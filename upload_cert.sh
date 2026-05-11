#!/usr/bin/env sh

FULLCHAIN_PEM="$(cat /acme.sh/$DOMAIN/fullchain.cer | jq -Rs '.')"
KEY_PEM="$(cat /acme.sh/$DOMAIN/$DOMAIN.key | jq -Rs '.')"

ve configure set --profile default --region "${VOLCENGINE_REGION:-cn-beijing}" --access-key "${Volcengine_ACCESS_KEY_ID}" --secret-key "${Volcengine_SECRET_ACCESS_KEY}"

ve certificateservice ImportCertificate --body "{
    \"CertificateInfo\": {
        \"CertificateChain\": ${FULLCHAIN_PEM},
        \"PrivateKey\": ${KEY_PEM}
    },
    \"ProjectName\": \"${PROJECT_NAME:-default}\"
}"

