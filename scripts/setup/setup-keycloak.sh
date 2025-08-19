#!/bin/bash

echo "🔧 Configuring Keycloak for KLB Frontend..."

# Wait for Keycloak to be ready
echo "⏳ Waiting for Keycloak to start..."
until curl -s http://localhost:8090/realms/master/.well-known/openid-configuration > /dev/null; do
    sleep 2
done

echo "✅ Keycloak is ready!"

# Get admin token
echo "🔑 Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8090/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ Failed to get admin token"
    exit 1
fi

echo "✅ Got admin token"

# Create Kienlongbank realm
echo "🏗️ Creating Kienlongbank realm..."
curl -s -X POST http://localhost:8090/admin/realms \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "Kienlongbank",
    "enabled": true,
    "displayName": "Kien Long Bank",
    "accessCodeLifespan": 300,
    "accessTokenLifespan": 3600,
    "refreshTokenMaxReuse": 0,
    "ssoSessionIdleTimeout": 1800,
    "ssoSessionMaxLifespan": 36000
  }'

echo "✅ Realm created"

# Create klb-frontend client
echo "🔧 Creating klb-frontend client..."
curl -s -X POST http://localhost:8090/admin/realms/Kienlongbank/clients \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "klb-frontend",
    "name": "KLB Frontend Application",
    "enabled": true,
    "publicClient": true,
    "directAccessGrantsEnabled": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "serviceAccountsEnabled": false,
    "redirectUris": ["http://localhost:3000/*"],
    "webOrigins": ["http://localhost:3000"],
    "protocol": "openid-connect"
  }'

echo "✅ Client created"

# Create test user
echo "👤 Creating test user..."
curl -s -X POST http://localhost:8090/admin/realms/Kienlongbank/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@kienlongbank.com",
    "firstName": "Test",
    "lastName": "User",
    "enabled": true,
    "credentials": [{
      "type": "password",
      "value": "password123",
      "temporary": false
    }]
  }'

echo "✅ Test user created"
echo ""
echo "🎉 Keycloak configuration complete!"
echo ""
echo "📋 Configuration Summary:"
echo "   Realm: Kienlongbank"
echo "   Client ID: klb-frontend"
echo "   Test User: testuser / password123"
echo "   Keycloak URL: http://localhost:8090"
echo ""
echo "🚀 You can now start the frontend and test login!"
