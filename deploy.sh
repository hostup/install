#!/bin/bash
echo "This assumes that you are doing a green-field install.  If you're not, please exit in the next 15 seconds."
sleep 15
apt update && \
    apt install -y build-essential \
    libicu-dev \
    curl \
    g++ \
    git
    
cd /root
curl https://github.com/Kitware/CMake/releases/download/v3.15.5/cmake-3.15.5-Linux-x86_64.sh -OL &&\
    echo '62e3e7d134a257e13521e306a9d3d1181ab99af8fcae66699c8f98754fc02dda cmake-3.15.5-Linux-x86_64.sh' | sha256sum -c - &&\
    mkdir /opt/cmake &&\
    sh cmake-3.15.5-Linux-x86_64.sh --prefix=/opt/cmake --skip-license &&\
    ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake &&\
    cmake --version &&\
    rm cmake-3.15.5-Linux-x86_64.sh
curl https://boostorg.jfrog.io/artifactory/main/release/1.68.0/source/boost_1_68_0.tar.bz2 -OL &&\
    echo '7f6130bc3cf65f56a618888ce9d5ea704fa10b462be126ad053e80e553d6d8b7 boost_1_68_0.tar.bz2' | sha256sum -c - &&\
    tar -xjf boost_1_68_0.tar.bz2 &&\
    rm boost_1_68_0.tar.bz2 &&\
    cd boost_1_68_0 &&\
    ./bootstrap.sh --with-libraries=system,filesystem,thread,date_time,chrono,regex,serialization,atomic,program_options,locale,timer &&\
    ./b2 &&\
    cd ..
BOOST_ROOT=/root/boost_1_68_0
pwd && mem_avail_gb=$(( $(getconf _AVPHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024 * 1024) )) &&\
    make_job_slots=$(( $mem_avail_gb < 4 ? 1 : $mem_avail_gb / 4)) &&\
    echo make_job_slots=$make_job_slots &&\
    set -x &&\
    git clone --single-branch https://github.com/zano-mining/zano.git -b pool_additions &&\
    cd zano &&\
    git submodule update --init --recursive &&\
    mkdir build && cd build &&\
    cmake -D STATIC=TRUE .. &&\
    make -j $make_job_slots daemon simplewallet
    
useradd -ms /bin/bash zano &&\
    mkdir -p /home/zano/.Zano &&\
    chown -R zano:zano /home/zano/.Zano
    
cd /home/zano
cp /root/zano/build/src/zanod .  &&\
cp /root/zano/build/src/simplewallet .  &&\
chown zano zanod  &&\
chown zano simplewallet

echo "now building api."
sleep 15

 apt-get update && apt-get install -y --no-install-recommends \
      apt-utils \
      build-essential \
      curl \
      wget \
      git \
      ca-certificates \
      golang \
      pkg-config \
      unzip \
      && rm -rf /var/lib/apt/lists/*
mkdir -p /var/local/git
git clone https://github.com/zano-mining/open-zano-pool /var/local/git/open-zano-pool && \
    cd /var/local/git/open-zano-pool && make && \
    mkdir -p /artifacts && \
    cp /var/local/git/open-zano-pool/config.example.json /artifacts/config.json && \
    cp /var/local/git/open-zano-pool/build/bin/open-zano-pool /artifacts
    apt-get update && apt-get install -y --no-install-recommends ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists
    groupadd -r -g 1001 pool && \
    useradd -r -u 1001 pool -g 1001 && \
    mkdir -p /opt/pool && \
    chown pool:pool -R /opt/pool
    cp -r /artifacts /opt/pool
    apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-utils \
      curl \
      wget \
      git \
      ca-certificates \
      nodejs \
      npm \
      watchman \
      pkg-config \
      unzip && \
    rm -rf /var/lib/apt/lists/*
    mkdir -p /var/local/git
    git clone https://github.com/zano-mining/open-zano-pool /var/local/git/open-zano-pool && \
    mkdir -p /artifacts && \
    cp -r /var/local/git/open-zano-pool/www /artifacts/
    cd /artifacts/www && \
    npm install -g ember-cli@3.1.3; exit 0
    cd /artifacts/www && \
    npm install -g bower && \
    npm install && \
    bower install --allow-root
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates \
    nodejs watchman && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists
    groupadd -r -g 1001 webserver && \
    useradd -r -u 1001 webserver -g 1001 && \
    mkdir -p /opt/frontend && \
    chown webserver:webserver -R /opt/frontend
    XDG_CONFIG_HOME=/opt/frontend/.config
    cp -r /artifacts /opt/frontend/
