#!/usr/bin/env bash
set -euo pipefail

docker run -it -v $HOME/.m2:/home/user/.m2 -v "$(pwd):/app" -p  12345:12345 -w /app crash-libpython unbuffer python3 -c "import cljbridge;cljbridge.init_clojure_repl(port=12345,bind='0.0.0.0')"
