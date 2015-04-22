#!/bin/bash
set -e

if [ "$1" = 'couchdb' ]; then
  # we need to set the permissions here because docker mounts volumes as root
  chown -R couchdb:couchdb \
    /usr/local/var/lib/couchdb \
    /usr/local/var/log/couchdb \
    /usr/local/var/run/couchdb \
    /usr/local/etc/couchdb

  chmod -R 0770 \
    /usr/local/var/lib/couchdb \
    /usr/local/var/log/couchdb \
    /usr/local/var/run/couchdb \
    /usr/local/etc/couchdb

  chmod 664 /usr/local/etc/couchdb/*.ini
  chmod 775 /usr/local/etc/couchdb/*.d
  HOME=/var/lib/couchdb exec gosu couchdb "$@"

elif [ "$1" = 'setup' ]; then
  sleep 10

  ruby /setup.rb

  #write out current crontab
  crontab -l > mycron
  #echo new cron into cron file
  echo "*/5 * * * * ruby /setup.rb" >> mycron
  #install new cron file
  crontab mycron
  rm mycron

else

  exec "$@"
fi


