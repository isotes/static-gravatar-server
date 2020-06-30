FROM ubuntu:20.04

LABEL name="static-gravatar-server-prepare"
LABEL version="1.0.0"
LABEL description="Prepare script for static-gravatar-server"
LABEL vendor="isotes"
LABEL maintainer="isotes <isotes@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

RUN true && \
	apt-get update && \
	apt-get install -y locales imagemagick && \
	locale-gen en_US.UTF-8 && \
	apt-get clean autoclean -y && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/* && \
	true

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

COPY ./prepare /usr/local/bin/static-gravatar-server-prepare
ENTRYPOINT ["/usr/local/bin/static-gravatar-server-prepare"]

WORKDIR /x
