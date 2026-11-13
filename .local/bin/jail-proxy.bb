#!/usr/bin/env bb
;; Network policy proxy for `jail --net-public` (babashka port of jail-proxy).
;;
;; One listener speaks both HTTP (CONNECT / absolute-URI) and SOCKS5; the
;; protocol is sniffed from the first byte, so HTTP clients and
;; `ALL_PROXY=socks5h://...` clients can share a single bridged socket.
;;
;;   --allow 127.0.0.1        address (any port)
;;   --allow 127.0.0.1:5432   address and port
;;   --allow 192.168.1.0/24   CIDR
;;   --allow nas.lan          hostname (also matches *.nas.lan)
;;   --allow nas.lan:445      hostname and port
;;
;; Public destinations pass unless --allow-only; everything else fails
;; closed. Names are resolved here, on the host.
;;
;; Usage: jail-proxy.bb --listen unix:/path/to/socket [--allow ENTRY]...

(require '[babashka.cli :as cli]
         '[babashka.fs :as fs]
         '[babashka.process :as p]
         '[cheshire.core :as json]
         '[clojure.string :as str])

(import '[java.io ByteArrayInputStream ByteArrayOutputStream FileInputStream InputStream OutputStream]
        '[java.net InetAddress InetSocketAddress ServerSocket Socket
          StandardProtocolFamily UnixDomainSocketAddress]
        '[java.nio.channels Channels ServerSocketChannel]
        '[java.nio.charset StandardCharsets]
        '[java.security KeyStore]
        '[java.security.cert CertificateFactory]
        '[javax.net.ssl SSLContext KeyManagerFactory TrustManagerFactory])

(def ^:private ISO StandardCharsets/ISO_8859_1)
(def ^:private ^bytes CRLF (.getBytes "\r\n" ISO))
(def ^:private ^bytes CRLFCRLF (.getBytes "\r\n\r\n" ISO))
(def ^:private CR (int 13))
(def ^:private LF (int 10))

(defn log [& xs]
  (binding [*out* (java.io.PrintWriter. System/err true)]
    (apply println xs)))

(defn close-quiet [^java.io.Closeable c]
  (try (.close c) (catch Exception _)))

;; ------------------------------------------------------------- arguments --

(defn parse-args [args]
  (cli/parse-opts args
    {:coerce {:mitm-port :long}
     :collect {:listen (fnil conj []) :allow (fnil conj [])}
     :exec-args {:listen [] :allow [] :allow-only false :mitm-port 443
                 :inject-auth-provider "openrouter"}
     :spec {:listen {} :allow {} :allow-only {} :mitm-ca {} :mitm-port {}
            :upstream-ca {} :openssl {} :inject-auth-from {}
            :inject-auth-env {} :inject-auth-provider {}}
     :restrict true}))

;; ------------------------------------------------------------------- IPs --

(def ^:private ipv4-re #"^\d{1,3}(\.\d{1,3}){3}$")
(def ^:private ipv6-re #"^[0-9A-Fa-f:.]+(%[A-Za-z0-9_.]+)?$")

(defn ip-literal? [s]
  (boolean (or (re-matches ipv4-re s)
               (and (str/includes? s ":") (re-matches ipv6-re s)))))

(defn inet [^String s]
  (when (ip-literal? s)
    (try (InetAddress/getByName s) (catch Exception _ nil))))

(defn in-prefix? [^bytes addr ^bytes net ^long prefix]
  (and (= (alength addr) (alength net))
       (let [full (quot prefix 8) rem (mod prefix 8)]
         (and (loop [i 0]
                (if (>= i full) true
                    (if (= (aget addr i) (aget net i)) (recur (inc i)) false)))
              (or (zero? rem)
                  (let [mask (bit-and 0xff (bit-shift-left 0xff (- 8 rem)))]
                    (= (bit-and mask (aget addr full))
                       (bit-and mask (aget net full)))))))))

(def ^:private reserved
  (mapv (fn [[ip p]] [(inet ip) p])
        [["0.0.0.0" 8] ["100.64.0.0" 10] ["192.0.0.0" 24] ["192.0.2.0" 24]
         ["198.18.0.0" 15] ["198.51.100.0" 24] ["203.0.113.0" 24]
         ["240.0.0.0" 4]
         ["::" 128] ["64:ff9b::" 96] ["100::" 64] ["2001:db8::" 32]
         ["2001:10::" 28]]))

(defn public? [^InetAddress a]
  (and (not (.isAnyLocalAddress a))
       (not (.isLoopbackAddress a))
       (not (.isLinkLocalAddress a))
       (not (.isSiteLocalAddress a))
       (not (.isMulticastAddress a))
       (not (some (fn [[^InetAddress net p]]
                    (in-prefix? (.getAddress a) (.getAddress net) p))
                  reserved))))

(defn resolve-addrs [^String host]
  (try
    (reduce (fn [acc ^InetAddress a]
              (if (some #(= (.getHostAddress ^InetAddress %) (.getHostAddress a)) acc)
                acc (conj acc a)))
            [] (InetAddress/getAllByName host))
    (catch Exception _ [])))

;; ---------------------------------------------------------------- policy --

(defn split-host-port [entry]
  (let [e (-> entry str/lower-case (str/replace #"\.$" ""))]
    (cond
      (str/starts-with? e "[")
      (let [end (str/index-of e "]")]
        (when-not end (throw (ex-info (str "bad allow entry: " entry) {})))
        [(subs e 1 end)
         (when (str/starts-with? (subs e (inc end)) ":")
           (parse-long (subs e (+ end 2))))])

      (and (= 1 (get (frequencies e) \: 0)) (re-matches #"[^:]+:\d+" e))
      (let [[h p] (str/split e #":" 2)] [h (parse-long p)])

      :else [e nil])))

(defn parse-cidr [s]
  (let [[h p] (str/split s #"/" 2)
        a (inet h)]
    (when a
      [a (if p (parse-long p) (if (= 4 (alength (.getAddress ^InetAddress a))) 32 128))])))

(defn make-policy [entries allow-only]
  (let [pairs (map split-host-port entries)]
    {:allow-only allow-only
     :nets (into [] (keep (fn [[h p]] (when-let [c (parse-cidr h)] [c p])) pairs))
     :names (into [] (keep (fn [[h p]] (when-not (parse-cidr h) [h p])) pairs))}))

(defn match-addr [policy ^InetAddress addr port]
  (boolean
   (some (fn [[[^InetAddress net prefix] p]]
           (and (or (nil? p) (= p port))
                (in-prefix? (.getAddress addr) (.getAddress net) prefix)))
         (:nets policy))))

(defn match-name [policy name port]
  (let [name (-> name str/lower-case (str/replace #"\.$" ""))]
    (boolean
     (some (fn [[host p]]
             (and (or (nil? p) (= p port))
                  (or (= name host) (str/ends-with? name (str "." host)))))
           (:names policy)))))

(defn check [policy host port addrs]
  (cond
    (match-name policy host port) [true addrs]
    (empty? addrs) [false []]
    (:allow-only policy)
    (let [allowed (filterv #(match-addr policy % port) addrs)]
      (if (seq allowed) [true allowed] [false []]))
    :else
    (if (every? #(or (public? %) (match-addr policy % port)) addrs)
      [true (into (filterv public? addrs) (filterv #(not (public? %)) addrs))]
      [false []])))

(defn describe-policy [policy]
  (str "mode=" (if (:allow-only policy) "allow-only" "public+allow")
       " nets=" (str/join "," (map (fn [[[^InetAddress a p] port]]
                                     (str (.getHostAddress a) "/" p
                                          (if port (str ":" port) "")))
                                   (:nets policy)))
       " names=" (str/join "," (map (fn [[h p]] (str h (if p (str ":" p) "")))
                                    (:names policy)))))

;; ------------------------------------------------------------------- I/O --

(defn read-bytes [^InputStream in ^long n]
  (let [buf (byte-array n)]
    (loop [off 0]
      (if (= off n)
        buf
        (let [r (.read in buf off (- n off))]
          (if (neg? r) nil (recur (+ off r))))))))

(defn- ends-with-delim? [^longs ring ^long n ^bytes delim]
  (let [dl (alength delim)]
    (and (>= n dl)
         (loop [k 0]
           (cond
             (= k dl) true
             (= (aget ring (mod (- n 1 k) dl))
                (long (bit-and 0xff (aget delim (- dl 1 k))))) (recur (inc k))
             :else false)))))

(defn read-until [^InputStream in ^bytes delim]
  (let [dl (alength delim)
        out (ByteArrayOutputStream. 256)
        ring (long-array dl)]
    (loop [n 0]
      (let [b (.read in)]
        (if (neg? b)
          (when (pos? (.size out)) (.toByteArray out))
          (do (.write out b)
              (aset ring (mod n dl) (long b))
              (if (ends-with-delim? ring (inc n) delim)
                (.toByteArray out)
                (recur (inc n)))))))))

(defn copy-exact [^InputStream in ^OutputStream out ^long n]
  (loop [left n]
    (if (zero? left)
      true
      (let [b (.readNBytes in (int (min left 65536)))]
        (if (empty? b)
          false
          (do (.write out ^bytes b)
              (.flush out)
              (recur (- left (alength ^bytes b)))))))))

(defn transfer-chunked [^InputStream in ^OutputStream out]
  (try
    (loop []
      (let [line (read-until in CRLF)]
        (if-not line
          false
          (do
            (.write out line)
            (let [sz (try (Long/parseLong
                           (str/trim (first (str/split (String. ^bytes line ISO) #";")))
                           16)
                          (catch Exception _ -1))]
              (cond
                (neg? sz) false
                (zero? sz) (loop []
                             (let [t (read-until in CRLF)]
                               (if-not t
                                 false
                                 (do (.write out t) (.flush out)
                                     (if (and (= 2 (alength ^bytes t))
                                              (= CR (aget ^bytes t 0)) (= LF (aget ^bytes t 1)))
                                       true
                                       (recur))))))
                (and (copy-exact in out sz) (copy-exact in out 2)) (recur)
                :else false))))))
    (catch Exception _ false)))

(defn splice [^InputStream in ^OutputStream out]
  (try
    (.transferTo in out)
    (.flush out)
    (catch Exception _)
    (finally (close-quiet out))))

(defn pump [^InputStream a-in ^OutputStream a-out ^InputStream b-in ^OutputStream b-out]
  (let [f (future (splice a-in b-out))
        g (future (splice b-in a-out))]
    @f @g))

(defn open-target [targets port timeout]
  (loop [ts (seq targets)]
    (when-let [a (first ts)]
      (let [s (try (let [s (Socket.)]
                     (.connect s (InetSocketAddress. ^InetAddress a (int port)) (int timeout))
                     s)
                   (catch Exception _ nil))]
        (if s [a s] (recur (next ts)))))))

(defn concat-bytes [^bytes a ^bytes b]
  (let [out (byte-array (+ (alength a) (alength b)))]
    (System/arraycopy a 0 out 0 (alength a))
    (System/arraycopy b 0 out (alength a) (alength b))
    out))

(defn after-first-crlf [^bytes b]
  (let [n (alength b)]
    (loop [i 0]
      (if (>= (inc i) n)
        nil
        (if (and (= CR (aget b i)) (= LF (aget b (inc i))))
          (java.util.Arrays/copyOfRange b (+ i 2) n)
          (recur (inc i)))))))

;; ----------------------------------------------------------------- SOCKS --

(defn socks-reply [code]
  (byte-array [5 (bit-and 0xff code) 0 1 0 0 0 0 0 0]))

(defn socks-read-host [^InputStream in atyp]
  (case atyp
    1 (some-> (read-bytes in 4) InetAddress/getByAddress)
    4 (some-> (read-bytes in 16) InetAddress/getByAddress)
    3 (when-let [lb (read-bytes in 1)]
        (when-let [b (read-bytes in (bit-and 0xff (aget ^bytes lb 0)))]
          (String. ^bytes b ISO)))
    nil))

(defn socks-connect [^InputStream in ^OutputStream out policy host port]
  (let [host-name (if (string? host) host (.getHostAddress ^InetAddress host))
        addrs (if (string? host) (resolve-addrs host) [host])
        [allowed targets] (check policy host-name port addrs)]
    (if-not allowed
      (do (log "deny socks" (str host-name ":" port)
               (mapv #(.getHostAddress ^InetAddress %) addrs))
          (.write out (socks-reply 0x02)) (.flush out))
      (if-let [[target up] (open-target targets port 15000)]
        (try
          (log "allow socks" (str host-name ":" port) "->" (.getHostAddress ^InetAddress target))
          (.write out (byte-array [5 0 0 1 0 0 0 0 0 0])) (.flush out)
          (pump in out (.getInputStream up) (.getOutputStream up))
          (finally (close-quiet up)))
        (do (log "connect-fail socks" (str host-name ":" port))
            (.write out (socks-reply 0x05)) (.flush out))))))

(defn handle-socks [^bytes first-byte ^InputStream in ^OutputStream out policy]
  (try
    (let [ver first-byte]
      (when (and ver (= 5 (bit-and 0xff (aget ^bytes ver 0))))
        (let [nb (read-bytes in 1)
              methods (when nb (read-bytes in (bit-and 0xff (aget ^bytes nb 0))))]
          (if-not (and methods (some #(zero? (bit-and 0xff %)) methods))
            (do (.write out (byte-array [5 0xff])) (.flush out))
            (do
              (.write out (byte-array [5 0])) (.flush out)
              (let [hdr (read-bytes in 4)]
                (when (and hdr (= 5 (bit-and 0xff (aget ^bytes hdr 0))))
                  (let [cmd (bit-and 0xff (aget ^bytes hdr 1))
                        atyp (bit-and 0xff (aget ^bytes hdr 3))]
                    (if (not= cmd 1)
                      (do (.write out (socks-reply 0x07)) (.flush out))
                      (let [host (socks-read-host in atyp)
                            pb (read-bytes in 2)
                            port (when pb
                                   (bit-or (bit-shift-left (bit-and 0xff (aget ^bytes pb 0)) 8)
                                           (bit-and 0xff (aget ^bytes pb 1))))]
                        (if (or (nil? host) (nil? port) (zero? port))
                          (do (.write out (socks-reply 0x08)) (.flush out))
                          (socks-connect in out policy host port))))))))))))
    (catch Exception e
      (log "socks-error" (.getMessage e)))))

;; ------------------------------------------------------------- HTTP proxy --

(defn http-fail [^OutputStream out code]
  (let [reason (case (int code) 400 "Bad Request" 403 "Forbidden" 502 "Bad Gateway")
        msg (str "HTTP/1.1 " code " " reason "\r\nContent-Length: 0\r\n\r\n")]
    (try (.write out (.getBytes msg ISO)) (.flush out) (catch Exception _))))

(defn header-value [lines name]
  (some (fn [^String line]
          (let [i (.indexOf line ":")]
            (when (pos? i)
              (when (= (str/lower-case (str/trim (subs line 0 i))) name)
                (str/trim (subs line (inc i)))))))
        lines))

(defn relay-requests [^InputStream in ^OutputStream out key]
  (let [auth (when key (str "Authorization: Bearer " key))]
    (try
      (loop []
        (let [head (read-until in CRLFCRLF)]
          (if-not head
            (close-quiet out)
            (let [s (String. ^bytes head ISO)
                  body (subs s 0 (max 0 (- (count s) 4)))
                  lines (str/split body #"\r\n")]
              (if (empty? (first lines))
                (close-quiet out)
                (let [kept (into [(first lines)]
                                 (remove (fn [^String line]
                                           (let [i (.indexOf line ":")
                                                 n (when (pos? i)
                                                     (str/lower-case (str/trim (subs line 0 i))))]
                                             (or (= n "proxy-authorization")
                                                 (and auth (= n "authorization")))))
                                         (rest lines)))
                      kept (if auth (conj kept auth) kept)]
                  (.write out (.getBytes (str (str/join "\r\n" kept) "\r\n\r\n") ISO))
                  (.flush out)
                  (let [te (header-value lines "transfer-encoding")
                        cl (header-value lines "content-length")]
                    (cond
                      (and te (str/includes? (str/lower-case te) "chunked"))
                      (if (transfer-chunked in out) (recur) (close-quiet out))
                      cl
                      (if (copy-exact in out (parse-long cl)) (recur) (close-quiet out))
                      :else (recur)))))))))
      (catch Exception _ (close-quiet out)))))

;; ------------------------------------------------------------------- TLS --

(defn find-openssl []
  (or (some-> (fs/which "openssl") str)
      (->> (fs/list-dir "/nix/store")
           (filter #(str/includes? (str (fs/file-name %)) "openssl"))
           (map #(fs/path % "bin" "openssl"))
           (filter fs/executable?)
           (sort)
           (first)
           (str))))

(defn keystore-context [^String cert ^String key openssl]
  (let [p12 (fs/create-temp-file {:prefix "jail-proxy-" :suffix ".p12"})]
    (try
      (p/check (p/sh openssl "pkcs12" "-export" "-in" cert "-inkey" key
                     "-out" (str p12) "-passout" "pass:"))
      (let [ks (KeyStore/getInstance "PKCS12")]
        (with-open [i (FileInputStream. (fs/file p12))] (.load ks i (char-array 0)))
        (let [kmf (KeyManagerFactory/getInstance (KeyManagerFactory/getDefaultAlgorithm))]
          (.init kmf ks (char-array 0))
          (doto (SSLContext/getInstance "TLS")
            (.init (.getKeyManagers kmf) nil nil))))
      (finally (fs/delete-if-exists p12)))))

(defn pem-certificates [^String file]
  ;; CertificateFactory.generateCertificates chokes on NixOS' 118-cert bundle
  ;; ("extra data at the end"), so split the PEM blocks ourselves.
  (let [cf (CertificateFactory/getInstance "X.509")]
    (for [pem (re-seq #"(?s)-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----"
                      (slurp file))]
      (with-open [i (ByteArrayInputStream. (.getBytes ^String pem StandardCharsets/US_ASCII))]
        (.generateCertificate cf i)))))

(defn trust-context [^String ca-file]
  (let [ks (KeyStore/getInstance "PKCS12")]
    (.load ks nil (char-array 0))
    (doseq [[i cert] (map-indexed vector (pem-certificates ca-file))]
      (.setCertificateEntry ks (str "ca-" i) cert))
    (let [tmf (TrustManagerFactory/getInstance (TrustManagerFactory/getDefaultAlgorithm))]
      (.init tmf ks)
      (doto (SSLContext/getInstance "TLS")
        (.init nil (.getTrustManagers tmf) nil)))))

(defn upstream-context [ca]
  (if ca
    (trust-context ca)
    (if-let [f (or (some #(when (and % (fs/regular-file? %)) %)
                         [(System/getenv "SSL_CERT_FILE")
                          (System/getenv "NIX_SSL_CERT_FILE")
                          (System/getenv "CURL_CA_BUNDLE")])
                    (some #(when (fs/regular-file? %) %)
                          ["/etc/ssl/certs/ca-certificates.crt" "/etc/ssl/cert.pem"
                           "/etc/ssl/certs/ca-bundle.crt"]))]
      (trust-context f)
      (SSLContext/getDefault))))

(defn tls-client [^Socket raw ^SSLContext ctx ^String host port]
  (let [s (.createSocket (.getSocketFactory ctx) raw host (int port) true)]
    (.setUseClientMode s true)
    (let [p (.getSSLParameters s)]
      (.setApplicationProtocols p (into-array String ["http/1.1"]))
      (.setSSLParameters s p))
    (.startHandshake s)
    s))

(defn tls-server [^Socket raw ^SSLContext ctx]
  (let [s (.createSocket (.getSocketFactory ctx) raw "localhost" 443 true)]
    (.setUseClientMode s false)
    (let [p (.getSSLParameters s)]
      (.setApplicationProtocols p (into-array String ["http/1.1"]))
      (.setSSLParameters s p))
    (.startHandshake s)
    s))

(defn ensure-ca! [m]
  (let [{:keys [ca-cert ca-key openssl]} m]
    (when-not (and (fs/regular-file? ca-cert) (fs/regular-file? ca-key))
      (p/check (p/sh openssl "req" "-x509" "-newkey" "ec"
                     "-pkeyopt" "ec_paramgen_curve:prime256v1" "-nodes"
                     "-keyout" ca-key "-out" ca-cert "-days" "3650"
                     "-subj" "/CN=jail-proxy local CA"
                     "-addext" "basicConstraints=critical,CA:TRUE"
                     "-addext" "keyUsage=critical,keyCertSign,cRLSign"))
      (fs/set-posix-file-permissions ca-key "rw-------")
      (log "mitm: generated CA" ca-cert))))

(defn make-leaf! [m host]
  (let [{:keys [cert-dir ca-cert ca-key openssl]} m
        safe (str/replace host #"[^A-Za-z0-9._-]" "_")
        cert (str (fs/path cert-dir (str safe ".pem")))
        key (str (fs/path cert-dir (str safe ".key")))]
    (when-not (and (fs/regular-file? cert) (fs/regular-file? key))
      (locking (:lock m)
        (when-not (and (fs/regular-file? cert) (fs/regular-file? key))
          (let [csr (str (fs/path cert-dir (str safe ".csr")))
                ext (str (fs/path cert-dir (str safe ".ext")))
                san (if (ip-literal? host) (str "IP:" host) (str "DNS:" host))]
            (spit ext (str "subjectAltName=" san "\n"
                           "basicConstraints=CA:FALSE\n"
                           "extendedKeyUsage=serverAuth\n"))
            (try
              (p/check (p/sh openssl "req" "-new" "-newkey" "ec"
                             "-pkeyopt" "ec_paramgen_curve:prime256v1" "-nodes"
                             "-keyout" key "-out" csr "-subj" (str "/CN=" host)))
              (p/check (p/sh openssl "x509" "-req" "-in" csr "-CA" ca-cert
                             "-CAkey" ca-key "-CAcreateserial" "-out" cert
                             "-days" "30" "-sha256" "-extfile" ext))
              (finally
                (fs/delete-if-exists csr)
                (fs/delete-if-exists ext)))
            (fs/set-posix-file-permissions key "rw-------")))))
    [cert key]))

(defn server-context [m host]
  (locking (:lock m)
    (or (get @(:contexts m) host)
        (let [[cert key] (make-leaf! m host)
              ctx (keystore-context cert key (:openssl m))]
          (swap! (:contexts m) assoc host ctx)
          ctx))))

(defn make-mitm [ca-dir port upstream-ca openssl]
  (let [dir (str (fs/absolutize (fs/expand-home ca-dir)))
        m {:dir dir
           :cert-dir (str (fs/path dir "certs"))
           :ca-cert (str (fs/path dir "ca.pem"))
           :ca-key (str (fs/path dir "ca.key"))
           :port port
           :openssl (or openssl (find-openssl))
           :upstream-ctx (upstream-context upstream-ca)
           :contexts (atom {})
           :lock (Object.)}]
    (when-not (:openssl m)
      (log "jail-proxy: --mitm-ca needs the openssl CLI (install it or pass --openssl PATH)")
      (System/exit 1))
    (fs/create-dirs (:cert-dir m))
    (ensure-ca! m)
    m))

(defn make-injector [path env provider]
  (let [warned (atom false)
        path (when path (str (fs/expand-home path)))]
    (fn []
      (or (when path
            (try
              (let [k (get-in (json/parse-string (slurp path)) [provider "key"])]
                (cond
                  (not (string? k)) nil
                  (str/starts-with? k "!")
                  (let [r (p/sh (subs k 1) {:out :string})]
                    (when (zero? (:exit r)) (str/trim (:out r))))
                  :else (not-empty k)))
              (catch Exception e
                (when-not @warned
                  (log "inject: cannot read" path (.getMessage e))
                  (reset! warned true))
                nil)))
          (when env (System/getenv env))))))

(defn handle-mitm [^Socket client ^InputStream in ^OutputStream out host port targets
                   mitm injector]
  (let [up (some (fn [^InetAddress a]
                   (try (let [raw (Socket.)]
                          (.connect raw (InetSocketAddress. a (int port)) 20000)
                          (tls-client raw (:upstream-ctx mitm) host port))
                        (catch Exception _ nil)))
                 targets)]
    (if-not up
      (do (log "mitm-upstream-fail" (str host ":" port)) (http-fail out 502))
      (try
        (let [ctx (server-context mitm host)]
          (.write out (.getBytes "HTTP/1.1 200 Connection Established\r\n\r\n" ISO))
          (.flush out)
          (let [client-tls (tls-server client ctx)
                cin (.getInputStream client-tls)
                cout (.getOutputStream client-tls)
                uin (.getInputStream up)
                uout (.getOutputStream up)
                key (when injector (injector))]
            (log "mitm" (str host ":" port) (str "inject=" (if key "yes" "no")))
            (let [f (future (splice uin cout))
                  g (future (relay-requests cin uout key))]
              @f @g)))
        (catch Exception e
          (log "mitm-error" (str host ":" port) (.getMessage e)))
        (finally (close-quiet up))))))

(defn addrs->str [addrs]
  (mapv #(.getHostAddress ^InetAddress %) addrs))

(defn relay!
  "Open the first reachable upstream, let `before` write to it, then pump
   bytes both ways. Fails the client with 502 when nothing connects."
  [^InputStream in ^OutputStream out targets port before ok-line fail-line]
  (if-let [[addr up] (open-target targets port 15000)]
    (try
      (log ok-line "->" (.getHostAddress ^InetAddress addr))
      (when before (before (.getOutputStream up)))
      (pump in out (.getInputStream up) (.getOutputStream up))
      (finally (close-quiet up)))
    (do (log fail-line) (http-fail out 502))))

(defn handle-connect [^Socket client ^InputStream in ^OutputStream out ^String host
                      port policy mitm injector]
  (let [addrs (resolve-addrs host)
        [allowed targets] (check policy host port addrs)
        line (str "allow CONNECT " host ":" port)]
    (cond
      (not allowed)
      (do (log "deny CONNECT" (str host ":" port) (addrs->str addrs))
          (http-fail out 403))

      (and mitm (= port (:port mitm)))
      (do (log line "(tls intercept)")
          (handle-mitm client in out host port targets mitm injector))

      :else
      (relay! in out targets port
              (fn [uout]
                (.write uout (.getBytes "HTTP/1.1 200 Connection Established\r\n\r\n" ISO))
                (.flush uout))
              line
              (str "connect-fail CONNECT " host ":" port)))))

(defn handle-absolute [^InputStream in ^OutputStream out ^bytes head
                       ^String method ^String target ^String version policy]
  (let [uri (try (java.net.URI. target) (catch Exception _ nil))]
    (if-not (and uri (.getHost uri))
      (http-fail out 400)
      (let [host (str/replace (.getHost uri) #"^\[|\]$" "")
            port (let [p (.getPort uri)] (if (neg? p) 80 p))
            path (str (or (.getRawPath uri) "/")
                      (when-let [q (.getRawQuery uri)] (str "?" q)))
            addrs (resolve-addrs host)
            [allowed targets] (check policy host port addrs)]
        (if-not allowed
          (do (log "deny" method (str host ":" port) (addrs->str addrs))
              (http-fail out 403))
          (relay! in out targets port
                  (fn [uout]
                    (.write uout (.getBytes (str method " " path " " version "\r\n") ISO))
                    (when-let [tail (after-first-crlf head)]
                      (.write uout ^bytes tail))
                    (.flush uout))
                  (str "allow " method " " host ":" port)
                  (str "connect-fail " method " " host ":" port)))))))

(defn handle-http [^Socket client ^InputStream in ^OutputStream out ^bytes first-byte
                   policy mitm injector]
  (let [rest-head (read-until in CRLFCRLF)]
    (if-not rest-head
      (close-quiet out)
      (let [head (concat-bytes first-byte rest-head)
            s (String. ^bytes head ISO)
            req-line (first (str/split s #"\r\n"))
            parts (str/split req-line #" ")]
        (if (not= 3 (count parts))
          (http-fail out 400)
          (let [[method target version] parts]
            (if (= "CONNECT" (str/upper-case method))
              (let [i (str/last-index-of target ":")
                    [h0 p0] (if i [(subs target 0 i) (subs target (inc i))] ["" target])
                    [host port] (if (str/blank? h0) [p0 "443"] [h0 p0])
                    host (if (and (str/starts-with? host "[") (str/ends-with? host "]"))
                           (subs host 1 (dec (count host))) host)
                    port (try (parse-long port) (catch Exception _ nil))]
                (if-not port
                  (http-fail out 400)
                  (handle-connect client in out host port policy mitm injector)))
              (handle-absolute in out head method target version policy))))))))

;; -------------------------------------------------------------- listeners --

(defn handle-conn [^Socket s policy mitm injector]
  (try
    (let [in (.getInputStream s) out (.getOutputStream s)]
      (when-let [b (read-bytes in 1)]
        (if (= 5 (bit-and 0xff (aget ^bytes b 0)))
          (handle-socks b in out policy)
          (handle-http s in out b policy mitm injector))))
    (catch Exception e
      (log "conn-error" (.getMessage e)))
    (finally (close-quiet s))))

(defn accept-loop [accept handler]
  (future
    (loop []
      (when-let [s (try (accept) (catch Exception _ nil))]
        (future (handler s))
        (recur)))))

(defn start-tcp [host port handler]
  (let [ss (ServerSocket. (int port) 50 (InetAddress/getByName host))]
    (log "listening" (str host ":" port))
    (accept-loop #(.accept ss) handler)))

(defn start-unix [path handler]
  (fs/create-dirs (fs/parent path))
  (fs/delete-if-exists path)
  (let [ch (ServerSocketChannel/open StandardProtocolFamily/UNIX)]
    (.bind ch (UnixDomainSocketAddress/of path))
    (fs/set-posix-file-permissions path "rw-------")
    (log "listening" (str "unix:" path))
    (let [internal (ServerSocket. 0 200 (InetAddress/getByName "127.0.0.1"))
          port (.getLocalPort internal)]
      (accept-loop #(.accept internal) handler)
      (accept-loop #(.accept ch)
                   (fn [c]
                     (try
                       (let [tcp (Socket. "127.0.0.1" (int port))]
                         (pump (Channels/newInputStream c) (Channels/newOutputStream c)
                               (.getInputStream tcp) (.getOutputStream tcp)))
                       (catch Exception _)
                       (finally (close-quiet c))))))))

(defn start-listener [spec handler]
  (if (str/starts-with? spec "unix:")
    (start-unix (subs spec 5) handler)
    (let [i (str/last-index-of spec ":")
          host (if (and i (pos? i)) (subs spec 0 i) "127.0.0.1")
          port (parse-long (subs spec (inc i)))]
      (start-tcp host port handler))))

(defn -main [& args]
  (let [opts (try
               (parse-args args)
               (catch Exception e
                 (log "jail-proxy:" (.getMessage e))
                 (System/exit 2)))
        policy (make-policy (:allow opts) (:allow-only opts))
        _ (log "policy" (describe-policy policy))
        mitm (when-let [ca (:mitm-ca opts)]
               (make-mitm ca (:mitm-port opts) (:upstream-ca opts) (:openssl opts)))
        injector (when (or (:inject-auth-from opts) (:inject-auth-env opts))
                   (when-not mitm
                     (log "jail-proxy: --inject-auth-* needs --mitm-ca")
                     (System/exit 1))
                   (make-injector (:inject-auth-from opts) (:inject-auth-env opts)
                                  (:inject-auth-provider opts)))]
    (when-not (seq (:listen opts))
      (log "jail-proxy: --listen is required")
      (System/exit 1))
    (when mitm
      (log "mitm" (str "ca=" (:ca-cert mitm) " port=" (:port mitm)
                       " openssl=" (:openssl mitm)
                       " inject=" (if injector "yes" "no"))))
    (doseq [spec (:listen opts)]
      (start-listener spec #(handle-conn % policy mitm injector)))
    @(promise)))

(when *command-line-args* (apply -main *command-line-args*))
