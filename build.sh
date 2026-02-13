#!/bin/bash
#
# Selects appropriate base images and Qemu archs 
# (but doesn’t yet check if they all exist and all - that’s your homework ;) 
# and also removes unnecessary qemu for amd64
#
# https://github.com/multiarch/qemu-user-static
# https://lobradov.github.io/Building-docker-multiarch-images/
# https://ownyourbits.com/2018/06/27/running-and-building-arm-docker-containers-in-x86/
#
# Build/Test specific Dockerfile:
# docker build -f Dockerfile.arm32  -t joweisberg/glances:arm32 .
# docker run -it --rm arm32v7/python:slim uname -m
# docker run -it --rm arm32v7/python:slim cat /etc/localtime
# docker run -it --rm arm32v7/python:slim cat /etc/timezone
#

FILE_PATH=$(readlink -f $(dirname $0))  #/home/media/docker-certs-extraction
FILE_NAME=$(basename $0)                #build.sh
FILE_NAME=${FILE_NAME%.*}               #build
FILE_DATE=$(date +'%Y%m%d-%H%M%S')
FILE_LOG="/var/log/$FILE_NAME.log"

DOCKER_USER="joweisberg"

if [ -z "$1" ] || [ -z "$(echo $1 | grep '/')" ]; then
  echo "* Require one parameter as <docker_user/docker_respository>:"
  # ./build.sh certs-extraction
  echo "* ./$(basename $0) $DOCKER_USER/$(echo ${FILE_PATH##*/} | sed 's/docker-//g')"
  exit 1
fi
DOCKER_USER=$(echo $1 | cut -d'/' -f1)
DOCKER_REPO=$(echo $1 | cut -d'/' -f2)

echo "* Sign In to https://hub.docker.com/u/$DOCKER_USER"
docker login -u $DOCKER_USER docker.io
if [ $? -ne 0 ]; then
  exit 1
fi

runstart=$(date +%s)
echo "* "
echo "* Command: $0 $@"
echo "* Start time: $(date)"
echo "* "

echo -n "* Create a builder instance..."
docker buildx create --name mybuilder > /dev/null
docker buildx use mybuilder > /dev/null
echo "Done"

echo "* "
echo "* Building and pushing multi-arch image"
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag $DOCKER_USER/$DOCKER_REPO:latest \
  --push \
  .

echo "* "
echo -n "* Remove builder instances..."
docker buildx stop mybuilder > /dev/null
docker buildx rm mybuilder > /dev/null 2>&1
echo "Done"

echo "* "
echo "* End time: $(date)"
runend=$(date +%s)
runtime=$((runend-runstart))
echo "* Elapsed time: $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"

echo "* "
echo -n "* Remove unused volumes and images? [y/N] "
read answer
if [ -n "$(echo $answer | grep -i '^y')" ]; then
  echo "* "
  docker system prune --all --volumes --force
fi

exit 0