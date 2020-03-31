#!/usr/bin/env bash

set -o errexit

# Create a container
container=$(buildah from debian:buster-20200224-slim)

# Labels
buildah config --label maintainer="lRamm <lukas.ramm.1998@gmail.com>" $container

#---
# Install apt-cacher-ng
buildah run $container apt update
echo "yes" >&1 | buildah run $container apt install -y apt-cacher-ng wget
buildah run $container rm -rf /var/lib/apt/lists/*
buildah commit $container

#---
# Mirror-List repo
if [ ! -d "../apt-cacher-ng-remap" ]; then
  cd ..
  git clone https://github.com/xXluki98Xx/apt-cacher-ng-remap.git
  cd apt-cacher-ng-remap
else
  cd ../apt-cacher-ng-remap
  git pull
fi

./centos.sh
./fedora.sh
./fedora-epel.sh
./debian.sh
./ubuntu.sh
cd ../buildah_apt-cacher-ng

#---
# Prepare Container
buildah run $container mkdir -p /etc/apt-cacher-ng/mirror_list.d
buildah copy $container ../apt-cacher-ng-remap/list* /etc/apt-cacher-ng/mirror_list.d/
rm ../apt-cacher-ng-remap/list.*

buildah copy $container ../apt-cacher-ng-remap /mirror_scripts
buildah run $container mv /etc/apt-cacher-ng/acng.conf /etc/apt-cacher-ng/acng.conf.orig
buildah copy $container acng.conf /etc/apt-cacher-ng/
buildah copy $container entrypoint.sh /entrypoint.sh
buildah commit $container

#---
# Config Container
buildah config \
		--healthcheck-timeout 2s \
		--healthcheck-retries 3 \
		--healthcheck-interval 10s \
		--healthcheck "wget -q -t1 -o /dev/null  http://localhost:3142/acng-report.html || exit 1" \
		--entrypoint /entrypoint.sh \
		--env APT_CACHER_NG_USER=apt-cacher-ng \
		--env APT_CACHER_NG_LOG_DIR="/var/log/apt-cacher-ng" \
		--env APT_CACHER_NG_CACHE_DIR="/var/cache/apt-cacher-ng" \
		--port 3142/tcp \
		$container

buildah commit --format docker $container apt-cacher-ng