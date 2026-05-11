FROM debian:stable AS builder

ARG VC_VERSION=1.0.40
ARG TARGETARCH

RUN apt update && apt install -y unar wget

WORKDIR /tmp

RUN wget "https://github.com/volcengine/volcengine-cli/releases/download/v${VC_VERSION}/volcengine-cli_${VC_VERSION}_linux_${TARGETARCH}.zip" -O volcengine-cli.zip
RUN unar volcengine-cli.zip


FROM neilpang/acme.sh:latest

COPY acme_volcengine_dns_api/dnsapi/dns_volcengine.sh /acmebin/dnsapi/
COPY upload_cert.sh /acmebin/

COPY --from=builder /tmp/volcengine-cli/ve /usr/local/bin
