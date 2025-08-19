# 📊 Exception Logging Test Guide

## 🎯 Mục đích
File này hướng dẫn cách test và verify logging functionality của GlobalExceptionHandler.

## � **Vị trí logs được ghi:**

### 🎯 **Cấu hình hiện tại (theo logback-spring.xml):**

1. **Console Output** (Terminal/IDE):
   ```
   2025-08-13 13:45:23 [http-nio-8082-exec-1] WARN  c.e.customer_service.exception.GlobalExceptionHandler - Customer not found: Không tìm thấy khách hàng với ID: 999
   ```

2. **File Outputs** (tự động tạo khi application chạy):
   ```
   📂 customer-service/
   ├── logs/
   │   ├── application.log          # 📝 Tất cả logs chính
   │   ├── application.2025-08-12.log  # 🗓️ Archived logs (rolling daily)
   │   ├── hibernate.log            # 🗃️ Database/JPA logs
   │   ├── security.log             # 🔐 Spring Security logs
   │   └── ...
   ```

### 🔧 **Tạo thư mục logs trước khi chạy:**

```bash
# Windows PowerShell
mkdir logs

# Linux/Mac
mkdir -p logs
```

### 📊 **Log File Details:**

#### **application.log** - Main Application Log
- **Content**: Tất cả application logs, bao gồm exception handling
- **Size**: Rolling khi đạt size limit
- **Retention**: 30 ngày
- **Format**: `yyyy-MM-dd HH:mm:ss [thread] LEVEL logger - message`

#### **hibernate.log** - Database Operations
- **Content**: SQL queries, database connections, JPA operations  
- **Level**: DEBUG cho Hibernate components
- **Use case**: Debug database issues

#### **security.log** - Security Events
- **Content**: Authentication, authorization, JWT validation
- **Level**: DEBUG cho Spring Security
- **Use case**: Debug login/permission issues
```yaml
logging:
  level:
    com.example.customer_service.exception: DEBUG
    org.springframework.security: INFO
    org.springframework.web: INFO
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  file:
    name: logs/customer-service.log
```

### Logback Configuration (Optional)
```xml
<!-- src/main/resources/logback-spring.xml -->
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/customer-service.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>logs/customer-service.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <logger name="com.example.customer_service.exception" level="DEBUG"/>
    
    <root level="INFO">
        <appender-ref ref="STDOUT" />
        <appender-ref ref="FILE" />
    </root>
</configuration>
```

---

## 🧪 Test Cases với Expected Log Output

### 1. Business Logic Exception Test
```bash
# Test CustomerNotFoundException
curl -X GET http://localhost:8082/api/customers/999999
```

**Expected Log Output:**
```
2025-08-13 13:45:23 [http-nio-8082-exec-1] WARN  c.e.customer_service.exception.GlobalExceptionHandler - Customer not found: Không tìm thấy khách hàng với ID: 999999 - URI: uri=/api/customers/999999
```

### 2. Validation Exception Test
```bash
# Test validation errors
curl -X POST http://localhost:8082/api/customers \
  -H "Content-Type: application/json" \
  -d '{"fullName":"","email":"invalid","phone":"123"}'
```

**Expected Log Output:**
```
2025-08-13 13:45:24 [http-nio-8082-exec-2] WARN  c.e.customer_service.exception.GlobalExceptionHandler - Validation failed for request: uri=/api/customers - Errors: {fullName=Họ tên không được để trống, email=Email không đúng định dạng, phone=Số điện thoại không đúng định dạng (VD: 0901234567 hoặc +84901234567)} - URI: uri=/api/customers
```

### 3. HTTP Exception Test
```bash
# Test unsupported media type
curl -X POST http://localhost:8082/api/customers \
  -H "Content-Type: text/plain" \
  -d "invalid data"
```

**Expected Log Output:**
```
2025-08-13 13:45:25 [http-nio-8082-exec-3] WARN  c.e.customer_service.exception.GlobalExceptionHandler - Unsupported media type: text/plain - Supported: [application/json] - URI: uri=/api/customers
```

### 4. Security Exception Test
```bash
# Test authentication failure
curl -X GET http://localhost:8082/api/customers \
  -H "Authorization: Bearer invalid-token"
```

**Expected Log Output:**
```
2025-08-13 13:45:26 [http-nio-8082-exec-4] WARN  c.e.customer_service.exception.GlobalExceptionHandler - Authentication failed: JWT token validation failed - URI: uri=/api/customers
```

### 5. Type Conversion Exception Test
```bash
# Test type mismatch
curl -X GET http://localhost:8082/api/customers/invalid-id
```

**Expected Log Output:**
```
2025-08-13 13:45:27 [http-nio-8082-exec-5] WARN  c.e.customer_service.exception.GlobalExceptionHandler - Type mismatch for parameter 'id': expected Long but received 'invalid-id' - URI: uri=/api/customers/invalid-id
```

### 6. Database Exception Test
```bash
# Test unique constraint violation (tạo customer với email trùng)
curl -X POST http://localhost:8082/api/customers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <VALID_TOKEN>" \
  -d '{"fullName":"Test User","email":"existing@example.com","phone":"0901234567"}'
```

