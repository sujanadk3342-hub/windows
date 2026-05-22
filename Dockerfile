# syntax=docker/dockerfile:1

ARG VERSION_ARG="latest"

# ==========================================
# AMD64 BUILD STAGE
# ==========================================
FROM ubuntu:24.04 AS build-amd64

COPY --from=qemux/qemu:7.30 / /

ARG TARGETARCH
ARG VERSION_WSDD="1.24"
ARG VERSION_VIRTIO="1.9.57"

ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"

RUN set -eux && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        samba \
        wimtools \
        dos2unix \
        cabextract \
        libxml2-utils \
        libarchive-tools \
        wget \
        tini && \
    wget "https://github.com/gershnik/wsdd-native/releases/download/v${VERSION_WSDD}/wsddn_${VERSION_WSDD}_${TARGETARCH}.deb" \
        -O /tmp/wsddn.deb -q && \
    dpkg -i /tmp/wsddn.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chmod=755 ./src /run/
COPY --chmod=755 ./assets /run/assets

ADD --chmod=664 \
    https://github.com/qemus/virtiso-whql/releases/download/v${VERSION_VIRTIO}-0/virtio-win-${VERSION_VIRTIO}.tar.xz \
    /var/drivers.txz

# ==========================================
# ARM64 BUILD STAGE
# ==========================================
FROM dockurr/windows-arm:${VERSION_ARG} AS build-arm64

# ==========================================
# FINAL IMAGE
# ==========================================
FROM build-${TARGETARCH}

ARG VERSION_ARG="0.00"

RUN echo "$VERSION_ARG" > /run/version

# ==========================================
# FIX STORAGE ISSUE
# ==========================================
RUN mkdir -p /storage && \
    chmod 777 /storage

ENV STORAGE="/storage"

# ==========================================
# WINDOWS SETTINGS
# ==========================================
# Use Windows 7 or 8
ENV VERSION="7"

# Low resource usage
ENV RAM_SIZE="1G"
ENV CPU_CORES="2"
ENV DISK_SIZE="32G"

# ==========================================
# OPTIONAL PERFORMANCE SETTINGS
# ==========================================
ENV CPU_MODEL="host"
ENV BOOT_MODE="windows_legacy"

# ==========================================
# PORTS
# ==========================================
EXPOSE 3389
EXPOSE 8006

# ==========================================
# AUTO-FIX STORAGE AT CONTAINER START
# ==========================================
RUN sed -i 's|\[ ! -d "/storage" \].*|mkdir -p /storage \&\& chmod 777 /storage|g' /run/entry.sh || true

# ==========================================
# START CONTAINER
# ==========================================
ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
