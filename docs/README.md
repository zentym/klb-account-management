# KLB Banking System

A modern microservices-based banking system with Spring Boot and React.

## 📁 Project Structure

```
klb-account-management/
├── kienlongbank-project/        # 🆕 Main Project (Recommended)
│   ├── docker-compose.yml       # Orchestrates all services
│   ├── main-app/               # Account Management Service
│   ├── customer-service/       # Customer Service
│   ├── wiremock/               # Mock external services
│   └── README.md               # Detailed documentation
├── klb-frontend/               # React TypeScript Frontend
├── legacy-scripts/             # Legacy testing scripts & docs
└── package.json                # Root package configuration
```

## 🚀 Quick Start

### New Microservices Architecture (Recommended)
```bash
cd kienlongbank-project
docker-compose down  # Clean up any existing containers
docker-compose up -d

# Configure Keycloak with customer data (run once)
cd ..
powershell -ExecutionPolicy Bypass -File setup-keycloak-phone.ps1

# Debug API Gateway connections (recommended)
powershell -ExecutionPolicy Bypass -File debug-api-gateway.ps1

# Setup customer data through API Gateway (if Gateway is working)
powershell -ExecutionPolicy Bypass -File setup-customer-data-via-gateway.ps1

# Or fallback to legacy method
powershell -ExecutionPolicy Bypass -File setup-customer-data.ps1
```

### Legacy Frontend
```bash
cd klb-frontend
npm install
npx react-scripts start
```

### 🔐 Authentication
- **Keycloak Admin**: http://localhost:8090 (admin/admin)
- **Test Users**:
  - **Admin**: 0901234567 / admin123
  - **User**: 0987654321 / password123
- **Realm**: Kienlongbank

### 👥 Customer Data Setup

**⚠️ Lưu ý**: Do API Gateway hiện tại có vấn đề với JWT validation, có một số cách để tạo customer data:

```bash
# 1. Debug và kiểm tra API Gateway (khuyến nghị chạy trước)
.\debug-api-gateway.ps1

# 2. Thử setup qua API Gateway (nếu Gateway đã được fix)
.\setup-customer-data-via-gateway.ps1

# 3. Tạo trực tiếp vào database (fallback method)
.\setup-customer-data.ps1 -DirectDB

# 4. Tạo thủ công với custom phone numbers
.\setup-customer-data-via-gateway.ps1 -AdminPhone "0901111111" -UserPhone "0902222222"

# 5. Skip authentication (for testing Gateway routing)
.\setup-customer-data-via-gateway.ps1 -SkipAuth
```

**Troubleshooting**: Nếu APIs trả về 401 Unauthorized, API Gateway có thể cần cấu hình lại JWT validation từ Keycloak realm.

## � API Testing Tools

### Quick API Testing
```bash
# Test nhanh tất cả APIs với user role
.\quick-api-test.ps1

# Test với admin role
.\quick-api-test.ps1 -AdminTest

# Test với output chi tiết
.\quick-api-test.ps1 -Verbose
```

### Advanced API Testing
```bash
# Test tất cả services
.\test-api-tool.ps1 -Service all

# Test service cụ thể
.\test-api-tool.ps1 -Service main
.\test-api-tool.ps1 -Service customer -Username admin -Password admin123

# Test endpoint cụ thể
.\test-api-tool.ps1 -Service main -Endpoint "/api/accounts" -Method GET
```

### Custom Endpoint Testing
```bash
# Test customer endpoint through API Gateway (recommended)
.\test-endpoint.ps1 -Url "http://localhost:8080/api/customers" -Method GET

# Create customer through API Gateway
.\test-endpoint.ps1 -Url "http://localhost:8080/api/customers" -Method POST -Data '{"firstName":"John","lastName":"Doe","email":"john@example.com","phoneNumber":"0912345678","address":"123 Main St"}'

# Test account endpoint through API Gateway
.\test-endpoint.ps1 -Url "http://localhost:8080/api/accounts" -Method GET

# Test public endpoint
.\test-endpoint.ps1 -Url "http://localhost:8080/actuator/health" -NoAuth

# Pretty JSON output
.\test-endpoint.ps1 -Url "http://localhost:8080/api/accounts" -Pretty
```

## �🧹 Cleanup Commands

### Quick Cleanup Scripts
```bash
# Menu dọn sạch với giao diện
.\cleanup-menu.bat

# Dọn sạch nhanh (containers + build artifacts)
.\quick-cleanup.ps1

# Dọn sạch đầy đủ (logs, temp files, IDE files)
.\cleanup-all.ps1 -Force

# Reset project hoàn toàn (XÓA TẤT CẢ!)
.\reset-project.ps1 -ConfirmAll

# Kiểm tra trạng thái project
.\check-status.ps1
```

### Manual Cleanup
```bash
# Docker cleanup
docker-compose -f kienlongbank-project/docker-compose.yml down --remove-orphans
docker system prune -af --volumes

# Maven cleanup
cd kienlongbank-project
mvn clean

# Frontend cleanup  
cd klb-frontend
Remove-Item node_modules, build -Recurse -Force
```

### Cleanup Options
- **`-Force`**: Không hỏi xác nhận
- **`-KeepDatabase`**: Giữ lại database volumes  
- **`-SkipDocker`**: Bỏ qua dọn sạch Docker
- **`-SkipBuild`**: Bỏ qua dọn sạch build artifacts
- **`-Verbose`**: Hiển thị thông tin chi tiết

## 📚 Documentation

- **Main Project**: See `kienlongbank-project/README.md` for complete setup and API documentation
- **Frontend**: See `klb-frontend/README.md` for React application details
- **Legacy Scripts**: Testing and utility scripts are in `legacy-scripts/`

## 🔧 Migration Guide

**From Legacy Structure:**
1. Use `kienlongbank-project/` for all new development
2. Legacy scripts are available in `legacy-scripts/` if needed
3. Frontend remains separate for now (future integration planned)

## 🛠️ Services Overview

| Service | Port | Description | Direct Access |
|---------|------|-------------|---------------|
| API Gateway | 8080 | **Main Entry Point** - Routes to all services | ✅ External |
| Account Management | - | User accounts, transactions, auth | 🔒 Internal only |
| Customer Service | - | Customer CRUD operations | 🔒 Internal only |
| Frontend | 3000 | React TypeScript UI | ✅ External |
| Keycloak | 8090 | Authentication & Authorization | ✅ External |
| PostgreSQL (Main) | 5432 | Account management database | ✅ External |
| PostgreSQL (Customer) | 5433 | Customer service database | ✅ External |
| WireMock | 8081 | Mock external services | ✅ External |

**⚠️ Important**: All API calls should go through API Gateway (port 8080). Backend services are not directly accessible from outside Docker network.

## 📝 License

This project is for educational purposes and internal use at Kien Long Bank.
