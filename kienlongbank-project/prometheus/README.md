# 📊 Prometheus Monitoring Setup

## 🎯 Tổng Quan
File này cấu hình Prometheus để monitor tất cả microservices trong hệ thống Kienlongbank.

## 🔧 Cấu Hình

### Services được Monitor:
- **account-management:8080** - Main App (Account Management)
- **customer-service:8082** - Customer Service
- **loan-service:8083** - Loan Service  
- **notification-service:8084** - Notification Service
- **prometheus:9090** - Prometheus itself

### Metrics Endpoints:
Tất cả services expose metrics tại: `http://service:port/actuator/prometheus`

## 🚀 Cách Sử Dụng

### 1. Start Docker Compose
```bash
cd kienlongbank-project
docker-compose up -d
```

### 2. Truy cập Prometheus UI
```
http://localhost:9090
```

### 3. Truy cập Grafana Dashboard  
```
http://localhost:3000
```
- Username: `admin`
- Password: `admin` (default)

## 📈 Các Metrics Quan Trọng

### Application Metrics:
- `http_server_requests_seconds` - HTTP request duration
- `http_server_requests_seconds_count` - HTTP request count
- `jvm_memory_used_bytes` - JVM memory usage
- `jvm_gc_pause_seconds` - Garbage collection time

### Circuit Breaker Metrics (Account Management):
- `resilience4j_circuitbreaker_calls_total` - Total circuit breaker calls
- `resilience4j_circuitbreaker_failure_rate` - Failure rate
- `resilience4j_circuitbreaker_state` - Circuit breaker state (CLOSED/OPEN/HALF_OPEN)

### Database Metrics:
- `hikari_connections_active` - Active database connections
- `hikari_connections_pending` - Pending connections

### RabbitMQ Metrics (Notification Service):
- `rabbitmq_consumed_total` - Messages consumed
- `rabbitmq_published_total` - Messages published

## 🔍 Sample Queries

### 1. HTTP Request Rate
```promql
rate(http_server_requests_seconds_count[5m])
```

### 2. Circuit Breaker State
```promql
resilience4j_circuitbreaker_state{name="customerService"}
```

### 3. Memory Usage by Service
```promql
jvm_memory_used_bytes{area="heap"}
```

### 4. 95th Percentile Response Time
```promql
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))
```

## 📊 Dashboard Setup

### Import Pre-built Dashboards:
1. **Spring Boot Dashboard**: ID `6756`
2. **JVM Dashboard**: ID `4701`
3. **Micrometer Dashboard**: ID `4701`

### Custom Dashboard URLs:
- Spring Boot Metrics: http://localhost:3000/d/spring-boot
- Circuit Breaker Monitoring: http://localhost:3000/d/circuit-breaker

## 🛠️ Troubleshooting

### Service Not Appearing in Targets:
1. Check if service is running: `docker ps`
2. Verify actuator endpoint: `curl http://localhost:8082/actuator/prometheus`
3. Check docker network: `docker network ls`

### No Metrics Data:
1. Verify dependencies in `pom.xml`:
   - `spring-boot-starter-actuator`
   - `micrometer-registry-prometheus`
2. Check application.properties:
   - `management.endpoints.web.exposure.include=prometheus`

### Connection Issues:
1. Ensure all services are in same Docker network
2. Check service names match container names in docker-compose.yml
3. Verify ports are correctly mapped

## 📝 Configuration Files

### Modified Files:
- `prometheus/prometheus.yml` - Main Prometheus configuration
- `customer-service/pom.xml` - Added actuator + micrometer dependencies
- `loan-service/pom.xml` - Added actuator + micrometer dependencies  
- `notification-service/pom.xml` - Added actuator + micrometer dependencies
- `customer-service/application.properties` - Exposed prometheus endpoint
- `loan-service/application.properties` - Exposed prometheus endpoint
- `notification-service/application.properties` - Exposed prometheus endpoint

### Endpoints Available:
- Health: `/actuator/health`
- Metrics: `/actuator/metrics`
- Prometheus: `/actuator/prometheus`
- Info: `/actuator/info`

---

## 🎉 Ready for Production Monitoring!

Hệ thống monitoring đã được setup hoàn chỉnh với:
- ✅ Prometheus metrics collection
- ✅ Grafana visualization  
- ✅ Circuit breaker monitoring
- ✅ Application health checks
- ✅ Custom dashboards support
