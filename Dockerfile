FROM alpine:latest

LABEL maintainer="Rick Rackow <rrackow@redhat.com>"

ARG HUGO_VERSION=0.163.3
ARG TARGETARCH

RUN apk add --no-cache \
    curl \
    git \
    openssh-client \
    rsync \
    build-base \
    libc6-compat

RUN set -eux; \
    arch="${TARGETARCH:-$(apk --print-arch)}"; \
    case "$arch" in \
      amd64|x86_64) hugo_arch="amd64" ;; \
      arm64|aarch64) hugo_arch="arm64" ;; \
      *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    mkdir -p /usr/local/src && \
    cd /usr/local/src && \
    curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${hugo_arch}.tar.gz" -o hugo.tar.gz && \
    tar -xzf hugo.tar.gz hugo && \
    mv hugo /usr/local/bin/hugo && \
    addgroup -Sg 1000 hugo && \
    adduser -Sg hugo -u 1000 -h /src hugo

WORKDIR /src

COPY . .

RUN hugo 

EXPOSE 1313

CMD ["hugo", "server", "--bind", "0.0.0.0"]
