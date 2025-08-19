# KLB Account Management System

A comprehensive microservices-based banking system with Spring Boot backend services, React TypeScript frontend, and Keycloak authentication.

## 🏗️ Architecture Overview

```
klb-account-management/
├── 📁 kienlongbank-project/    # Core microservices (THIS FOLDER)
│   ├── docker-compose.yml      # Main orchestration
│   ├── api-gateway/            # API Gateway service
│   ├── main-app/               # Account Management Service
│   ├── customer-service/       # Customer Service
│   ├── loan-service/           # Loan Service
│   ├── notification-service/   # Notification Service
│   ├── common-api/             # Shared API components
│   ├── prometheus/             # Monitoring
│   └── wiremock/               # Mock external services
├── 📁 klb-frontend/            # React TypeScript frontend
├── 📁 scripts/                 # Organized automation scripts
│   ├── setup/                  # System setup scripts
│   ├── test/                   # Testing scripts
│   ├── debug/                  # Debugging tools
│   └── utilities/              # Management utilities
├── 📁 docs/                    # Documentation
├── 📁 config/                  # Configuration files
└── 📁 demos/                   # Demo applications
```

**Core Services:**
- **🌐 API Gateway**: Centralized routing and authentication (Port 8090)
- **🏦 Account Management**: Spring Boot 3.5.4 (Port 8080)
- **👥 Customer Service**: Spring Boot 3.5.4 (Port 8082)
- **💰 Loan Service**: Spring Boot 3.5.4 (Port 8083)
- **📧 Notification Service**: Spring Boot 3.5.4 (Port 8084)
- **🔧 Common API**: Shared components and utilities
- **🎨 Frontend**: React 19.1.1 + TypeScript (Port 3000)
- **🗄️ Database**: PostgreSQL 15 (Multiple instances)
- **🎭 WireMock**: Mock external services (Port 8081)
- **📊 Prometheus**: Monitoring and metrics (Port 9090)
- **🔐 Keycloak**: Authentication server (Port 8180)

## 🚀 Quick Start

### Prerequisites
- ☕ Java 17+
- 📦 Node.js 18+
- 🐳 Docker & Docker Compose
- 🔐 Keycloak knowledge (basic)

### 🎯 Option 1: Automated Setup (Recommended)
Use the organized scripts from the project root:

```powershell
# Navigate to project root
cd ../

# 1. Setup Keycloak and all services
.\scripts\setup\setup-keycloak.ps1

# 2. Create admin user and test data
.\scripts\setup\create-admin-user.ps1
.\scripts\setup\setup-customer-data.ps1

# 3. Start all services
cd kienlongbank-project
docker-compose up -d

# 4. Run comprehensive tests
cd ../
.\scripts\test\ultimate-test-my-info.ps1
```

### 🎯 Option 2: Manual Setup

#### 1. Start Core Infrastructure
```bash
cd kienlongbank-project
docker-compose up -d
```

This will start:
- 🗄️ PostgreSQL databases (multiple instances)
- 🌐 API Gateway on port 8090
- 🏦 Account Management Service on port 8080
- 👥 Customer Service on port 8082
- 💰 Loan Service on port 8083
- 📧 Notification Service on port 8084
- 🎭 WireMock on port 8081
- 📊 Prometheus monitoring on port 9090

#### 2. Setup Keycloak Authentication
```powershell
cd ../
.\scripts\setup\setup-keycloak.ps1
```

#### 3. Start Frontend
```bash
cd ../klb-frontend
npm install
npm run start:safe
```

Frontend will be available at: `http://localhost:3000`

#### 4. Verify Installation
```powershell
# Quick health check
cd ../
.\scripts\test\test-auth-flow.ps1

# Comprehensive system check
.\scripts\debug\verify-keycloak.ps1
```

### 🎯 Useful Scripts

The project now includes organized scripts in `../scripts/` directory:

```powershell
# Setup scripts
.\scripts\setup\setup-keycloak.ps1           # Setup Keycloak server
.\scripts\setup\create-admin-user.ps1        # Create admin user
.\scripts\setup\setup-customer-data.ps1      # Setup test data

# Testing scripts  
.\scripts\test\test-auth-flow.ps1            # Test authentication
.\scripts\test\test-api-gateway-user-info.ps1 # Test API Gateway
.\scripts\test\ultimate-test-my-info.ps1     # Comprehensive test

# Debug scripts
.\scripts\debug\debug-jwt-token.ps1          # Debug JWT issues
.\scripts\debug\verify-keycloak.ps1          # Verify Keycloak setup

# Utility scripts
.\scripts\utilities\start-react-dev.ps1      # Start React development
.\scripts\utilities\monitor-build.ps1        # Monitor build process
.\scripts\utilities\cleanup-all.ps1          # Clean up system
```

