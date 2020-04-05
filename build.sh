#!/bin/sh

cd /home/media/docker-phpvirtualbox
git clone https://github.com/jazzdd86/phpVirtualbox.git .
sed -i "s/5.2-1/develop/g" Dockerfile
# docker build -t jazzdd/phpvirtualbox .
docker build -t local/phpvirtualbox .
