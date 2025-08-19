# 📍 Log Storage Location Summary

## 🎯 **Customer Service Logging Configuration**

### **Logs được ghi tại:**

```
📂 customer-service/
├── logs/                           # 📁 Log files directory (được tạo tự động)
│   ├── application.log            # 📝 Main application logs (bao gồm exceptions)
│   ├── application.2025-08-13.log # 🗓️ Daily archived logs
│   ├── hibernate.log              # 🗃️ Database & JPA logs
│   ├── security.log               # 🔐 Spring Security logs
│   └── ...
├── src/
├── target/
└── ...
```

### **Log Configuration Files:**

1. **`src/main/resources/logback-spring.xml`** - Main logging configuration
2. **`src/main/resources/application.properties`** - Log levels configuration

---

## 📊 **Exception Logs Location:**

### **GlobalExceptionHandler logs sẽ xuất hiện trong:**

✅ **Console Output** (khi chạy application):
```
2025-08-13 13:45:23 [http-nio-8082-exec-1] WARN  c.e.customer_service.exception.GlobalExceptionHandler - Customer not found: Không tìm thấy khách hàng với ID: 999 - URI: uri=/api/customers/999
```

✅ **File: `logs/application.log`**:
```
2025-08-13 13:45:23 [http-nio-8082-exec-1] WARN  com.example.customer_service.exception.GlobalExceptionHandler - Customer not found: Không tìm thấy khách hàng với ID: 999 - URI: uri=/api/customers/999 
MDC:[traceId=, spanId=]
```

---

## 🔍 **How to Check Logs:**

### **1. Real-time Console Logs:**
Khi chạy application với Maven:
```bash
mvn spring-boot:run
```

### **2. File Logs:**
```bash
# Windows PowerShell
Get-Content "logs/application.log" -Tail 50
Get-Content "logs/application.log" -Wait -Tail 10

# Linux/Mac
tail -f logs/application.log
tail -50 logs/application.log
```

### **3. Search Exception Logs:**
```bash
# Windows
Select-String -Path "logs/application.log" -Pattern "GlobalExceptionHandler"
Select-String -Path "logs/application.log" -Pattern "WARN|ERROR"

# Linux/Mac  
grep "GlobalExceptionHandler" logs/application.log
grep -E "WARN|ERROR" logs/application.log
```

---

## 🚀 **Quick Start để test logging:**

### **Bước 1: Start Application**
```bash
cd customer-service
mvn spring-boot:run
```

### **Bước 2: Trigger Exception** (terminal khác)
```bash
# Trigger CustomerNotFoundException
curl -X GET http://localhost:8082/api/customers/999999

# Trigger Validation Error
curl -X POST http://localhost:8082/api/customers \
  -H "Content-Type: application/json" \
  -d '{"fullName":"","email":"invalid"}'
```

### **Bước 3: Check Logs**
```bash
# Check console output (terminal đang chạy app)
# Hoặc check file:
Get-Content "logs/application.log" -Tail 20
```

---

## 📝 **Log File Rotation:**

- **Daily rotation**: Logs được archive hàng ngày
- **Retention**: Giữ logs trong 30 ngày
- **File naming**: `application.2025-08-13.log`
- **Max history**: 30 files

---

## 🔧 **Customize Log Location:**

Nếu muốn thay đổi vị trí logs, edit `logback-spring.xml`:

```xml
<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>D:/MyLogs/customer-service.log</file>  <!-- Custom path -->
    <!-- ... -->
</appender>
```

---

**📌 Tóm tắt:** Exception logs sẽ xuất hiện trong **console** (real-time) và **`logs/application.log`** file với format đầy đủ và structured để dễ dàng monitoring và debugging.