### ⚡ Health Check
```bash
# API Gateway
curl http://localhost:8090/health

# Account Management Service
curl http://localhost:8080/api/health

# Customer Service
curl http://localhost:8082/api/health

# Loan Service
curl http://localhost:8083/api/health

# Notification Service
curl http://localhost:8084/api/health

# Keycloak (if running)
curl http://localhost:8180/auth/realms/klb/.well-known/openid_configuration
```

## 📋 API Endpoints

### 🌐 API Gateway (Port 8090)
All requests should go through the API Gateway for proper authentication and routing:

| Method | Endpoint | Description | Target Service |
|--------|----------|-------------|----------------|
| POST | `/auth/login` | User login via Keycloak | Account Management |
| GET | `/auth/user-info` | Get current user info | Account Management |
| GET | `/api/accounts/**` | Account operations | Account Management |
| GET | `/api/customers/**` | Customer operations | Customer Service |
| GET | `/api/loans/**` | Loan operations | Loan Service |
| POST | `/api/notifications/**` | Notifications | Notification Service |

### 🏦 Account Management Service (Port 8080)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | User login |
| GET | `/api/auth/user-info` | Get user information |
| GET | `/api/accounts` | Get user accounts |
| POST | `/api/accounts` | Create new account |
| GET | `/api/transactions` | Get transactions |
| POST | `/api/transactions` | Create transaction |
| GET | `/api/my-info` | Get detailed user info |

### 👥 Customer Service (Port 8082)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/customers` | Get all customers |
| POST | `/api/customers` | Create customer |
| GET | `/api/customers/{id}` | Get customer by ID |
| PUT | `/api/customers/{id}` | Update customer |
| DELETE | `/api/customers/{id}` | Delete customer |
| POST | `/api/customers/mapping` | Create customer mapping |

### 💰 Loan Service (Port 8083)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/loans` | Get all loans |
| POST | `/api/loans` | Create loan application |
| GET | `/api/loans/{id}` | Get loan by ID |
| PUT | `/api/loans/{id}/status` | Update loan status |
| GET | `/api/loans/my-loans` | Get current user's loans |

### 📧 Notification Service (Port 8084)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| POST | `/api/notifications` | Send notification |
| GET | `/api/notifications/{userId}` | Get user notifications |
| PUT | `/api/notifications/{id}/read` | Mark as read |

## 📚 API Documentation

**Swagger UI:**
- 🌐 API Gateway: `http://localhost:8090/swagger-ui/index.html`
- 🏦 Account Management: `http://localhost:8080/swagger-ui/index.html`
- 👥 Customer Service: `http://localhost:8082/swagger-ui/index.html`
- 💰 Loan Service: `http://localhost:8083/swagger-ui/index.html`
- 📧 Notification Service: `http://localhost:8084/swagger-ui/index.html`

**Authentication:**
- 🔐 Keycloak Admin Console: `http://localhost:8180/auth/admin/`
- 🔑 Keycloak User Account: `http://localhost:8180/auth/realms/klb/account/`

**Monitoring:**
- 📊 Prometheus: `http://localhost:9090`
- 📈 Application Metrics: `http://localhost:8080/actuator/prometheus`

## 🛠️ Development

### 🏃‍♂️ Running Individual Services

**API Gateway:**
```bash
cd api-gateway
./mvnw spring-boot:run
```

**Account Management:**
```bash
cd main-app
./mvnw spring-boot:run
```

**Customer Service:**
```bash
cd customer-service
./mvnw spring-boot:run
```

**Loan Service:**
```bash
cd loan-service
./mvnw spring-boot:run
```

**Notification Service:**
```bash
cd notification-service
./mvnw spring-boot:run
```

### 🗄️ Database Configuration

**Account Management DB:**
- Host: `localhost:5432`
- Database: `account_management`
- Username: `kienlong`
- Password: `notStrongPassword`

**Customer Service DB:**
- Host: `localhost:5433`
- Database: `customer_service_db`
- Username: `kienlong`
- Password: `notStrongPassword`

**Loan Service DB:**
- Host: `localhost:5434`
- Database: `loan_service_db`
- Username: `kienlong`
- Password: `notStrongPassword`

### 🔐 Keycloak Configuration
- **Admin Console**: `http://localhost:8180/auth/admin/`
- **Admin User**: `admin`
- **Admin Password**: `admin`
- **Realm**: `klb`
- **Client ID**: `klb-frontend`

