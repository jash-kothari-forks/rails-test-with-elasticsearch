FROM ubuntu:16.04

RUN cat /etc/apt/sources.list | sed -e 's|http://[^ ]*|mirror://mirrors.ubuntu.com/mirrors.txt|g' > /tmp/sources.list && mv /tmp/sources.list /etc/apt/sources.list
RUN apt-get update && \
    apt-get install -y software-properties-common git-core build-essential autoconf curl \
      zlib1g-dev libmysqlclient-dev imagemagick libmagickcore-dev libmagickwand-dev libssl-dev libreadline-dev \
      libyaml-dev libxml2-dev libxslt-dev tzdata

RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo 'Asia/Tokyo' > /etc/timezone && date

# elasticsearch
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" > /etc/apt/sources.list.d/webupd8team-java-trusty.list && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get update && apt-get install -y oracle-java8-installer

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D88E42B4 && \
    echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" > /etc/apt/sources.list.d/elasticsearch-2.x.list && \
    apt-get update && apt-get install -y elasticsearch=2.3.3

RUN /usr/share/elasticsearch/bin/plugin install lmenezes/elasticsearch-kopf &&\
    /usr/share/elasticsearch/bin/plugin install analysis-kuromoji && \
    /usr/share/elasticsearch/bin/plugin install analysis-icu

# nodejs
RUN apt-get install -y apt-transport-https
RUN apt-get update -qq
RUN curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
RUN echo "deb https://deb.nodesource.com/node_6.x xenial main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update -qq && apt-get install -y nodejs

# yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y yarn

# rootパスワードを"root"に設定してmysql-serverをインストール
RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections && \
    apt-get -y install mysql-server mysql-client && \
    echo "character-set-server = utf8mb4" >> /etc/mysql/mysql.conf.d/mysqld.cnf && \
    echo "default-character-set = utf8mb4" >> /etc/mysql/conf.d/mysql.cnf

# PhantomJS
ENV PHANTOMJS_VERSION 2.1.1
RUN cd /tmp && \
    wget -q https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
    tar jxf phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 && \
    mv phantomjs-$PHANTOMJS_VERSION-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs && \
    rm -rf phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 phantomjs-$PHANTOMJS_VERSION-linux-x86_64

# Redis
RUN apt-get install -y redis-server

# Ruby
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN /root/.rbenv/plugins/ruby-build/install.sh
RUN echo 'export PATH=/root/.rbenv/bin:/root/.rbenv/shims:$PATH' >> /etc/profile.d/rbenv.sh
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
RUN source /etc/profile.d/rbenv.sh
RUN rbenv install 2.4.1
RUN echo 'gem: --no-rdoc --no-ri' >> /.gemrc
RUN rbenv global 2.4.1
RUN ruby --version
RUN gem install bundler
