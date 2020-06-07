FROM jrei/systemd-ubuntu:18.04

# environment variable

ENV container docker
ENV DEBIAN_FRONTEND noninteractive
ENV ROOT_PWD root
ENV USER_UID 1000
ENV USER_GID 1000
ENV USER_NAME ubuntu
ENV USER_GROUP ubuntu
ENV USER_PWD ubuntu
ENV USER_HOME /home/ubuntu
ENV NOTVISIBLE "in users profile"

# enable all repos

RUN set -xev; sed -i 's/# deb/deb/g' /etc/apt/sources.list

# unminimize ubuntu

RUN yes | unminimize

# install some utils

RUN set -xe \
    && apt-get update \
    && apt-get install -y apt-utils tzdata locales

# setting locale and timezone

ENV TZ=Europe/Rome

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
     && echo $TZ > /etc/timezone

RUN set -xe &&\
    dpkg-reconfigure --frontend=noninteractive tzdata && \
    sed -i -e 's/# it_IT.UTF-8 UTF-8/it_IT.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="it_IT.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=it_IT.UTF-8

ENV LANG it_IT.UTF-8
ENV LANGUAGE it_IT.UTF-8
ENV LC_ALL it_IT.UTF-8

# install utils and software

RUN set -xev; \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        openssl nano sudo htop \
        wget curl net-tools xz-utils rsyslog \
        pigz bash-completion python3-pip \
        vim perl tar man adduser netstat-nat w3m \
        openssh-server iputils-ping cron && \
    apt-get clean && \
    rm -rf /usr/share/doc/* /usr/share/man/* /var/lib/apt/lists/* /tmp/* /var/tmp/*

# enable syslog

RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

# set ssh options (not secure for production!)

RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#StrictModes yes/StrictModes no/' /etc/ssh/sshd_config
RUN sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN echo "export VISIBLE=now" >> /etc/profile

# craete group and user

RUN set -xev; \
	groupadd -g $USER_GID $USER_GROUP

RUN set -xev; \
   useradd -rm \
	-d $USER_HOME \
	-s /bin/bash \
	-p "$(openssl passwd -1 $USER_PWD)" \
	-g $USER_GROUP \
	-G root \
	-u $USER_UID \
	$USER_NAME

# set password for root

RUN echo root:"${ROOT_PWD}" | chpasswd

# enable user to execute sudo without password

RUN echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# enable bash completion

RUN echo "source /etc/profile.d/bash_completion.sh" >> /home/$USER_NAME/.bashrc
RUN echo "source /etc/profile.d/bash_completion.sh" >> /root/.bashrc

RUN grep -wq '^source /etc/profile.d/bash_completion.sh' /home/$USER_NAME/.bashrc || echo 'source /etc/profile.d/bash_completion.sh' >> /home/$USER_NAME/.bashrc
RUN grep -wq '^source /etc/profile.d/bash_completion.sh' /root/.bashrc || echo 'source /etc/profile.d/bash_completion.sh' >> /root/.bashrc

# install python webssh

RUN pip3 install webssh
RUN touch /var/log/cron.log
RUN (crontab -l ; echo "@reboot /usr/local/bin/wssh --fbidhttp=False >> /var/log/cron-webssh.log 2>&1") | crontab

# copy custom .bashrc

COPY ./.bashrc /home/$USER_NAME/.bashrc
RUN chown $USER_NAME:$USER_NAME /home/$USER_NAME/.bashrc
COPY ./.bashrc /root/.bashrc

# enable services

RUN systemctl enable cron.service
RUN systemctl enable ssh.service

# expose ssh and webssh port

EXPOSE 22 8888

WORKDIR $USER_HOME
