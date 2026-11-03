FROM python:3.13 AS builder

ARG CYBERDROP_DL_VERSION="10.0.0"
ARG TARGETARCH
ARG GOTTY_VERSION="1.5.0"

WORKDIR /build

ENV PYTHONUNBUFFERED=1

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
       "cyberdrop-dl-patched==${CYBERDROP_DL_VERSION}"

RUN set -ex && \
    curl -fsSL \
      "https://github.com/sorenisanerd/gotty/releases/download/v${GOTTY_VERSION}/gotty_v${GOTTY_VERSION}_linux_${TARGETARCH:-amd64}.tar.gz" \
      | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/gotty && \
    chmod 755 /usr/local/bin/gotty


FROM python:3.13-slim

ARG APP_USER="abc"

ENV HOME=/home/abc \
    TERM=xterm-256color \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    DEBIAN_FRONTEND=noninteractive

RUN adduser --disabled-password --gecos "" --shell /bin/bash "${APP_USER}" \
    && mkdir -p /cyberdrop-dl \
    && chown -R "${APP_USER}:${APP_USER}" /home/abc /cyberdrop-dl

COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      tmux \
      ffmpeg \
      ca-certificates \
      curl \
      gosu \
      sed \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /cyberdrop-dl

ADD --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["cyberdrop-dl"]
