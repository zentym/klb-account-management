#!/bin/bash
echo "🔑 Getting token from Docker network..."

# Get token using container hostname  
TOKEN_RESPONSE=$(curl -s -X POST 'http://klb-keycloak:8080/realms/Kienlongbank/protocol/openid-connect/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password&client_id=klb-frontend&username=testuser&password=password123')

echo "Raw token response:"
echo "$TOKEN_RESPONSE"

if echo "$TOKEN_RESPONSE" | grep -q "access_token"; then
  echo "✅ Token obtained successfully!"
  
  # Extract token (basic extraction)
  TOKEN=$(echo "$TOKEN_RESPONSE" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  echo "Token length: ${#TOKEN}"
  
  echo "🧪 Testing API endpoint..."
  API_RESPONSE=$(curl -s -X GET 'http://klb-api-gateway:8080/api/accounts' \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -w "HTTP_STATUS:%{http_code}")
  
  echo "API Response: $API_RESPONSE"
else
  echo "❌ Failed to get token"
fi
