# JWT Token Forwarding Implementation

## Tổng quan

Chúng ta đã tái cấu trúc hệ thống để tự động chuyển tiếp JWT token giữa các service thông qua **Feign Client** và **JwtForwardingInterceptor**.

## Cấu trúc mới

### 1. JwtForwardingInterceptor
- **File**: `src/main/java/com/kienlongbank/klbaccountmanagement/config/JwtForwardingInterceptor.java`
- **Chức năng**: Tự động lấy JWT token từ request gốc và đính kèm vào tất cả requests từ Feign Client
- **Cách hoạt động**:
  ```java
  // Tự động lấy Authorization header từ request hiện tại
  String authHeader = request.getHeader("Authorization");
  // Đính kèm vào Feign request
  requestTemplate.header("Authorization", authHeader);
  ```

### 2. CustomerClient (Feign Interface)
- **File**: `src/main/java/com/kienlongbank/klbaccountmanagement/client/CustomerClient.java`
- **Chức năng**: Interface definition cho Customer Service API calls
- **Tự động sử dụng**: JwtForwardingInterceptor được config trong `@FeignClient`

### 3. CustomerServiceClientV2
- **File**: `src/main/java/com/kienlongbank/klbaccountmanagement/service/CustomerServiceClientV2.java`
- **Thay thế**: `CustomerServiceClient` (RestTemplate-based)
- **Cải tiến**:
  - Tự động forward JWT token
  - Better error handling với Feign exceptions
  - Structured logging
  - Type-safe API responses

## Cách sử dụng

### Trong Service Classes:
```java
@Service
public class YourService {
    @Autowired
    private CustomerServiceClientV2 customerClient;
    
    public void someMethod() {
        // JWT token sẽ được tự động forward!
        CustomerDTO customer = customerClient.getCustomerById(123L);
    }
}
```

### Không cần làm gì thêm!
- Token được tự động extract từ incoming request
- Token được tự động attach vào outgoing Feign requests
- Xử lý lỗi được cải thiện (401, 404, etc.)

## Configuration

### Dependencies (đã thêm vào pom.xml):
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
```

### Application Properties:
```properties
# Customer Service URL (Docker container name)
customer.service.url=http://klb-customer-service:8081

# Feign timeouts
feign.client.config.default.connect-timeout=5000
feign.client.config.default.read-timeout=5000
feign.client.config.customer-service.logger-level=full
```

### Main Application:
```java
@SpringBootApplication
@EnableFeignClients  // ← Đã thêm
public class KlbAccountManagementApplication {
    // ...
}
```

## Testing

### Test JWT Forwarding:
1. Gọi API endpoint với JWT token:
   ```bash
   curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
        http://localhost:8080/api/accounts
   ```

2. Check logs để verify token forwarding:
   ```
   INFO - Creating account for customer ID: 123
   DEBUG - Forwarding JWT token to customer-service
   INFO - Successfully created account KLB1234567890 for customer 123
   ```

## Migration Guide

### Từ RestTemplate sang Feign:

**Trước (RestTemplate):**
```java
@Autowired
private CustomerServiceClient customerServiceClient;

// Phải manually handle token passing
public CustomerDTO getCustomer(Long id) {
    // Complicated token extraction and forwarding
    return customerServiceClient.getCustomerById(id);
}
```

**Sau (Feign):**
```java
@Autowired
private CustomerServiceClientV2 customerServiceClient;

// Token tự động được forward!
public CustomerDTO getCustomer(Long id) {
    return customerServiceClient.getCustomerById(id);
}
```

## Troubleshooting

### Common Issues:

1. **401 Unauthorized**:
   - Check JWT token validity
   - Verify Keycloak is accessible
   - Check user roles

2. **404 Not Found**:
   - Verify customer-service URL
   - Check Docker container connectivity

3. **Connection Timeout**:
   - Check Feign timeouts in application.properties
   - Verify Docker network connectivity

### Debug Commands:
```bash
# Check container connectivity
docker exec klb-account-management curl http://klb-customer-service:8081/actuator/health

# Check logs
docker logs klb-account-management
docker logs klb-customer-service
```

## Benefits

1. **Automatic Token Forwarding**: Không cần manual token handling
2. **Type Safety**: Feign provides compile-time type checking
3. **Better Error Handling**: Structured exception handling with FeignException
4. **Centralized Configuration**: All HTTP client config in one place
5. **Easier Testing**: Mock Feign clients easily in tests
6. **Circuit Breaker Ready**: Easy integration with Hystrix/Resilience4j

## Next Steps

1. **Add Retry Logic**: Implement retry mechanism for failed calls
2. **Circuit Breaker**: Add Hystrix or Resilience4j for fault tolerance
3. **Metrics**: Add Micrometer metrics for monitoring
4. **Caching**: Implement response caching where appropriate

---

## Customer Service Security Configuration

### Enhanced SecurityConfig.java
The customer service has been configured with comprehensive JWT authentication:

**Key Features:**
- **JWT Token Validation**: Connects to Keycloak for token verification
- **Role Extraction**: Automatically extracts roles from `realm_access.roles` claim
- **Method Security**: Supports `@PreAuthorize` annotations
- **Endpoint Protection**: All `/api/customers/*` endpoints require authentication
- **Admin Endpoints**: `/api/admin/*` require ADMIN role
- **Public Access**: Health checks, Swagger UI, and actuator endpoints are public

### Security Configuration Details:

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {
    // JWT Authentication Converter extracts roles from Keycloak
    // Session management set to STATELESS
    // CSRF disabled for API usage
}
```

### Protected Endpoints:

| Endpoint Pattern | Access Level | Description |
|------------------|--------------|-------------|
| `/api/customers/**` | Authenticated | Requires valid JWT token |
| `/api/admin/**` | ADMIN role | Requires ADMIN authority in JWT |
| `/swagger-ui/**` | Public | API documentation |
| `/actuator/health` | Public | Health monitoring |
| `/api/health` | Public | Custom health endpoint |

### JWT Token Flow:
1. **Account Management Service** → receives request with JWT
2. **JwtForwardingInterceptor** → extracts token from request context
3. **Feign Client** → forwards token to Customer Service
4. **Customer Service SecurityConfig** → validates token with Keycloak
5. **JwtAuthenticationConverter** → extracts roles from token
6. **Endpoint Authorization** → grants/denies access based on roles

### Testing Customer Service Security:
```bash
# Run comprehensive security tests
powershell -ExecutionPolicy Bypass -File test-customer-service-security.ps1
```

This ensures end-to-end JWT token forwarding and proper authentication across all microservices.
