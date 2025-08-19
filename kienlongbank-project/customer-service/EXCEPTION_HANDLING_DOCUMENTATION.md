# 🚨 Exception Handling Documentation - Customer Service

## 📋 Tổng quan

File này ghi lại tất cả các Exception Handlers đã được bổ sung vào `GlobalExceptionHandler` của Customer Service để xử lý lỗi một cách nhất quán và thân thiện với người dùng.

## 🎯 Mục tiêu

- ✅ Xử lý lỗi tập trung và nhất quán
- ✅ Thông báo lỗi bằng tiếng Việt
- ✅ Format response chuẩn với `ApiResponse`
- ✅ Bảo mật thông tin nhạy cảm
- ✅ Logging và debugging hiệu quả

---

## 📝 Chi tiết Exception Handlers

### 🎯 1. BUSINESS LOGIC EXCEPTIONS

#### 1.1 CustomerNotFoundException
```java
@ExceptionHandler(CustomerNotFoundException.class)
```

**Mục đích**: Xử lý khi không tìm thấy khách hàng theo ID

**HTTP Status**: `404 NOT_FOUND`

**Response Format**:
```json
{
  "status": "error",
  "message": "Không tìm thấy khách hàng với ID: 123",
  "data": null,
  "timestamp": "2025-08-13T10:30:00"
}
```

**Test Case**:
```bash
curl -X GET http://localhost:8082/api/customers/999999
```

---

### 📝 2. VALIDATION EXCEPTIONS

#### 2.1 MethodArgumentNotValidException
```java
@ExceptionHandler(MethodArgumentNotValidException.class)
```

**Mục đích**: Xử lý lỗi validation khi sử dụng `@Valid` annotation

**HTTP Status**: `400 BAD_REQUEST`

**Kích hoạt khi**:
- Trường required để trống (`@NotBlank`)
- Email sai format (`@Email`)
- Độ dài không đúng (`@Size`)
- Pattern không match (`@Pattern`)

**Response Format**:
```json
{
  "status": "error",
  "message": "Dữ liệu đầu vào không hợp lệ",
  "data": {
    "fullName": "Họ tên không được để trống",
    "email": "Email không đúng định dạng",
    "phone": "Số điện thoại không đúng định dạng (VD: 0901234567 hoặc +84901234567)"
  },
  "timestamp": "2025-08-13T10:30:00"
}
```

**Test Cases**:
```bash
# Test validation errors
curl -X POST http://localhost:8082/api/customers \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "",
    "email": "invalid-email",
    "phone": "123",
    "address": "Test Address"
  }'
```

#### 2.2 ConstraintViolationException
```java
@ExceptionHandler(ConstraintViolationException.class)
```

**Mục đích**: Xử lý lỗi constraint violation ở entity level

**HTTP Status**: `400 BAD_REQUEST`

**Kích hoạt khi**: Database constraints bị vi phạm

**Response Format**:
```json
{
  "status": "error",
  "message": "Vi phạm ràng buộc dữ liệu",
  "data": {
    "email": "Email đã tồn tại trong hệ thống"
  },
  "timestamp": "2025-08-13T10:30:00"
}
```

---

### 🌐 3. HTTP/REQUEST EXCEPTIONS

#### 3.1 HttpMediaTypeNotSupportedException
```java
@ExceptionHandler(HttpMediaTypeNotSupportedException.class)
```

**Mục đích**: Xử lý khi gửi sai Content-Type

**HTTP Status**: `415 UNSUPPORTED_MEDIA_TYPE`

**Kích hoạt khi**: Gửi XML, text/plain thay vì JSON

**Response Format**:
```json
{
  "status": "error",
  "message": "Loại dữ liệu không được hỗ trợ. Vui lòng sử dụng Content-Type: application/json",
  "data": {
    "supportedTypes": "[application/json]",
    "receivedType": "text/plain"
  },
  "timestamp": "2025-08-13T10:30:00"
}
```

**Test Case**:
```bash
curl -X POST http://localhost:8082/api/customers \
  -H "Content-Type: text/plain" \
  -d "invalid data"
```

