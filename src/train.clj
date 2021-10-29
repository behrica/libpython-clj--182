(ns train
  (:require
   [camel-snake-kebab.core :as csk]
   [scicloj.ml.core :as ml]
   [scicloj.ml.dataset :as ds]
   [scicloj.ml.metamorph :as mm]
   [scicloj.ml.top2vec :as top2vec]
   [tablecloth.api :as tc]
   [clojure.java.io :as io]))

(def outputs-dir "outputs")


(defn copy-file [source-path dest-path]
  (io/copy (io/file source-path) (io/file dest-path)))


(def raw-data
  (->
   (tc/dataset "https://github.com/scicloj/scicloj.ml.smile/blob/main/test/data/reviews.csv.gz?raw=true"
               {:key-fn csk/->kebab-case-keyword
                :file-type :csv
                :gzipped? true})
   (tc/rename-columns {:text :abstract})))

(defn make-pipe [options]
  (def options options)
  (ml/pipeline
   ;; (mm/head 1000)
   (mm/select-columns :abstract)
   (mm/drop-missing)
   {:metamorph/id :model}
   (mm/model (merge options
                    {:min_count 1
                     :documents-column :abstract
                     :verbose 1
                     :model-type :top2vec}))))


(def search-grid
  (ml/sobol-gridsearch {:speed (ml/categorical [:learn])

                        :embedding_model (ml/categorical ["doc2vec"])}))


(def pipes
  (mapv make-pipe search-grid))

;; (ml/fit-pipe raw-data pipe)



(defn eval-handler [ctx]
  (def ctx ctx)

  (let [
        documents (-> ctx :fit-ctx :metamorph/data :abstract seq)

        options (-> ctx :fit-ctx :model :options)

        topic-model-py
        (scicloj.metamorph.ml/thaw-model (-> ctx :fit-ctx :model))

        pwi (-> ctx :fit-ctx :model :model-data :pwi)

        out-dir (str outputs-dir "/" (java.util.UUID/randomUUID))]

    (.mkdir (clojure.java.io/file out-dir))

    (copy-file "Dockerfile" (str out-dir "/Dockerfile"))
    (->> {:documents documents
          :options options}
         (print-str)
         (spit (str  out-dir "/in.edn")))


    (top2vec/save topic-model-py (str out-dir "/model.bin"))

    (->> {:pwi pwi}
         (print-str)
         (spit (str  out-dir "/metrics.edn"))))
  nil)



(def evaluation-results
  (ml/evaluate-pipelines pipes
                         [{:train raw-data :test (ds/dataset)}]
                         (fn [ctx]
                           (let [top-2-vec-model (ml/thaw-model (:model ctx))]
                             (println top-2-vec-model)
                             (top2vec/pwi top-2-vec-model nil)))
                         :loss
                         {:return-best-crossvalidation-only false
                          :return-best-pipeline-only false
                          :evaluation-handler-fn eval-handler}))

(clojure.pprint/pprint
 (map
  #(hash-map :opts %1 :metric %2)
  (->> evaluation-results
       flatten
       (map #(get-in % [:fit-ctx :model :options]))
       (map #(select-keys % [:speed :verbose])))
  (->> evaluation-results flatten (map #(get-in % [:train-transform :metric])))))
