FROM ghcr.io/linuxserver/baseimage-alpine:3.14

# set version label
ARG BUILD_DATE
ARG VERSION
ARG BAZARR_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chbmb"
# hard set UTC in case the user does not define it
ENV TZ="Etc/UTC"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    cargo \
    g++ \
    gcc \
    jq \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    python3-dev && \
  echo "**** install packages ****" && \
  apk add --no-cache \
    curl \
    ffmpeg \
    libxml2 \
    libxslt \
    py3-pip \
    python3 \
    unrar \
    unzip && \
  echo "**** install bazarr ****" && \
  if [ -z ${BAZARR_VERSION+x} ]; then \
    BAZARR_VERSION=$(curl -sX GET "https://api.github.com/repos/morpheus65535/bazarr/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/bazarr.zip -L \
    "https://github.com/morpheus65535/bazarr/releases/download/${BAZARR_VERSION}/bazarr.zip" && \
  mkdir -p \
    /app/bazarr/bin && \
  unzip \
    /tmp/bazarr.zip -d \
    /app/bazarr/bin && \
  rm -Rf /app/bazarr/bin/bin && \
  echo "UpdateMethod=docker\nBranch=master\nPackageVersion=${VERSION}\nPackageAuthor=[linuxserver.io](https://linuxserver.io)" > /app/bazarr/package_info && \
  echo "**** Install requirements ****" && \
  pip3 install -U --no-cache-dir pip && \
  pip install lxml --no-binary :all: && \
  pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine/  -r \
    /app/bazarr/bin/requirements.txt && \
  echo "**** clean up ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /root/.cargo \
    /tmp/*

# add ffsubsync
RUN apk add ffmpeg py3-scipy g++ openblas py3-numpy-dev git python3-dev py3-pip
RUN pip3 install cython git+https://github.com/smacke/ffsubsync@latest


# add local files
COPY root/ /

# ports and volumes
EXPOSE 6767
VOLUME /config
