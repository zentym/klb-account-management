#!/bin/bash

echo "🐳 Starting PostgreSQL databases for microservices..."

# Start the docker containers
echo "Starting main account management database (port 5432)..."
echo "Starting customer service database (port 5433)..."

docker-compose up -d postgres-db postgres-customer-db

echo "⏳ Waiting for databases to be ready..."
sleep 10

echo "📊 Checking database status..."
docker ps | grep postgres

echo "✅ Database setup complete!"
echo ""
echo "🔗 Connection details:"
echo "   Main Service DB: localhost:5432/account_management"
echo "   Customer Service DB: localhost:5433/customer_service_db"
echo "   Username: kienlong"
echo "   Password: notStrongPassword"
echo ""
echo "🚀 You can now start your services:"
echo "   1. Main service (port 8080): cd klb-account-management && mvn spring-boot:run"
echo "   2. Customer service (port 8082): cd customer-service/customer-service && mvn spring-boot:run"
