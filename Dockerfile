FROM ghcr.io/pagdot/baseimage-ubuntu-nginx:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG NEXTCLOUD_RELEASE=29.0.2
LABEL build_version="pagdot version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="pagdot"

# environment settings
ENV NEXTCLOUD_PATH="/config/www/nextcloud"

RUN \
  echo "**** install runtime packages ****" && \
  apt update && \
  apt install -y \
    curl \
    ffmpeg \
    imagemagick \
    libxml2 \
    php8.1-apcu \
    php8.1-bcmath \
    php8.1-bz2 \
    php8.1-ctype \
    php8.1-curl \
    php8.1-dom \
    php8.1-exif \
    php8.1-fileinfo \
    php8.1-ftp \
    php8.1-gd \
    php8.1-gmp \
    php8.1-iconv \
    php8.1-imagick \
    php8.1-imap \
    php8.1-intl \
    php8.1-ldap \
    php8.1-mysql \
    php8.1-mbstring \
    php8.1-opcache \
    php8.1-pgsql \
    php8.1-phar \
    php8.1-posix \
    php8.1-redis \
    php8.1-simplexml \
    php8.1-sqlite3 \
    php8.1-xml \
    php8.1-xmlreader \
    php8.1-xmlwriter \
    php8.1-zip \
    samba-client \
    sudo \
    tar \
    unzip && \
  echo "**** configure php and nginx for nextcloud ****" && \
  echo 'apc.enable_cli=1' >> /etc/php/8.1/fpm/conf.d/apcu.ini && \
  echo 'apc.enable_cli=1' >> /etc/php/8.1/cli/conf.d/apcu.ini && \
  sed -i \
    -e 's/;opcache.enable.*=.*/opcache.enable=1/g' \
    -e 's/;opcache.enable_cli.*=.*/opcache.enable_cli=1/g' \
    -e 's/;opcache.interned_strings_buffer.*=.*/opcache.interned_strings_buffer=16/g' \
    -e 's/;opcache.max_accelerated_files.*=.*/opcache.max_accelerated_files=10000/g' \
    -e 's/;opcache.memory_consumption.*=.*/opcache.memory_consumption=128/g' \
    -e 's/;opcache.save_comments.*=.*/opcache.save_comments=1/g' \
    -e 's/;opcache.revalidate_freq.*=.*/opcache.revalidate_freq=1/g' \
    -e 's/memory_limit.*=.*128M/memory_limit=512M/g' \
    -e 's/max_execution_time.*=.*30/max_execution_time=120/g' \
    -e 's/upload_max_filesize.*=.*2M/upload_max_filesize=1024M/g' \
    -e 's/post_max_size.*=.*8M/post_max_size=1024M/g' \
    -e 's/output_buffering.*=.*/output_buffering=0/g' \
      /etc/php/8.1/fpm/php.ini && \
  echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php/8.1/fpm/php-fpm.conf && \
  echo "**** set version tag ****" && \
  if [ -z ${NEXTCLOUD_RELEASE+x} ]; then \
    NEXTCLOUD_RELEASE=$(curl -sX GET https://api.github.com/repos/nextcloud/server/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]' \
      | sed 's|^v||'); \
  fi && \
  echo "**** download nextcloud ****" && \
  curl -o /app/nextcloud.tar.bz2 -L \
    https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_RELEASE}.tar.bz2 && \
  echo "**** test tarball ****" && \
    tar xvf /app/nextcloud.tar.bz2 -C \
      /tmp && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
VOLUME /config
