# Ubuntu18-systemd-full

Ubuntu 18.04 LTS Full

## Installed

- unminimized
- locale (ita)
- lang (ita)
- nano, sudo, htop, bash-completion, cron, ssh, webssh

## Credentials

- root:root
- ubuntu:ubuntu

## Webssh

Access to `localhost:8888`

## Docker compose

```
version: '2.4'

services:

  ubuntu18-systemd-full:
    container_name: ubuntu
    hostname: ubuntu
    image: adiprint/ubuntu18-systemd-full:latest
    privileged: true
    stdin_open: false
    tty: false
    restart: "no"
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    network_mode: bridge
```
