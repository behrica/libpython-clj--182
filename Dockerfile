FROM rocker/r-ver:4.1.1

RUN apt-get update && apt-get -y install expect openjdk-11-jdk curl rlwrap libssl-dev build-essential zlib1g-dev  libncurses5-dev libgdbm-dev libnss3-dev  libreadline-dev libffi-dev  libbz2-dev libbluetooth-dev libbz2-dev libdb-dev libexpat1-dev libffi-dev libgdbm-dev liblzma-dev libmpdec-dev libncursesw5-dev libreadline-dev libsqlite3-dev libssl-dev zlib1g-dev  git libbz2-dev

RUN curl -O https://www.python.org/ftp/python/3.9.7/Python-3.9.7.tar.xz
RUN tar xf Python-3.9.7.tar.xz
RUN cd Python-3.9.7 && ./configure --enable-shared --with-ensurepip=install && make && make install && ldconfig
RUN curl -O https://download.clojure.org/install/linux-install-1.10.3.981.sh && chmod +x linux-install-1.10.3.981.sh && ./linux-install-1.10.3.981.sh

RUN /usr/local/bin/python3.9 -m pip install --upgrade pip
# leav this at th end
ARG USER_ID
ARG GROUP_ID

RUN addgroup --gid $GROUP_ID user
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user

USER user
RUN unbuffer pip3 install numpy==1.20.3
COPY requirements.txt .
RUN unbuffer pip3 install -r requirements.txt
RUN export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 && unbuffer pip3 install python-javabridge

USER root
RUN mkdir -p /app/outputs && chmod o+w -R /app
RUN mkdir /data && chmod o+w /data

USER user
WORKDIR /home/user

RUN unbuffer git clone https://github.com/openefsa/Top2Vec.git -b progressLog && \
    cd Top2Vec &&  git checkout f4ddb560cb8f9c480388e459ab289eb4fadd6636 && \
    unbuffer python3 setup.py develop --no-deps --user
RUN pip3 install numpy==1.20
RUN curl https://raw.githubusercontent.com/behrica/libpython-clj/2b5c495561d816acd696f50dc8ae08bd37842530/cljbridge.py -o /home/user/.local/lib/python3.9/site-packages/cljbridge.py
RUN curl https://gist.githubusercontent.com/behrica/91b3f958fad80247069ade3b96646dcf/raw/7d27ec07bfe7b6cef1598c530bff50882f84ba70/PWI_top2vec.py -o /home/user/.local/lib/python3.9/site-packages/PWI_top2vec.py

ENV TFHUB_DOWNLOAD_PROGRESS=1

CMD ["/bin/bash", "-c", "sleep 0.1;clj"]