#### 3.2 HttpRequestMethodNotSupportedException
```java
@ExceptionHandler(HttpRequestMethodNotSupportedException.class)
```

**Mục đích**: Xử lý khi sử dụng HTTP method không được hỗ trợ

**HTTP Status**: `405 METHOD_NOT_ALLOWED`

**Test Case**:
```bash
curl -X PATCH http://localhost:8082/api/customers/1
```

#### 3.3 HttpMessageNotReadableException
```java
@ExceptionHandler(HttpMessageNotReadableException.class)
```

**Mục đích**: Xử lý JSON malformed hoặc không đọc được

**HTTP Status**: `400 BAD_REQUEST`

**Test Case**:
```bash
curl -X POST http://localhost:8082/api/customers \
  -H "Content-Type: application/json" \
  -d '{"fullName": "Test", "email":}'
```

#### 3.4 MethodArgumentTypeMismatchException
```java
@ExceptionHandler(MethodArgumentTypeMismatchException.class)
```

**Mục đích**: Xử lý lỗi chuyển đổi kiểu dữ liệu

**HTTP Status**: `400 BAD_REQUEST`

**Kích hoạt khi**: Gửi string cho Long ID

**Test Case**:
```bash
curl -X GET http://localhost:8082/api/customers/invalid-id
```

#### 3.5 MissingPathVariableException
```java
@ExceptionHandler(MissingPathVariableException.class)
```

**Mục đích**: Xử lý thiếu path variable

**HTTP Status**: `400 BAD_REQUEST`

#### 3.6 MissingServletRequestParameterException
```java
@ExceptionHandler(MissingServletRequestParameterException.class)
```

**Mục đích**: Xử lý thiếu request parameter bắt buộc

**HTTP Status**: `400 BAD_REQUEST`

---

### 🔐 4. SECURITY EXCEPTIONS

#### 4.1 AuthenticationException
```java
@ExceptionHandler(AuthenticationException.class)
```

**Mục đích**: Xử lý lỗi xác thực JWT

**HTTP Status**: `401 UNAUTHORIZED`

**Kích hoạt khi**:
- Không có Authorization header
- JWT token không hợp lệ
- JWT token đã hết hạn

**Response Format**:
```json
{
  "status": "error",
  "message": "Xác thực thất bại. Vui lòng kiểm tra JWT token",
  "data": null,
  "timestamp": "2025-08-13T10:30:00"
}
```

**Test Case**:
```bash
# Test without token
curl -X GET http://localhost:8082/api/customers

# Test with invalid token
curl -X GET http://localhost:8082/api/customers \
  -H "Authorization: Bearer invalid-token"
```

#### 4.2 AccessDeniedException
```java
@ExceptionHandler(AccessDeniedException.class)
```

**Mục đích**: Xử lý khi user đã xác thực nhưng không có quyền

**HTTP Status**: `403 FORBIDDEN`

**Kích hoạt khi**: User không có ADMIN role để truy cập admin endpoints

**Test Case**:
```bash
# Test admin endpoint without ADMIN role
curl -X GET http://localhost:8082/api/admin/hello \
  -H "Authorization: Bearer <USER_TOKEN>"
```

#### 4.3 BadCredentialsException
```java
@ExceptionHandler(BadCredentialsException.class)
```

**Mục đích**: Xử lý thông tin xác thực sai

**HTTP Status**: `401 UNAUTHORIZED`

---

### 🗃️ 5. DATABASE EXCEPTIONS

#### 5.1 SQLException
```java
@ExceptionHandler(SQLException.class)
```

**Mục đích**: Xử lý lỗi SQL database với thông báo thân thiện

**HTTP Status**: `500 INTERNAL_SERVER_ERROR`

**SQL State Codes được xử lý**:
- **23xxx**: Integrity constraint violation
  - Unique constraint → "Dữ liệu đã tồn tại. Email có thể đã được sử dụng"
  - Other constraints → "Vi phạm ràng buộc dữ liệu"
