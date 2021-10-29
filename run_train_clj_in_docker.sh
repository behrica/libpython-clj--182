#!/usr/bin/env bash
set -euo pipefail

docker run -it --rm -v $HOME/.m2:/home/user/.m2 -v "$(pwd):/app" -w /app tm-prev unbuffer python3  -c "import cljbridge;cljbridge.load_clojure_file(clj_file='src/train.clj')"