## 🧪 Testing

### 🤖 Automated Testing (Recommended)
Use the organized test scripts:

```powershell
cd ../

# Basic authentication test
.\scripts\test\test-auth-flow.ps1

# API Gateway tests
.\scripts\test\test-api-gateway-user-info.ps1

# My Info API comprehensive test
.\scripts\test\ultimate-test-my-info.ps1

# JWT token testing
.\scripts\test\test-my-info-with-jwt.ps1

# Database integration test
.\scripts\test\test-my-info-with-database.ps1

# Performance testing
node scripts\test\performance-test.js
```

### 📬 Using Postman
Import collection: `../config/api-test-config.json`

### 🔧 Manual Testing with PowerShell
```powershell
# Navigate to project root
cd ../

# Test individual components
.\scripts\test\test-account-api.ps1
.\scripts\test\test-admin-user.ps1
.\scripts\test\test-direct-grant.ps1

# Quick API tests
.\scripts\utilities\quick-api-test.ps1
.\scripts\utilities\quick-test-customer.ps1
```

### 🧪 Testing Workflow
1. **Setup**: Run setup scripts first
2. **Unit Tests**: Test individual services
3. **Integration Tests**: Test service communication
4. **End-to-End Tests**: Test complete user workflows
5. **Performance Tests**: Load and stress testing

## 🐳 Docker Operations

### 🚀 Start all services
```bash
docker-compose up -d
```

### 🛑 Stop all services
```bash
docker-compose down
```

### 📋 View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f [service-name]
# Examples: api-gateway, main-app, customer-service, loan-service
```

### 🔄 Rebuild services
```bash
# Rebuild all
docker-compose up --build

# Rebuild specific service
docker-compose up --build [service-name]
```

### 🧹 Clean up
```bash
# Remove containers and networks
docker-compose down --remove-orphans

# Remove containers, networks, and volumes
docker-compose down -v

# Remove everything including images
docker-compose down --rmi all -v
```

### 📊 Monitor services
```bash
# Check service status
docker-compose ps

# Check resource usage
docker stats

# Inspect specific service
docker-compose exec [service-name] /bin/bash
```

## 🔧 Configuration

### 🌍 Environment Variables
- `SPRING_DATASOURCE_URL`: Database connection URL
- `SPRING_DATASOURCE_USERNAME`: Database username  
- `SPRING_DATASOURCE_PASSWORD`: Database password
- `CUSTOMER_SERVICE_URL`: Customer service endpoint
- `LOAN_SERVICE_URL`: Loan service endpoint
- `NOTIFICATION_SERVICE_URL`: Notification service endpoint
- `KEYCLOAK_SERVER_URL`: Keycloak server URL
- `KEYCLOAK_REALM`: Keycloak realm name
- `JWT_SECRET_KEY`: JWT signing secret

### 🔐 Keycloak Settings
- **Realm**: `klb`
- **Client ID**: `klb-frontend`
- **Client Secret**: Auto-generated
- **Valid Redirect URIs**: `http://localhost:3000/*`
- **Web Origins**: `http://localhost:3000`

### 🎭 WireMock Configuration
Mock responses are configured in `wiremock/mappings/` directory:
- External API mocks
- Third-party service simulations
- Test data responses

### 📊 Prometheus Configuration
Monitoring configuration in `prometheus/prometheus.yml`:
- Service discovery
- Metrics collection intervals
- Alert rules

## 🐛 Troubleshooting

### 🔍 Common Issues

**Port conflicts:**
```bash
# Check port usage
netstat -an | findstr "8080\|8082\|8083\|8084\|8090\|5432\|5433\|5434\|8180"

# Stop all services
docker-compose down
```

**Database connection issues:**
```bash
# Check database status
docker-compose ps
docker logs klb-postgres
docker logs klb-postgres-customer
docker logs klb-postgres-loan

# Reset databases
docker-compose down -v
docker-compose up -d
```

**Keycloak authentication issues:**
```powershell
# Use debug scripts
cd ../
.\scripts\debug\debug-jwt-token.ps1
.\scripts\debug\verify-keycloak.ps1

# Check Keycloak logs
docker-compose logs keycloak
```

**Service communication issues:**
- Verify all services are running: `docker-compose ps`
- Check service logs: `docker-compose logs [service-name]`
- Ensure proper network configuration in docker-compose.yml
- Test API Gateway routing: `curl http://localhost:8090/health`