- **42xxx**: Syntax error → "Lỗi truy vấn cơ sở dữ liệu"
- **08xxx**: Connection exception → "Lỗi kết nối cơ sở dữ liệu"

**Response Format**:
```json
{
  "status": "error",
  "message": "Dữ liệu đã tồn tại. Email có thể đã được sử dụng",
  "data": null,
  "timestamp": "2025-08-13T10:30:00"
}
```

---

### 🚫 6. GENERIC EXCEPTIONS

#### 6.1 NoHandlerFoundException
```java
@ExceptionHandler(NoHandlerFoundException.class)
```

**Mục đích**: Xử lý 404 - endpoint không tồn tại

**HTTP Status**: `404 NOT_FOUND`

**Test Case**:
```bash
curl -X GET http://localhost:8082/api/nonexistent
```

#### 6.2 Exception (Catch-all)
```java
@ExceptionHandler(Exception.class)
```

**Mục đích**: Xử lý tất cả lỗi không mong đợi khác

**HTTP Status**: `500 INTERNAL_SERVER_ERROR`

**Tính năng**:
- In stack trace cho debugging (development)
- Thông báo generic cho user
- Không làm lộ thông tin nhạy cảm

---

## 🧪 Testing Strategy

### Test Cases Coverage

1. **Validation Tests**:
   ```bash
   # Empty required fields
   curl -X POST http://localhost:8082/api/customers -H "Content-Type: application/json" -d '{"fullName":"","email":"","phone":"","address":""}'
   
   # Invalid email format
   curl -X POST http://localhost:8082/api/customers -H "Content-Type: application/json" -d '{"fullName":"Test","email":"invalid","phone":"0901234567","address":"Test"}'
   
   # Invalid phone format
   curl -X POST http://localhost:8082/api/customers -H "Content-Type: application/json" -d '{"fullName":"Test","email":"test@example.com","phone":"123","address":"Test"}'
   ```

2. **HTTP Error Tests**:
   ```bash
   # Wrong content type
   curl -X POST http://localhost:8082/api/customers -H "Content-Type: text/plain" -d "invalid"
   
   # Wrong method
   curl -X PATCH http://localhost:8082/api/customers/1
   
   # Malformed JSON
   curl -X POST http://localhost:8082/api/customers -H "Content-Type: application/json" -d '{"name":'
   ```

3. **Security Tests**:
   ```bash
   # No token
   curl -X GET http://localhost:8082/api/customers
   
   # Invalid token
   curl -X GET http://localhost:8082/api/customers -H "Authorization: Bearer invalid"
   
   # Admin endpoint without ADMIN role
   curl -X GET http://localhost:8082/api/admin/hello -H "Authorization: Bearer <USER_TOKEN>"
   ```

### Expected Response Format

Tất cả exceptions đều trả về format chuẩn:

```json
{
  "status": "error",
  "message": "Mô tả lỗi bằng tiếng Việt",
  "data": {
    // Chi tiết lỗi (nếu có)
  },
  "timestamp": "2025-08-13T10:30:00"
}
```

---

## 🚀 Integration với Security

GlobalExceptionHandler tích hợp hoàn hảo với Spring Security và JWT authentication:

1. **JWT Authentication Flow**: Tự động xử lý lỗi token validation
2. **Role-based Authorization**: Xử lý 403 khi user không có quyền
3. **Security Configuration**: Hoạt động seamlessly với SecurityConfig

---

## 📚 Best Practices

### ✅ Đã implement:
- ✅ Centralized error handling
- ✅ Consistent response format  
- ✅ Localized error messages (Vietnamese)
- ✅ Security-aware error handling
- ✅ Detailed validation error reporting
- ✅ Database error translation
- ✅ Proper HTTP status codes
- ✅ **Comprehensive SLF4J logging với structured format**
- ✅ **Production-ready logging với appropriate log levels**
- ✅ **Request context tracking trong logs**
- ✅ **Parameterized logging cho performance**

### 🔒 Security Considerations:
- Không expose stack trace cho production
- Không leak internal system information
- Generic messages cho system errors
- Detailed validation errors chỉ cho development

