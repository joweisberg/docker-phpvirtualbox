# docker-phpvirtualbox

This is a fork of [jazzdd/phpvirtualbox](https://hub.docker.com/r/jazzdd/phpvirtualbox/), because it is not very up to date and there are no further configuration options. This version is working with phpVirtualBox 6.1 and above

This project:

- GitHub [joweisberg/docker-phpvirtualbox](https://github.com/joweisberg/docker-phpvirtualbox/)
- Docker Hub [joweisberg/phpvirtualbox](https://hub.docker.com/r/joweisberg/phpvirtualbox/)

# phpVirtualBox 6.1 and above

[phpVirtualBox](http://sourceforge.net/projects/phpvirtualbox/) is a modern web interface that allows you to control remote VirtualBox instances - mirroring the VirtualBox GUI.

![](http://a.fsdn.com/con/app/proj/phpvirtualbox/screenshots/phpvb1.png)

## Docker image platform / architecture

The Docker image to use `joweisberg/phpvirtualbox:latest`.
Build on Linux Ubuntu 20.04 LTS, Docker 19.03 and above for:

| Platform | Architecture / Tags |
|---|---|
| x86_64 | amd64 |
| aarch64 | arm64 |
| arm | arm32 |

## Usage
This image provides the phpVirtualBox web interface that communicates with any number of VirtualBox installations on your computers.

Internally, the phpVirtualBox web interface communicates with each VirtualBox installation through the `vboxwebsrv` program that is installed as part of VirtualBox.

The container is started with following command:

```bash
$ docker run --name vbox_http --restart=always \
    -p 80:80 \
    -e TZ=Europe/Paris
    -e ID_HOSTPORT=ServerIP:PORT \
    -e ID_NAME=serverName \
    -e ID_USER=vboxUser \
    -e ID_PW='vboxUserPassword' \
    -e CONF_browserRestrictFolders="/data,/home" \
    -d joweisberg/phpvirtualbox
```

* `-p {OutsidePort}:80` - will bind the webserver to the given host port
* `-d joweisberg/phpvirtualbox` - the name of this docker image
* `-e TZ` - name of the TimeZone - ie. "Etc/UTC" or "Europe/Paris" (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
* `-e ID_NAME` - name of the vbox server - display name of the Server in the UI - could be any name
* `-e ID_HOSTPORT` - ip/hostname and port of the vbox server
* `-e ID_USER` - user name of the user in the vbox group
* `-e ID_PW` - password of this user
* `-e CONF_varName` - override default config value of varName, browserRestrictFolders is a useful example. Coma-separated strings will be converted into an array.

ID is an identifier to get all matching environment variables for one vbox server. So, it is possible to define more then one VirtualBox server and manage it with one phpVirtualbox instance.

An example would look as follows:
```nash
$ docker run --name vbox_http --restart=always -p 80:80 \
    -e TZ=Europe/Paris
    -e SRV1_HOSTPORT=192.168.1.1:18083 -e SRV1_NAME=Server1 -e SRV1_USER=user1 -e SRV1_PW='test' \
    -e SRV2_HOSTPORT=192.168.1.2:18083 -e SRV2_NAME=Server2 -e SRV2_USER=user2 -e SRV2_PW='test' \
    -d joweisberg/phpvirtualbox
```

## Running vboxwebsrv as a container
Instead of exposing the vboxwebsrv service to the outside, the [jazzdd86/vboxwebsrv](https://github.com/jazzdd86/vboxwebsrv) image could be used to establish a secure ssh connection to the server and start the vboxwebsrv service on demand and tunneling the vboxwebsrv port to the phpVirtualbox container.

See [jazzdd86/vboxwebsrv](https://github.com/jazzdd86/vboxwebsrv) for more information on how to start the vboxwebsrv service via docker image.

Example:

```bash
$ docker run -it --name=vbox_websrv_1 --restart=always jazzdd/vboxwebsrv user1@192.168.1.1
```

To install on Ubuntu following command:

```bash
echo "* [VirtualBox] Install service"
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" > /etc/apt/sources.list.d/virtualbox.list
apt update > /dev/null 2>&1
apt -y install virtualbox-6.0

echo "* [VirtualBox] Install Extpack"
vboxversion=$(wget -qO - http://download.virtualbox.org/virtualbox/LATEST.TXT)
vboxextpack=Oracle_VM_VirtualBox_Extension_Pack-$vboxversion.vbox-extpack
wget "http://download.virtualbox.org/virtualbox/$vboxversion/$vboxextpack"
echo "y" | vboxmanage extpack install --replace $vboxextpack
rm $vboxextpack
```

To run phpVirtualbox with the vboxwebsrv container use following command:

```bash
$ docker run --name vbox_http --restart=unless-stopped -p 80:80 \
    -e TZ=Europe/Paris
    -e ID_HOSTPORT=$HOST_IP:18083 -e ID_NAME=$HOST -e ID_USER=$VBOX_USR -e ID_PW=$VBOX_PWD \
    -d joweisberg/phpvirtualbox
```

## Configurations

As mentioned before `-e CONF_varName` can override default config values of varName. This configuration options can be used in two ways:

```bash
$ docker run --name vbox_http --restart=unless-stopped -p 80:80 \
    -e TZ=Europe/Paris
    -e ID_HOSTPORT=$HOST_IP:18083 -e ID_NAME=$HOST -e ID_USER=$VBOX_USR -e ID_PW=$VBOX_PWD \
    -e CONF_vrde=on -e CONF_vrdeport=9000-9010 -e CONF_vrdeaddress= -e CONF_noAuth=true \
    -e CONF_browserRestrictFolders=/data,/home,
    -d joweisberg/phpvirtualbox
```

1. `-e SRV1_CONF_browserRestrictFolders="/data,/home"` - config parameter only valid for one specific virtualbox server
2. `-e CONF_browserRestrictFolders="/data,"` - global configuration - valid for all virtualbox servers, if more than one server was specified
3. `-e CONF_vrde=on -e CONF_vrdeport=9000-9010 -e CONF_vrdeaddress= -e CONF_noAuth=true` - global configuration - to enable remote desktop access and ports without authentication

If an option requires an array but only one parameter is given enter a comma after the option (see option 2).

## Authentication

The image enables authentication by default. Default login would be admin/admin.

If using multiple servers, there is a need to specify one server as authentication server with e.g. SRV1_CONF_authMaster='true'. If no authMaster is specified, phpVirtualBox uses the first configured server.

If no authentication is used please specify -e CONF_noAuth='true'.

## Run the container via docker-compose

```yml
version: "3.5"
services:
    vbox_http:
        container_name: vbox_http
        image: joweisberg/phpvirtualbox
        restart: always
        depends_on:
            - vbox_websrv
        ports:
            - 8080:80
        environment:
            TZ="Europe/Paris"
            SRV1_HOSTPORT="vbox_websrv_1:18083"
            SRV1_NAME="Server1"
            SRV1_USER="user1"
            SRV1_PW="test"
            SRV2_HOSTPORT="192.168.1.2:18083"
            SRV2_NAME="Server2"
            SRV2_USER="user2"
            SRV2_PW="test"
            SRV2_CONF_browserRestrictFolders="/data,"
            SRV2_CONF_authMaster="true"
            CONF_browserRestrictFolders="/home,/usr/lib/virtualbox,"
            CONF_noAuth="true"

    vbox_websrv:
        container_name: vbox_websrv_1
        image: jazzdd/vboxwebsrv
        command: user1@192.168.1.1
        restart: always
        environment:
            USE_KEY: 1
        volumes:
            - "./ssh:/root/.ssh"
```
