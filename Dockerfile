FROM debian:stable AS builder

ARG VC_VERSION=1.0.40
ARG TARGETARCH

RUN apt update && apt install -y unar

WORKDIR /tmp

RUN wget https://github.com/volcengine/volcengine-cli/releases/download/v${VC_VERSION}/volcengine-cli_${VC_VERSION}_linux_${TARGETARCH}.zip -O volcengine-cli.zip
RUN unar volcengine-cli.zip


FROM neilpang/acme.sh:latest

COPY volcengine_dns_api/dns_volcengine.sh /install_acme.sh/dnsapi
COPY upload_cert.sh /install_acme.sh

COPY --from=builder /tmp/volcengine-cli/ve /usr/local/bin