### 📊 **6. Monitoring & Logging**

#### **SLF4J Logging Implementation**

**Logger Configuration**: 
- Sử dụng `@Slf4j` annotation của Lombok
- Automatic logger injection với tên `log`
- Structured logging với parameterized messages

**Log Levels được sử dụng**:
- `WARN`: Business logic errors, validation failures, client errors (4xx)
- `ERROR`: System errors, database issues, unexpected exceptions (5xx)

**Log Format Pattern**:
```
log.warn("Customer not found: {} - URI: {}", ex.getMessage(), request.getDescription(false));
log.error("Database error: {} - SQLState: {} - URI: {}", message, ex.getSQLState(), request.getDescription(false));
```

**Logging được implement cho tất cả Exception Handlers**:

1. **Business Logic Exceptions**:
   ```java
   log.warn("Customer not found: {} - URI: {}", ex.getMessage(), request.getDescription(false));
   ```

2. **Validation Exceptions**:
   ```java
   log.warn("Validation failed for request: {} - Errors: {} - URI: {}", 
            request.getDescription(false), fieldErrors, request.getDescription(false));
   ```

3. **HTTP/Request Exceptions**:
   ```java
   log.warn("Unsupported media type: {} - Supported: {} - URI: {}", 
            ex.getContentType(), ex.getSupportedMediaTypes(), request.getDescription(false));
   ```

4. **Security Exceptions**:
   ```java
   log.warn("Authentication failed: {} - URI: {}", ex.getMessage(), request.getDescription(false));
   log.warn("Access denied: {} - URI: {}", ex.getMessage(), request.getDescription(false));
   ```

5. **Database Exceptions**:
   ```java
   log.error("Database error: {} - SQLState: {} - URI: {}", 
            message, ex.getSQLState(), request.getDescription(false));
   ```

6. **Generic Exceptions**:
   ```java
   log.error("Unexpected exception occurred - URI: {} - Exception: {}", 
            request.getDescription(false), ex.getClass().getSimpleName(), ex);
   ```

**Logged Information bao gồm**:
- ✅ Exception message
- ✅ Request URI và HTTP method
- ✅ Validation error details
- ✅ SQL error codes
- ✅ Parameter names và values
- ✅ Stack trace cho unexpected errors
- ✅ User context (khi có)

**Production Logging Best Practices**:
- Sensitive information được filter
- Stack traces chỉ log ở DEBUG level
- Structured logging cho easy parsing
- Request correlation IDs (future enhancement)

---

## 🛠️ Development Guidelines

### Thêm Exception Handler mới:

1. Xác định exception type cần xử lý
2. Chọn HTTP status code phù hợp
3. Viết message bằng tiếng Việt
4. Sử dụng `ApiResponse.error()` format
5. Thêm test cases
6. Update documentation này

### Example:
```java
@ExceptionHandler(CustomBusinessException.class)
public ResponseEntity<ApiResponse<Object>> handleCustomBusinessException(
        CustomBusinessException ex) {
    
    ApiResponse<Object> response = ApiResponse.error("Thông báo lỗi bằng tiếng Việt");
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
}
```

---

## 📝 Changelog

**Version 1.1 - August 13, 2025**
- ✅ Comprehensive SLF4J logging implementation
- ✅ Structured logging với parameterized messages
- ✅ Appropriate log levels (WARN for client errors, ERROR for system errors)
- ✅ Request context tracking trong tất cả logs
- ✅ Production-ready logging configuration
- ✅ Performance-optimized với lazy evaluation

---

## 🔗 Related Files

- **GlobalExceptionHandler.java**: Main implementation file
- **CustomerNotFoundException.java**: Custom business exception
- **SecurityConfig.java**: Security configuration
- **ApiResponse.java**: Response wrapper class
- **CustomerController.java**: Protected endpoints
- **AdminController.java**: Admin-only endpoints

---

*Tài liệu này sẽ được cập nhật khi có thay đổi trong exception handling logic.*
