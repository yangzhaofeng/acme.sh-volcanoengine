#!/usr/bin/env sh

FULLCHAIN_PEM="$(cat /acme.sh/$DOMAIN/fullchain.cer | jq -Rs '.')"
KEY_PEM="$(cat /acme.sh/$DOMAIN/$DOMAIN.key | jq -Rs '.')"

ve configure set --profile default --region "${VOLCENGINE_REGION:-cn-beijing}" --access-key "${Volcengine_ACCESS_KEY_ID}" --secret-key "${Volcengine_SECRET_ACCESS_KEY}"

result="$(ve certificateservice ImportCertificate --body \"{
    \\"CertificateInfo\\": {
        \\"CertificateChain\\": ${FULLCHAIN_PEM},
        \\"PrivateKey\\": ${KEY_PEM}
    },
    \\"ProjectName\\": \\"${PROJECT_NAME:-default}\\"
}\")"

instanceid="$(echo \"${result}\" | jq '.Result.InstanceId')"
repeatid="$(echo \"${result}\" | jq '.Result.RepeatId')"

if [ -n "${repeatid}" ]; then
    echo "Certificate ${repeatid} already exists on cloud, skipping..."
    exit 1
else
    echo "Certificate successfully uploaded. Certificate Instance ID:"
    echo "${instanceid}"
fi

ve clb ModifyListenerAttributes --CertCenterCertificateId "${instanceid}" --ListenerId "${VOLCENGINE_CLB_LISTENER_ID}"
