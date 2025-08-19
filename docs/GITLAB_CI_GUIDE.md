# GitLab CI/CD Pipeline Guide - KLB Account Management

## 📋 Tổng quan
Pipeline GitLab CI/CD cho dự án KLB Account Management được thiết kế để:
- Tự động hóa quá trình build, test và deploy
- Đảm bảo chất lượng code thông qua kiểm tra tự động  
- Hỗ trợ deployment lên nhiều môi trường (staging, production)
- Kiểm tra bảo mật và performance

## 🏗️ Cấu trúc Pipeline

### Stages (Giai đoạn)
1. **Validate** - Kiểm tra cấu trúc code và dependencies
2. **Test** - Chạy unit tests và integration tests
3. **Build** - Build ứng dụng và tạo artifacts
4. **Security-scan** - Kiểm tra lỗ hổng bảo mật
5. **Package** - Tạo Docker images
6. **Deploy-staging** - Deploy lên môi trường staging  
7. **Deploy-production** - Deploy lên môi trường production

### Services được hỗ trợ
- **Backend Services**: api-gateway, common-api, customer-service, loan-service, main-app, notification-service
- **Frontend**: React application với TypeScript
- **Database**: PostgreSQL với migration support
- **Cache**: Redis support
- **Monitoring**: Prometheus metrics

## 🔧 Cấu hình Pipeline

### 1. Cấu hình GitLab Variables
Vào **Settings → CI/CD → Variables** và thêm các biến sau:

#### Registry & Docker
```
CI_REGISTRY_IMAGE: registry.gitlab.com/your-group/klb-account-management
```

#### Staging Environment
```
STAGING_SERVER: staging.klb.com
STAGING_USER: deploy  
STAGING_SSH_PRIVATE_KEY: [SSH private key - Masked]
```

#### Production Environment  
```
PRODUCTION_SERVER: prod.kienlongbank.com
PRODUCTION_USER: deploy
PRODUCTION_SSH_PRIVATE_KEY: [SSH private key - Masked & Protected]
```

#### Database
```
DATABASE_URL: jdbc:postgresql://localhost:5432/account_management
DATABASE_USER: kienlong
DATABASE_PASSWORD: [Secure password - Masked]
```

### 2. Chuẩn bị Server
#### Staging/Production Server Requirements:
```bash
# Docker & Docker Compose
sudo apt-get update
sudo apt-get install docker.io docker-compose

# Tạo user deploy
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy

# Tạo thư mục project
sudo mkdir -p /opt/klb-staging /opt/klb-production
sudo chown deploy:deploy /opt/klb-*

# Copy docker-compose.yml lên server
scp kienlongbank-project/docker-compose.yml deploy@staging.klb.com:/opt/klb-staging/
```

## 🚀 Workflow Triggers

### Automatic Triggers
- **Push to main**: Chạy full pipeline + có thể deploy production (manual)
- **Push to develop**: Chạy pipeline + có thể deploy staging (manual)  
- **Pull Request**: Chạy test và validation jobs
- **Tag creation**: Build và package Docker images

### Manual Triggers
- **Deploy Staging**: Manual deployment lên staging environment
- **Deploy Production**: Manual deployment lên production (chỉ từ main branch)
- **Performance Tests**: Chạy K6 performance testing
- **Database Migration**: Chạy Liquibase migration

## 📊 Artifacts & Reports

### Test Reports
- **JUnit Reports**: Unit test kết quả từ Maven Surefire
- **Coverage Reports**: JaCoCo coverage cho backend, Cobertura cho frontend
- **Integration Test Reports**: Failsafe integration test kết quả

### Security Reports
- **Dependency Scanning**: OWASP Dependency Check reports
- **Container Scanning**: Docker image vulnerability scanning
- **Frontend Security**: npm audit kết quả

### Build Artifacts
- **JAR Files**: Spring Boot executable JARs (1 hour retention)
- **Frontend Build**: React production build (1 hour retention)
- **Docker Images**: Pushed lên GitLab Container Registry

## 🔍 Monitoring & Debugging

### Pipeline Status
```bash
# Kiểm tra pipeline status qua API
curl --header "PRIVATE-TOKEN: your-token" \
  "https://gitlab.com/api/v4/projects/PROJECT_ID/pipelines"
```

### Logs Access
- **GitLab UI**: Project → CI/CD → Pipelines → Job logs
- **Container logs**: `docker logs container-name` trên server
- **Application logs**: Kiểm tra trong mounted volumes

### Health Checks
Pipeline tự động kiểm tra:
```bash
# Application health
curl http://localhost:8080/actuator/health

# Service-specific health  
curl http://localhost:8080/customer-service/actuator/health
curl http://localhost:8080/loan-service/actuator/health
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Maven Build Failures
```yaml
# Thêm debug option
variables:
  MAVEN_CLI_OPTS: "--batch-mode --errors --fail-at-end --show-version --debug"
```

#### 2. Docker Build Issues
```bash
# Kiểm tra Docker daemon
docker info

# Kiểm tra registry authentication
echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY
```

#### 3. SSH Connection Issues
```bash
# Test SSH connection
ssh -T deploy@staging.klb.com

# Kiểm tra SSH key format
cat ~/.ssh/id_rsa | head -1
# Should start with -----BEGIN OPENSSH PRIVATE KEY-----
```

#### 4. Database Connection Issues
```yaml
# Test database connection in pipeline
script:
  - apt-get install -y postgresql-client
  - pg_isready -h postgres-db -p 5432 -U kienlong
```

### Performance Optimization

#### 1. Cache Configuration
```yaml
# Tối ưu cache cho faster builds
cache:
  key: 
    files:
      - "**/*.xml"
      - "**/package-lock.json"
  policy: pull-push
```

#### 2. Parallel Jobs
```yaml
# Chạy jobs song song khi có thể
test:backend-parallel:
  parallel: 3
  script:
    - mvn test -Dtest=**/Test${CI_NODE_INDEX}*
```

## 📚 Best Practices

### 1. Security
- ✅ Sử dụng **Masked variables** cho sensitive data
- ✅ Sử dụng **Protected variables** cho production
- ✅ Chạy security scanning thường xuyên
- ✅ Cập nhật dependencies định kỳ

### 2. Performance  
- ✅ Sử dụng caching hiệu quả
- ✅ Chạy tests parallel khi có thể
- ✅ Tối ưu Docker layer caching
- ✅ Cleanup artifacts thường xuyên

### 3. Reliability
- ✅ Thêm proper health checks
- ✅ Sử dụng rolling deployments
- ✅ Backup database trước khi deploy
- ✅ Monitor pipeline metrics

### 4. Development Workflow
- ✅ Feature branches trigger validation only
- ✅ Develop branch triggers full pipeline + staging deploy
- ✅ Main branch requires manual approval cho production
- ✅ Use semantic versioning cho tags

## 🎯 Next Steps

1. **Setup GitLab Runner** trên infrastructure của bạn
2. **Configure Variables** theo hướng dẫn trên  
3. **Test Pipeline** với feature branch đầu tiên
4. **Setup Monitoring** với Prometheus/Grafana
5. **Configure Notifications** Slack/Teams integration
6. **Setup Scheduled Pipelines** cho maintenance tasks

## 📞 Support

Nếu gặp vấn đề với pipeline:
1. Kiểm tra job logs trong GitLab UI
2. Verify server connectivity và permissions
3. Test manual commands trên server trước
4. Contact DevOps team với error details

---

*Pipeline được thiết kế để support high-availability deployment với minimal downtime cho KLB banking system.*
