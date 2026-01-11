#!/bin/bash
API_TOKEN="bDpxwjREOdHcMqSgU7Xk6WwZ4fkyN1oTVPYBtlvUec944902"
EMAIL="support@cyberfence.in"

# Extract the root/base domain — assumes `*.bytesec.co.in` or `sub.domain.tld`
BASE_DOMAIN=$(echo "$CERTBOT_DOMAIN" | awk -F'.' '{print $(NF-1)"."$NF}')

# DNS record name to create
RECORD_NAME="_acme-challenge.$CERTBOT_DOMAIN"

# Hostinger API endpoint
API_URL="https://developers.hostinger.com/api/dns/v1/zones/${CERTBOT_DOMAIN}"

# Create DNS TXT record using Hostinger API
curl -s -X PUT "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{
    "overwrite": true,
    "zone": [
      {
        "name": "'"$RECORD_NAME"'",
        "type": "TXT",
        "ttl": 120,
        "records": [
          {
            "content": "'"$CERTBOT_VALIDATION"'"
          }
        ]
      }
    ]
  }'

echo " TXT record created for $RECORD_NAME"
echo " Sleeping for 60 seconds to allow DNS to propagate..."
sleep 60
