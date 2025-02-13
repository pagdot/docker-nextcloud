FROM ghcr.io/pagdot/baseimage-ubuntu-nginx:noble

# set version label
ARG BUILD_DATE
ARG VERSION
ARG NEXTCLOUD_RELEASE=30.0.6
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
    lbzip2 \
    libxml2 \
    php8.3-apcu \
    php8.3-bcmath \
    php8.3-bz2 \
    php8.3-ctype \
    php8.3-curl \
    php8.3-dom \
    php8.3-exif \
    php8.3-fileinfo \
    php8.3-ftp \
    php8.3-gd \
    php8.3-gmp \
    php8.3-iconv \
    php8.3-imagick \
    php8.3-imap \
    php8.3-intl \
    php8.3-ldap \
    php8.3-mysql \
    php8.3-mbstring \
    php8.3-opcache \
    php8.3-pgsql \
    php8.3-phar \
    php8.3-posix \
    php8.3-redis \
    php8.3-simplexml \
    php8.3-sqlite3 \
    php8.3-xml \
    php8.3-xmlreader \
    php8.3-xmlwriter \
    php8.3-zip \
    rsync \
    samba-client \
    util-linux \
    sudo && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -E -i 's/^;?clear_env ?=.*$/clear_env = no/g' /etc/php/8.3/fpm/pool.d/www.conf && \
  grep -qxF 'clear_env = no' /etc/php/8.3/fpm/pool.d/www.conf || echo 'clear_env = no' >> /etc/php/8.3/fpm/pool.d/www.conf && \
  echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php/8.3/fpm/php-fpm.conf && \
  echo "**** configure php for nextcloud ****" && \
  { \
    echo 'apc.enable_cli=1'; \
  } >> /etc/php/8.3/fpm/conf.d/apcu.ini && \
  { \
    echo 'apc.enable_cli=1'; \
  } >> /etc/php/8.3/cli/conf.d/apcu.ini && \
  { \
    echo 'opcache.enable=1'; \
    echo 'opcache.interned_strings_buffer=32'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.jit=1255'; \
    echo 'opcache.jit_buffer_size=128M'; \
  } >> "/etc/php/8.3/fpm/conf.d/91_opcache.ini" && \
  { \
    echo 'memory_limit=512M'; \
    echo 'upload_max_filesize=512M'; \
    echo 'post_max_size=512M'; \
    echo 'max_input_time=300'; \
    echo 'max_execution_time=300'; \
    echo 'output_buffering=0'; \
    echo 'always_populate_raw_post_data=-1'; \
  } >> "/etc/php/8.3/fpm/conf.d/nextcloud.ini" && \
  echo "**** install nextcloud ****" && \
  mkdir -p \
    /app/www/src/ && \
  if [ -z ${NEXTCLOUD_RELEASE+x} ]; then \
    NEXTCLOUD_RELEASE=$(curl -sX GET https://api.github.com/repos/nextcloud/server/releases \
      | jq -r '.[] | select(.prerelease != true) | .tag_name' \
      | sed 's|^v||g' | sort -rV | head -1); \
  fi && \
  curl -o \
    /tmp/nextcloud.tar.bz2 -L \
    https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_RELEASE}.tar.bz2 && \
  tar xf /tmp/nextcloud.tar.bz2 -C \
    /app/www/src --strip-components=1 && \
  rm -rf /app/www/src/updater && \
  mkdir -p /app/www/src/data && \
  chmod +x /app/www/src/occ && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
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
