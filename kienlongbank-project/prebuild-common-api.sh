#!/bin/bash
# Pre-build script for common-api to avoid rebuilding every time

echo "🚀 Pre-building common-api module..."

cd common-api
mvn clean install -DskipTests -q

echo "✅ Common-api build completed!"
echo "📦 Artifact installed to local Maven repository"
echo ""
echo "💡 Now you can build other services faster:"
echo "   docker-compose build loan-service"
