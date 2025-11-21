FROM scratch

LABEL \
  org.opencontainers.image.title="Arch Linux Base Image" \
  org.opencontainers.image.description="Minimal Arch Linux Docker base image with pacman support" \
  org.opencontainers.image.source="https://github.com/luzifer-docker/archlinux" \
  org.opencontainers.image.licenses="GPL-3.0-only" \
  org.opencontainers.image.authors="https://github.com/luzifer-docker/archlinux/graphs/contributors" \
  org.opencontainers.image.created="${BUILD_TIMESTAMP}" \
  org.opencontainers.image.documentation="https://github.com/luzifer-docker/archlinux/blob/master/README.md"

ENV LANG=en_US.UTF-8

ADD archlinux.tar /

CMD ["/usr/bin/bash"]
