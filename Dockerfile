FROM neilpang/acme.sh:latest

COPY volcengine_dns_api/dns_volcengine.sh /install_acme.sh/dnsapi

COPY deploy/volc_certctr.sh /install_acme.sh/deploy