**Frontend connection issues:**
```powershell
# Debug frontend setup
cd ../
.\scripts\debug\debug-api-gateway.ps1

# Restart with clean setup
.\scripts\utilities\restart-react-with-proxy.ps1
```

### 🔧 Debug Tools
Use the organized debug scripts:
```powershell
cd ../

# JWT token issues
.\scripts\debug\debug-jwt-token.ps1
.\scripts\debug\debug-jwt-config.ps1

# System verification
.\scripts\debug\verify-keycloak.ps1

# API Gateway debugging
.\scripts\debug\debug-api-gateway.ps1
```

### 📋 Health Check Commands
```bash
# Quick health check all services
curl http://localhost:8090/health && \
curl http://localhost:8080/api/health && \
curl http://localhost:8082/api/health && \
curl http://localhost:8083/api/health && \
curl http://localhost:8084/api/health

# Keycloak health
curl http://localhost:8180/auth/realms/klb/.well-known/openid_configuration
```

## 📁 Project Structure

### 🏗️ Core Microservices (Current Directory)
```
kienlongbank-project/
├── 🌐 api-gateway/              # Central API routing
├── 🏦 main-app/                 # Account management core
├── 👥 customer-service/         # Customer data management  
├── 💰 loan-service/             # Loan processing
├── 📧 notification-service/     # Messaging system
├── 🔧 common-api/               # Shared components
├── 📊 prometheus/               # Monitoring setup
├── 🎭 wiremock/                 # Mock services
└── 🐳 docker-compose.yml        # Container orchestration
```

### 📂 Related Directories
- `../klb-frontend/` - React TypeScript frontend with Keycloak integration
- `../scripts/` - Organized automation and testing scripts
  - `setup/` - System initialization scripts
  - `test/` - Comprehensive testing suite
  - `debug/` - Debugging and troubleshooting tools
  - `utilities/` - Daily operation scripts
- `../docs/` - Complete project documentation
- `../config/` - Configuration files and API collections
- `../demos/` - Demo applications and examples

### 📚 Documentation Links
- 📖 [Complete Project README](../README.md)
- 📋 [Scripts Index](../docs/SCRIPTS_INDEX.md)
- 🔐 [Custom Login Integration](../docs/CUSTOM_LOGIN_INTEGRATION_GUIDE.md)
- 📱 [Phone Login Guide](../docs/PHONE_LOGIN_GUIDE.md)
- 🔒 [JWT Caching Implementation](../docs/JWT_CACHING_IMPLEMENTATION.md)
- 🚀 [GitLab CI Guide](../docs/GITLAB_CI_GUIDE.md)

## � Getting Started Workflow

### 🎯 For New Developers
1. **Clone and Setup:**
   ```bash
   git clone [repository-url]
   cd klb-account-management
   ```

2. **Quick Start:**
   ```powershell
   # Automated setup (recommended)
   .\scripts\setup\setup-keycloak.ps1
   .\scripts\setup\create-admin-user.ps1
   
   # Start services
   cd kienlongbank-project
   docker-compose up -d
   
   # Verify installation
   cd ../
   .\scripts\test\ultimate-test-my-info.ps1
   ```

3. **Start Development:**
   ```powershell
   # Start frontend
   .\scripts\utilities\start-react-dev.ps1
   
   # Monitor system
   .\scripts\utilities\monitor-build.ps1
   ```

### 🔧 For DevOps/System Admin
- Use scripts in `../scripts/setup/` for environment setup
- Monitor with Prometheus: `http://localhost:9090`
- Check health endpoints regularly
- Use `../scripts/utilities/cleanup-all.ps1` for maintenance

### 🧪 For QA/Testing
- Complete test suite available in `../scripts/test/`
- API documentation at respective Swagger UI endpoints
- Performance testing with `node ../scripts/test/performance-test.js`

## 🏆 Features

- ✅ **Microservices Architecture** with Spring Boot
- ✅ **API Gateway** with centralized routing
- ✅ **Keycloak Authentication** with JWT tokens
- ✅ **React Frontend** with TypeScript
- ✅ **PostgreSQL** multi-database setup
- ✅ **Docker Compose** orchestration
- ✅ **Prometheus Monitoring** integration
- ✅ **Automated Testing** suite
- ✅ **Organized Scripts** for all operations
- ✅ **Comprehensive Documentation**

## �📝 License

This project is for educational purposes and internal use at Kien Long Bank.

---

**📞 Support:** For issues, check the troubleshooting section or use debug scripts in `../scripts/debug/`

**📚 Documentation:** Complete guides available in `../docs/`

**🚀 Quick Help:** Run `.\scripts\utilities\quick-api-test.ps1` for immediate system check
