# Customer Service Integration Tests

## Tổng quan

Tôi đã tạo đầy đủ **Integration Tests** cho CustomerController để kiểm tra toàn bộ luồng hoạt động của customer-service. Tests này sử dụng MockMvc của Spring Test để giả lập HTTP requests mà không cần khởi động server thực sự.

## Cấu trúc Test

### 1. CustomerControllerIntegrationTest.java
- **Loại**: Integration Test (toàn bộ Spring context)
- **Mục đích**: Kiểm tra luồng hoạt động đầy đủ từ HTTP request → Controller → Service → Repository → Database
- **Database**: Sử dụng H2 in-memory database cho test
- **Security**: Disabled để tập trung vào business logic

### 2. CustomerControllerUnitTest.java  
- **Loại**: Unit Test (chỉ Controller layer)
- **Mục đích**: Kiểm tra Controller logic với Service được mock
- **Ưu điểm**: Nhanh hơn, tập trung vào Controller layer

### 3. Cấu hình Test
- `application-test.properties`: Cấu hình H2 database và logging cho test
- `TestSecurityConfig.java`: Disable security cho test environment

## Test Coverage

### CRUD Operations
- ✅ **GET /api/customers** - Lấy danh sách tất cả customers
- ✅ **POST /api/customers** - Tạo customer mới
- ✅ **GET /api/customers/{id}** - Lấy customer theo ID
- ✅ **PUT /api/customers/{id}** - Cập nhật customer
- ✅ **DELETE /api/customers/{id}** - Xóa customer

### Validation Tests
- ✅ Email validation (định dạng email hợp lệ)
- ✅ Phone number validation (regex pattern cho VN)
- ✅ Required fields validation (@NotBlank)
- ✅ Length validation (@Size)
- ✅ Handling null/empty values

### Edge Cases
- ✅ Customer không tồn tại (ID invalid)
- ✅ Database empty scenarios
- ✅ Full CRUD workflow
- ✅ Multiple customers creation
- ✅ Minimal valid data scenarios

### HTTP Status Codes
- ✅ 200 OK cho successful operations
- ✅ 400 Bad Request cho validation errors
- ✅ Proper JSON response format (ApiResponse wrapper)

## Chạy Tests

### Prerequisites
1. Java 17+
2. Maven 3.6+
3. H2 Database dependency (đã được thêm vào pom.xml)

### Commands

```bash
# Chạy tất cả tests
mvn test

# Chạy chỉ Integration tests
mvn test -Dtest=CustomerControllerIntegrationTest

# Chạy chỉ Unit tests  
mvn test -Dtest=CustomerControllerUnitTest

# Chạy tests với verbose output
mvn test -X

# Chạy tests và generate report
mvn test surefire-report:report
```

### PowerShell Script (Windows)
```powershell
# Trong thư mục customer-service
cd E:\dowload\klb-account-management\kienlongbank-project\customer-service

# Chạy integration tests
mvn test -Dtest=CustomerControllerIntegrationTest -Dspring.profiles.active=test

# Chạy unit tests
mvn test -Dtest=CustomerControllerUnitTest

# Xem kết quả chi tiết
Get-Content target\surefire-reports\TEST-*.xml
```

## Test Scenarios Chi Tiết

### 1. GET All Customers Tests
```java
testGetAllCustomers_WhenEmpty_ShouldReturnEmptyList()
testGetAllCustomers_WithData_ShouldReturnCustomerList()
```

### 2. CREATE Customer Tests
```java
testCreateCustomer_WithValidData_ShouldCreateSuccessfully()
testCreateCustomer_WithInvalidEmail_ShouldReturnBadRequest()
testCreateCustomer_WithBlankFullName_ShouldReturnBadRequest()
testCreateCustomer_WithInvalidPhoneNumber_ShouldReturnBadRequest()
testCreateCustomer_WithNullOptionalFields_ShouldWork()
```

### 3. GET Customer By ID Tests
```java
testGetCustomerById_WithValidId_ShouldReturnCustomer()
testGetCustomerById_WithInvalidId_ShouldReturnNotFound()
```

### 4. UPDATE Customer Tests
```java
testUpdateCustomer_WithValidData_ShouldUpdateSuccessfully()
testUpdateCustomer_WithInvalidId_ShouldReturnNotFound()
testUpdateCustomer_WithInvalidData_ShouldReturnBadRequest()
```

### 5. DELETE Customer Tests
```java
testDeleteCustomer_WithValidId_ShouldDeleteSuccessfully()
testDeleteCustomer_WithInvalidId_ShouldStillReturnSuccess()
```

### 6. Full Workflow Test
```java
testFullCrudFlow_CreateReadUpdateDelete_ShouldWorkCorrectly()
```
- Tạo customer → Đọc → Cập nhật → Đọc lại → Xóa → Verify đã xóa

## Sample Test Data

```java
// Valid Customer
Customer testCustomer = Customer.builder()
    .fullName("Nguyễn Văn Test")
    .email("test@kienlongbank.com") 
    .phone("0901234567")
    .address("123 Test Street, Test City")
    .build();

// Invalid Email
.email("invalid-email") // Sẽ fail validation

// Invalid Phone
.phone("123") // Không match regex pattern

// Minimal Valid Data
Customer minimal = Customer.builder()
    .fullName("AB") // Minimum 2 chars
    .email("a@b.co") // Minimal valid email
    .build(); // phone và address có thể null
```

## Expected JSON Response Format

```json
{
  "status": "success",
  "data": {
    "id": 1,
    "fullName": "Nguyễn Văn Test",
    "email": "test@kienlongbank.com",
    "phone": "0901234567", 
    "address": "123 Test Street, Test City"
  },
  "message": "Tạo khách hàng thành công"
}
```

## Test Configuration

### H2 Database Configuration
```properties
spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=true
```

### Security Disabled
```java
@TestConfiguration
@EnableWebSecurity  
@Profile("test")
public class TestSecurityConfig {
    @Bean
    public SecurityFilterChain testSecurityFilterChain(HttpSecurity http) {
        return http.csrf().disable()
                  .authorizeHttpRequests(authz -> authz.anyRequest().permitAll())
                  .build();
    }
}
```

## Troubleshooting

### Common Issues

1. **Lombok Issues**: Đảm bảo IDE có Lombok plugin installed
2. **H2 Database**: Kiểm tra H2 dependency trong pom.xml
3. **Port Conflicts**: Test sử dụng random port (`server.port=0`)
4. **Security Issues**: Test profile disable security

### Debug Tips

```bash
# Enable debug logging
mvn test -Dlogging.level.org.springframework.test=DEBUG

# View H2 console (if needed)
# Add spring.h2.console.enabled=true to test properties

# Check test reports
cat target/surefire-reports/TEST-CustomerControllerIntegrationTest.xml
```

## Kết Luận

Integration Tests này đảm bảo:
- ✅ Toàn bộ CRUD operations hoạt động chính xác
- ✅ Validation rules được enforce đúng cách  
- ✅ HTTP status codes và JSON format đúng chuẩn
- ✅ Database operations hoạt động đúng
- ✅ Edge cases được handle properly
- ✅ API contract được maintain

Tests có thể chạy độc lập mà không cần dependencies (PostgreSQL, Keycloak) nhờ H2 in-memory database và disabled security.
