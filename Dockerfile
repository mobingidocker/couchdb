FROM ubuntu:14.04
MAINTAINER David Siaw <david.siaw@mobingi.com>

# Install instructions from https://cwiki.apache.org/confluence/display/COUCHDB/Debian

ENV COUCHDB_VERSION 1.6.1

RUN groupadd -r couchdb && useradd -d /var/lib/couchdb -g couchdb couchdb

# download dependencies, compile and install couchdb
RUN apt-get update && \
    apt-get -y install supervisor build-essential erlang-base-hipe erlang-dev erlang-manpages erlang-eunit erlang-nox libicu-dev libmozjs185-dev libcurl4-openssl-dev curl ruby && \
    apt-get -y install wget && \
    wget http://mirrors.advancedhosters.com/apache/couchdb/source/1.6.1/apache-couchdb-1.6.1.tar.gz &&\
    tar xzvf apache-couchdb-*.tar.gz && \
    cd apache* && \
    ./configure && \
    make && make install && \
    chown -R couchdb:couchdb /usr/local/var/lib/couchdb && \
    chown -R couchdb:couchdb /usr/local/var/log/couchdb && \
    chown -R couchdb:couchdb /usr/local/var/run/couchdb && \
    chown -R couchdb:couchdb /usr/local/etc/couchdb && \
    chmod 0770 /usr/local/var/lib/couchdb/ && \
    chmod 0770 /usr/local/var/log/couchdb/ && \
    chmod 0770 /usr/local/var/run/couchdb/ && \
    chmod 0770 /usr/local/etc/couchdb/*.ini && \
    chmod 0770 /usr/local/etc/couchdb/*.d && \
    ln -s /usr/local/etc/logrotate.d/couchdb /etc/logrotate.d/couchdb && \
    ln -s /usr/local/etc/init.d/couchdb /etc/init.d && \
    update-rc.d couchdb defaults

# grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
  && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
  && gpg --verify /usr/local/bin/gosu.asc \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu

# permissions
RUN chown -R couchdb:couchdb \
    /usr/local/lib/couchdb /usr/local/etc/couchdb \
    /usr/local/var/lib/couchdb /usr/local/var/log/couchdb /usr/local/var/run/couchdb \
  && chmod -R g+rw \
    /usr/local/lib/couchdb /usr/local/etc/couchdb \
    /usr/local/var/lib/couchdb /usr/local/var/log/couchdb /usr/local/var/run/couchdb \
  && mkdir -p /var/lib/couchdb

# Expose to the outside
RUN sed -e 's/^bind_address = .*$/bind_address = 0.0.0.0/' -i /usr/local/etc/couchdb/default.ini

RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./docker-entrypoint.sh /entrypoint.sh
COPY setup.rb /setup.rb

# Define mountable directories. (removed for now because it does not fit our purposes)
# VOLUME ["/usr/local/var/log/couchdb", "/usr/local/var/lib/couchdb"]

EXPOSE 5984
WORKDIR /var/lib/couchdb

RUN chmod +x /entrypoint.sh
RUN echo "complete" > /var/log/container_status

CMD ["/usr/bin/supervisord"]
