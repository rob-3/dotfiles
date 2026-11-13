#!/usr/bin/env bb
;; Supervisor for `jail --net-public`.
;;
;; Runs inside the fresh, private network namespace, exposes the host-side
;; jail-proxy unix socket as 127.0.0.1:<port>, then runs the given command.
;; When the command exits, this process exits too and the listeners die.
;;
;; Usage: jail-bridge.bb --socket SOCK --port 8787 [--port 1080] \
;;                       --ready FILE -- COMMAND [ARGS...]

(require '[babashka.cli :as cli]
         '[babashka.fs :as fs]
         '[babashka.process :as p]
         '[clojure.string :as str])

(import '[java.io InputStream OutputStream]
        '[java.net InetAddress InetSocketAddress ServerSocket Socket
          StandardProtocolFamily UnixDomainSocketAddress]
        '[java.nio.channels Channels SocketChannel])

(defn log [& xs]
  (binding [*out* (java.io.PrintWriter. System/err true)] (apply println xs)))

(defn close-quiet [^java.io.Closeable c]
  (try (.close c) (catch Exception _)))

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

(defn handle-client [^Socket client sock-path]
  (try
    (let [ch (SocketChannel/open StandardProtocolFamily/UNIX)]
      (.connect ch (UnixDomainSocketAddress/of sock-path))
      (pump (.getInputStream client) (.getOutputStream client)
            (Channels/newInputStream ch) (Channels/newOutputStream ch)))
    (catch Exception _)
    (finally (close-quiet client))))

(defn start-server [port handler]
  (let [ss (ServerSocket.)]
    (.bind ss (InetSocketAddress. (InetAddress/getByName "127.0.0.1") (int port)))
    (future
      (loop []
        (when-let [s (try (.accept ss) (catch Exception _ nil))]
          (future (handler s))
          (recur))))))

(defn split-command [args]
  (let [i (first (keep-indexed #(when (= "--" %2) %1) args))]
    (if i
      [(subvec (vec args) 0 i) (subvec (vec args) (inc i))]
      [(vec args) []])))

(defn parse-args [args]
  (let [[head cmd] (split-command args)
        opts (try
               (cli/parse-opts head {:coerce {:port :long}
                                     :collect {:port (fnil conj [])}
                                     :exec-args {:port []}
                                     :spec {:socket {} :port {} :ready {}}
                                     :restrict true})
               (catch Exception e
                 (log "jail-bridge:" (.getMessage e))
                 (System/exit 1)))]
    (if (and (:socket opts) (:ready opts) (seq (:port opts)) (seq cmd))
      (assoc opts :cmd cmd)
      (do (log "usage: jail-bridge.bb --socket SOCK --port 8787 [--port 1080]"
               "--ready FILE -- COMMAND [ARGS...]")
          (System/exit 1)))))

(defn euid []
  (parse-long (str/trim (:out (p/sh {:out :string} "id" "-u")))))

(defn -main [args]
  (let [{:keys [socket port ready cmd]} (parse-args args)]
    (fs/delete-if-exists ready)

    ;; Only the wrapper user namespace has CAP_NET_ADMIN; as a plain user this
    ;; is a no-op (the caller already has a usable loopback).
    (when (zero? (euid))
      (let [r (p/sh {:out :string :err :string} "ip" "link" "set" "lo" "up")]
        (when-not (zero? (:exit r))
          (log "jail-bridge: cannot bring up loopback:" (str/trim (:err r)))
          (System/exit 1))))

    (doseq [p port]
      (start-server p #(handle-client % socket)))
    (spit ready "")

    (let [proc (try
                 (apply p/process {:inherit true} cmd)
                 (catch Exception e
                   (log "jail-bridge:" (first cmd) ":" (.getMessage e))
                   (System/exit 1)))]
      (System/exit (:exit @proc)))))

(-main *command-line-args*)
