FROM neilpang/acme.sh:latest

ARG VC_VERSION=1.0.40

COPY volcengine_dns_api/dns_volcengine.sh /install_acme.sh/dnsapi
COPY upload_cert.sh /install_acme.sh

RUN cd /tmp && wget "https://github.com/volcengine/volcengine-cli/releases/download/v${VC_VERSION}/volcengine-cli_${VC_VERSION}_linux_${TARGETARCH}.zip"
