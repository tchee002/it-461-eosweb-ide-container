FROM ubuntu:20.04

ENV TZ=America/New_York DEBIAN_FRONTEND=noninteractive
RUN apt-get update  \
    && apt-get install -y asciidoctor      bash-completion      build-essential      clang-tools-8      curl      g++-8      git      htop      jq      less  \
       libcurl4-gnutls-dev      libgmp3-dev      libssl-dev      libusb-1.0-0-dev locales      man-db multitail \
        nano      nginx      ninja-build      pkg-config      python      software-properties-common  sudo      supervisor      vim      wget      xz-utils      zlib1g-dev 
#    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* 

ENV LANG=en_US.UTF-8
WORKDIR /root
USER root

RUN wget https://github.com/eosio/eos/releases/download/v2.1.0/eosio_2.1.0-1-ubuntu-20.04_amd64.deb
#COPY eosio_2.1.0-1-ubuntu-20.04_amd64.deb .
RUN apt install -y ./eosio_2.1.0-1-ubuntu-20.04_amd64.deb
RUN wget https://github.com/eosio/eosio.cdt/releases/download/v1.7.0/eosio.cdt_1.7.0-1-ubuntu-18.04_amd64.deb
#COPY eosio.cdt_1.7.0-1-ubuntu-18.04_amd64.deb .
RUN apt install -y ./eosio.cdt_1.7.0-1-ubuntu-18.04_amd64.deb

#RUN locale-gen en_US.UTF-8  && curl -sL https://deb.nodesource.com/setup_10.x | bash -  && apt-get install -yq      nodejs  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*  && npm i -g yarn typescript
#RUN locale-gen en_US.UTF-8  && curl -sL https://deb.nodesource.com/setup_10.x | bash -  && apt-get update && apt-get install -yq nodejs && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*  && npm i -g yarn typescript
COPY setup_10.x .
RUN locale-gen en_US.UTF-8 && cat setup_10.x | bash - && apt-get update &&  apt-get install -y nodejs && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* && npm i -g yarn typescript

RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod     \
    && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

# custom Bash prompt
RUN { echo && echo "PS1='\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\]\$(__git_ps1 \" (%s)\") $ '" ; } >> .bashrc

# set up permissions
#RUN chown -R gitpod /var/log/nginx && chown gitpod /var/lib/nginx && touch /run/nginx.pid && chown gitpod /run/nginx.pid

### Gitpod user (2) ###
USER gitpod
# use sudo so that user does not get sudo usage info on (the first) login
RUN sudo echo "Running 'sudo' for Gitpod: success" && \
    # create .bashrc.d folder and source it in the bashrc
    mkdir -p /home/gitpod/.bashrc.d && \
    (echo; echo "for i in \$(ls -A \$HOME/.bashrc.d/); do source \$HOME/.bashrc.d/\$i; done"; echo) >> /home/gitpod/.bashrc && \
    # create a completions dir for gitpod user
    mkdir -p /home/gitpod/.local/share/bash-completion/completions

USER root
WORKDIR /root
RUN echo >/password \
    && chown gitpod /password \
    && chgrp gitpod /password  \
    && >/run/nginx.pid  \
    && chmod 666 /run/nginx.pid  \
    && chmod 666 /var/log/nginx/*  \
    && chmod 777 /var/lib/nginx /var/log/nginx
#RUN cd /workspace && ln -s eosweb-it-461 eosio-web-ide
WORKDIR /home/gitpod
USER gitpod
RUN { echo \
    && echo "PS1='\[\e]0;\u \w\a\]\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \\\$ '" ; } >> .bashrc
RUN sudo echo "Running 'sudo' for Gitpod: success"
RUN cleos wallet create --to-console | tail -n 1 | sed 's/"//g' >/password     \
    && cleos wallet import --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3
RUN echo '\n   unlock-timeout = 31536000 \n' >$HOME/eosio-wallet/config.ini
WORKDIR /home/gitpod
USER gitpod
RUN  notOwnedFile=$(find . -not "(" -user gitpod -and -group gitpod ")" -print -quit)     \
     && { [ -z "$notOwnedFile" ]         || { echo "Error: not all files/dirs in $HOME are owned by 'gitpod' user & group"; exit 1; } }

ENV HOME=/home/gitpod
