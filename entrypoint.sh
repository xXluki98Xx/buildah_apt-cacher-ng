#!/bin/bash
set -e

#---
# Folder creation orignal from sameersbn/docker-apt-cacher-ng

create_pid_dir() {
  mkdir -p /run/apt-cacher-ng
  chmod -R 0755 /run/apt-cacher-ng
  chown ${APT_CACHER_NG_USER}:${APT_CACHER_NG_USER} /run/apt-cacher-ng
}

create_cache_dir() {
  mkdir -p ${APT_CACHER_NG_CACHE_DIR}
  chmod -R 0755 ${APT_CACHER_NG_CACHE_DIR}
  chown -R ${APT_CACHER_NG_USER}:root ${APT_CACHER_NG_CACHE_DIR}
}

create_log_dir() {
  mkdir -p ${APT_CACHER_NG_LOG_DIR}
  chmod -R 0755 ${APT_CACHER_NG_LOG_DIR}
  chown -R ${APT_CACHER_NG_USER}:${APT_CACHER_NG_USER} ${APT_CACHER_NG_LOG_DIR}
}

update_config(){
  sed "s#CacheDir: /var/cache/apt-cacher-ng#CacheDir: ${APT_CACHER_NG_CACHE_DIR}#" -i /etc/apt-cacher-ng/acng.conf
  sed "s#LogDir: /var/log/apt-cacher-ng#LogDir: ${APT_CACHER_NG_LOG_DIR}#" -i /etc/apt-cacher-ng/acng.conf
}

mirror_lists(){
  if [ -z "$(ls -A /etc/apt-cacher-ng/mirror_list.d)" ]; then
    echo "mirror lists doesnt exist, will created"
    cd /mirror_scripts;
    ./centos.sh;
    ./fedora.sh;
    ./fedora-epel.sh;
    mv list.* /etc/apt-cacher-ng/mirror_list.d/;
    echo "mirror lists created, starting server"
  fi
}

create_pid_dir
create_cache_dir
create_log_dir
update_config
mirror_lists

#---

while true; do sleep 15s && rm -v /acng-report* 2>| /dev/null || echo clean ; done &
bash /etc/init.d/apt-cacher-ng start && tail -f /var/log/apt-cacher-ng/*
