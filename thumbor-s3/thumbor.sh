#!/bin/sh

# Get thumbor key
/usr/bin/curl \
  -s \
  -X GET \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  https://vault.google.com:8200/v1/secret/thumbor/pictures/key | \
    sed -r 's/.*key":"([^"]*)".*/\1/' > /app/thumbor.key

# setup boto/aws config
{
echo "[default]"
echo -n "aws_access_key_id ="

/usr/bin/curl \
  -s \
  -X GET \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  https://vault.google.com:8200/v1/secret/thumbor/pictures/aws-key | \
    sed -r 's/.*key":"([^"]*)".*/\1/'

echo
echo -n "aws_secret_access_key ="

/usr/bin/curl \
  -s \
  -X GET \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  https://vault.google.com:8200/v1/secret/thumbor/pictures/aws-secret | \
    sed -r 's/.*secret":"([^"]*)".*/\1/'

echo "s3 =
    signature_version = s3"

} > /app/aws.credentials

AWS_CONFIG_FILE=/app/aws.credentials
export AWS_CONFIG_FILE

# clear vault token
unset VAULT_TOKEN

# fix config depending of the environment
/bin/sed -i "s/%ENVIRONMENT%/$ENVIRONMENT/g" /app/thumbor.conf

# minor security protection, remove write access
/bin/chmod a-w  /app/thumbor.conf /app/thumbor.key /app/aws.credentials .

# ready to launch
exec /usr/bin/thumbor --port=9900 --conf=/app/thumbor.conf  -k /app/thumbor.key

