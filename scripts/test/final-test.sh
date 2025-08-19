#!/bin/bash
echo "🔑 Getting token from Keycloak..."
TOKEN_RESPONSE=$(curl -s -X POST "http://klb-keycloak:8080/realms/Kienlongbank/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=klb-frontend&username=testuser&password=password123")

TOKEN=$(echo "$TOKEN_RESPONSE" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to extract token"
    echo "Response: $TOKEN_RESPONSE"
    exit 1
fi

echo "✅ Token obtained (length: ${#TOKEN})"

echo ""
echo "🧪 Testing Account Management Service directly..."
RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" -X GET "http://klb-account-management:8080/api/accounts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "Response: $RESPONSE"

# Check for success
if echo "$RESPONSE" | grep -q "HTTP_STATUS:2"; then
    echo "✅ Success!"
elif echo "$RESPONSE" | grep -q "HTTP_STATUS:401"; then
    echo "❌ Unauthorized - JWT validation failed"
elif echo "$RESPONSE" | grep -q "HTTP_STATUS:403"; then
    echo "❌ Forbidden - Insufficient permissions"  
else
    echo "❌ Other error"
fi
