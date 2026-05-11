#!/usr/bin/env sh

volc_crtctr() {
  _info "Starting Volcengine Certificate Upload..."

  VOLC_AK="${VOLC_AK:-$VOLCENGINE_ACCESS_KEY_ID}"
  VOLC_SK="${VOLC_SK:-$VOLCENGINE_SECRET_ACCESS_KEY}"
  VOLC_REGION="${VOLC_REGION:-$VOLCENGINE_REGION}"

  if [ -z "$VOLC_AK" ] || [ -z "$VOLC_SK" ]; then
    _err "VOLC_AK and VOLC_SK are required."
    return 1
  fi

  if [ -z "$REAL_FULLCHAIN_PATH" ] || [ -z "$REAL_KEY_PATH" ]; then
     _err "Certificate path not found. Are you running this via acme.sh --deploy?"
     return 1
  fi

  _cert_content=$(cat "$REAL_FULLCHAIN_PATH")
  _key_content=$(cat "$REAL_KEY_PATH")
  _cert_name="acme-$(echo "$_main_domain" | tr '.' '-')-$(date +%s)"

  _service="certificate-service"
  _host="certificate-service.volcengineapi.com"
  _action="UploadCertificate"
  _version="2021-02-01"
  _timestamp=$(date -u +%Y%m%dT%H%M%SZ)
  _date=$(echo "$_timestamp" | cut -c 1-8)

  _payload="{\"CertificateName\":\"$_cert_name\",\"PublicKey\":\"${_cert_content//$'\n'/\\n}\",\"PrivateKey\":\"${_key_content//$'\n'/\\n}\",\"Repeatable\":true}"
  
  _content_sha256=$(printf "%s" "$_payload" | openssl dgst -sha256 -hex | sed 's/^.* //')

  _canonical_uri="/"
  _canonical_querystring="Action=$_action&Version=$_version"
  _canonical_headers="content-type:application/json\nhost:$_host\nx-content-sha256:$_content_sha256\nx-date:$_timestamp\n"
  _signed_headers="content-type;host;x-content-sha256;x-date"
  
  _canonical_request=$(printf "POST\n%s\n%s\n%s\n%s\n%s" \
    "$_canonical_uri" "$_canonical_querystring" "$_canonical_headers" "$_signed_headers" "$_content_sha256")

  _hashed_canonical_request=$(printf "%s" "$_canonical_request" | openssl dgst -sha256 -hex | sed 's/^.* //')

  _string_to_sign=$(printf "HMAC-SHA256\n%s\n%s/%s/%s/request\n%s" \
    "$_timestamp" "$_date" "$VOLC_REGION" "$_service" "$_hashed_canonical_request")

  hmac_sha256() {
    printf "$1" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$2" -hex | sed 's/^.* //'
  }

  _k_date=$(printf "$_date" | openssl dgst -sha256 -mac HMAC -macopt "key:$VOLC_SK" -hex | sed 's/^.* //')
  _k_region=$(printf "$VOLC_REGION" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$_k_date" -hex | sed 's/^.* //')
  _k_service=$(printf "$_service" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$_k_region" -hex | sed 's/^.* //')
  _k_signing=$(printf "request" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$_k_service" -hex | sed 's/^.* //')

  _signature=$(printf "$_string_to_sign" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$_k_signing" -hex | sed 's/^.* //')

  _auth_header="HMAC-SHA256 Credential=$VOLC_AK/$_date/$VOLC_REGION/$_service/request, SignedHeaders=$_signed_headers, Signature=$_signature"

  _response=$(curl -s -X POST "https://$_host/?$_canonical_querystring" \
    -H "Authorization: $_auth_header" \
    -H "Content-Type: application/json" \
    -H "X-Date: $_timestamp" \
    -H "X-Content-Sha256: $_content_sha256" \
    -d "$_payload")

  if echo "$_response" | grep -q "CertificateId"; then
    _info "Success: Certificate uploaded. Response: $_response"
    return 0
  else
    _err "Failed: $_response"
    return 1
  fi
}

if [ -z "$_main_domain" ]; then
    _info() { echo "[INFO] $@"; }
    _err() { echo "[ERROR] $@"; }
    _main_domain="$DOMAIN"
    REAL_FULLCHAIN_PATH="$CERT_PATH"
    REAL_KEY_PATH="$KEY_PATH"
    volc_upload_deploy
fi
