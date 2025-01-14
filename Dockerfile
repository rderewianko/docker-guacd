# guacamole builder
FROM ghcr.io/linuxserver/baseimage-alpine:3.15 as guacbuilder

ARG GUACD_VERSION=1.4.0

RUN \
 echo "**** install build deps ****" && \
 apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
	ossp-uuid-dev && \
 apk add --no-cache \
	cairo-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	ffmpeg-dev \
	freerdp-dev \
	openssl-dev \
	ossp-uuid-dev \
	pango-dev \
	pulseaudio-dev \
	libssh2-dev \
	libvncserver-dev \
	libvorbis-dev \	
	libwebp-dev \
	libwebsockets-dev \
	perl \
	cunit-dev \
	autoconf \
	automake \
	alpine-sdk

RUN \
 echo "**** compile guacamole ****" && \
 mkdir /buildout && \
 mkdir /tmp/guac && \
 cd /tmp/guac && \
 wget \
	http://apache.org/dyn/closer.cgi?action=download\&filename=guacamole/${GUACD_VERSION}/source/guacamole-server-${GUACD_VERSION}.tar.gz \
	-O guac.tar.gz && \
 tar -xf guac.tar.gz && \
 wget \ 
	https://raw.githubusercontent.com/apache/guacamole-server/master/src/guacenc/ffmpeg-compat.c \
	-O /tmp/guac/guacamole-server-${GUACD_VERSION}/src/guacenc/ffmpeg-compat.c && \
 cd guacamole-server-${GUACD_VERSION} && \
 ./configure \
	--prefix=/usr \
	--sysconfdir=/etc \
	--mandir=/usr/share/man \
	--localstatedir=/var \
	--disable-static \
	--with-libavcodec \
	--with-libavutil \
	--with-libswscale \
	--with-ssl \
	--without-winsock \
	--with-vorbis \
	--with-pulse \
	--with-pango \
	--with-terminal \
	--with-vnc \
	--with-rdp \
	--with-ssh \
	--without-telnet \
	--with-webp \
	--with-websockets && \
 make && \
 make DESTDIR=/buildout install

# runtime stage
FROM ghcr.io/linuxserver/baseimage-alpine:3.15

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# Copy build outputs
COPY --from=guacbuilder /buildout /

RUN \ 
 echo "**** install packages ****" && \
 apk add --no-cache \
	cairo \
	ffmpeg-libs \
	font-terminus-nerd \
	freerdp-libs \
	glib \
	libcrypto1.1 \
	libjpeg-turbo \
	libpng \
	libpulse \
	libssh2 \
	libssl1.1 \
	libvncserver \
	libwebp \
	libwebsockets \
	pango && \
 apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
	ossp-uuid && \
 echo "**** cleanup ****" && \
 rm -rf \
        /tmp/*

# add local files
COPY /root /

# ports
EXPOSE 4822
