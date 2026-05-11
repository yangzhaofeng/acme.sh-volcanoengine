#!/usr/bin/env sh

FULLCHAIN_PEM="$(cat /acme.sh/$DOMAIN/fullchain.cer)"
KEY_PEM="$(cat /acme.sh/$DOMAIN/$DOMAIN.key)"

ve configure set --profile default --region "${VOLCENGINE_REGION:-cn-beijing}" --access-key "${VOLCENGINE_ACCESS_KEY_ID}" --secret-key "${VOLCENGINE_SECRET_ACCESS_KEY}"

ve certificateservice ImportCertificate --body "{
    'CertificateInfo': {
        'CertificateChain': '${FULLCHAIN_PEM}'
        'PrivateKey': '${KEY_PEM}'
    },
    'ProjectName': '${PROJECT_NAME:-default}'
}"
