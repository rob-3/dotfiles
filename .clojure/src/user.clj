(ns user
  (:require [sc.api]
            [clojure.string]
            [clojure.set]
            [clojure.repl]
            [clojure.pprint]
            [clojure.edn]))

(defn- inject [v]
  (let [fn-name (-> v symbol name symbol)]
    (if (-> v meta :macro)
      (do
        (intern 'user (with-meta fn-name (meta v)) @v)
        (intern 'clojure.core (with-meta fn-name (meta v)) @v))
      (do
        (intern 'user fn-name v)
        (intern 'clojure.core fn-name v)))))

(defn trace [x]
  (clojure.pprint/pprint x)
  x)
(intern 'clojure.core 'trace trace)

(let [nrepl? (try (requiring-resolve 'nrepl.version/version) (catch Exception _))]
  (when nrepl?
    (inject #'clojure.pprint/pprint)
    (inject #'clojure.repl/source)
    (inject #'clojure.repl/doc)))

(run! inject (-> 'sc.api ns-publics vals))

(defmacro defsc
  ([] (let [id (sc.api/last-ep-id)]
        `(sc.api/defsc ~id)))
  ([ep-id] `(sc.api/defsc ~ep-id)))
(inject #'defsc)

(defmacro undefsc
  ([] (let [id (sc.api/last-ep-id)]
        `(sc.api/undefsc ~id)))
  ([ep-id] `(sc.api/undefsc ~ep-id)))
(inject #'undefsc)