**Expected Log Output:**
```
2025-08-13 13:45:28 [http-nio-8082-exec-6] ERROR c.e.customer_service.exception.GlobalExceptionHandler - Database error: Dữ liệu đã tồn tại. Email có thể đã được sử dụng - SQLState: 23505 - URI: uri=/api/customers
```

---

## 🔍 Log Analysis Commands

### Tail logs trong realtime
```bash
# Windows PowerShell - Follow log file  
Get-Content "logs/application.log" -Wait -Tail 50

# Filter exceptions only
Get-Content "logs/application.log" -Wait | Select-String "GlobalExceptionHandler"

# Linux/Mac - Follow log file
tail -f logs/application.log

# Filter exceptions only  
tail -f logs/application.log | grep "GlobalExceptionHandler"
```

### Search specific exception types
```bash
# Windows PowerShell
Select-String -Path "logs/application.log" -Pattern "Customer not found"
Select-String -Path "logs/application.log" -Pattern "Authentication failed"  
Select-String -Path "logs/application.log" -Pattern "Database error"

# Linux/Mac  
grep "Customer not found" logs/application.log
grep "Authentication failed" logs/application.log
grep "Database error" logs/application.log
```

---

## 📊 Log Monitoring Setup

### ELK Stack Integration (Optional)
```yaml
# docker-compose.yml addition for ELK
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.14.0
    environment:
      - discovery.type=single-node
    ports:
      - "9200:9200"
      
  logstash:
    image: docker.elastic.co/logstash/logstash:7.14.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
      - ./logs:/logs
    ports:
      - "5044:5044"
      
  kibana:
    image: docker.elastic.co/kibana/kibana:7.14.0
    ports:
      - "5601:5601"
```

### Logstash Configuration
```ruby
# logstash.conf
input {
  file {
    path => "/logs/customer-service.log"
    start_position => "beginning"
  }
}

filter {
  grok {
    match => { 
      "message" => "%{TIMESTAMP_ISO8601:timestamp} \[%{DATA:thread}\] %{LOGLEVEL:level} %{DATA:logger} - %{GREEDYDATA:log_message}" 
    }
  }
  
  if [logger] == "c.e.customer_service.exception.GlobalExceptionHandler" {
    mutate { add_tag => ["exception"] }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "customer-service-logs-%{+YYYY.MM.dd}"
  }
}
```

---

## 🚨 Alerting Setup

### Simple Log-based Alerts
```bash
#!/bin/bash
# alert-on-errors.sh

LOGFILE="logs/customer-service.log"
ERROR_COUNT=$(grep -c "ERROR" "$LOGFILE" | tail -1)

if [ "$ERROR_COUNT" -gt 10 ]; then
    echo "Alert: More than 10 errors detected in customer-service"
    # Send notification (email, Slack, etc.)
fi
```

### Application Metrics (Micrometer)
```java
// Add to GlobalExceptionHandler
@Autowired
private MeterRegistry meterRegistry;

// In each exception handler
Counter.builder("exception.count")
    .tag("type", "customer_not_found")
    .tag("status", "404")
    .register(meterRegistry)
    .increment();
```

---

## 🔧 Development Tips

### Enable Debug Logging
```yaml
# application-dev.yml
logging:
  level:
    com.example.customer_service: DEBUG
    org.springframework.security: DEBUG
    org.springframework.web: DEBUG
```

### Test Logging in Unit Tests
```java
@Test
void testExceptionLogging() {
    // Setup log capture
    ch.qos.logback.classic.Logger logger = 
        (ch.qos.logback.classic.Logger) LoggerFactory.getLogger(GlobalExceptionHandler.class);
    
    TestAppender testAppender = new TestAppender();
    logger.addAppender(testAppender);
    
    // Trigger exception
    CustomerNotFoundException ex = new CustomerNotFoundException("Test message");
    globalExceptionHandler.handleCustomerNotFoundException(ex, mockRequest);
    
    // Verify log
    List<ILoggingEvent> logEvents = testAppender.events;
    assertEquals(1, logEvents.size());
    assertEquals(Level.WARN, logEvents.get(0).getLevel());
    assertTrue(logEvents.get(0).getMessage().contains("Customer not found"));
}
```

### Performance Monitoring
```java
// Add timing logs for performance analysis
@ExceptionHandler(Exception.class)
public ResponseEntity<ApiResponse<Object>> handleGenericException(Exception ex, WebRequest request) {
    long startTime = System.currentTimeMillis();
    
    // Exception handling logic...
    
    long duration = System.currentTimeMillis() - startTime;
    log.error("Exception processing took {}ms - URI: {} - Exception: {}", 
             duration, request.getDescription(false), ex.getClass().getSimpleName(), ex);
    
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
}
```

---

## 📝 Log Best Practices được implement

✅ **Structured Logging**: Parameterized messages với consistent format  
✅ **Appropriate Log Levels**: WARN cho client errors, ERROR cho system errors  
✅ **Context Information**: Request URI, parameters, user context  
✅ **Performance**: Lazy evaluation với parameterized logging  
✅ **Security**: Không log sensitive information  
✅ **Debugging**: Stack traces cho unexpected errors  
✅ **Monitoring**: Consistent format cho log aggregation tools  

---

*File này giúp developers và DevOps teams monitor và troubleshoot exception handling effectively.*
