# Customer Service Security Configuration

## Tổng quan

Customer Service đã được cấu hình với bảo mật JWT toàn diện, đảm bảo tất cả các endpoint được bảo vệ và kết nối với Keycloak để xác thực.

## Cấu hình Security

### 1. SecurityConfig.java - Enhanced

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Public endpoints
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**", "/actuator/health").permitAll()
                
                // Admin endpoints
                .requestMatchers("/api/admin/**").hasAuthority("ADMIN")
                
                // Customer endpoints - require authentication
                .requestMatchers("/api/customers/**").authenticated()
                
                // All other requests require authentication
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
            );
    }
}
```

### 2. JWT Authentication Converter

**Chức năng**: Tự động extract roles từ Keycloak JWT token
**Keycloak Role Location**: `realm_access.roles` claim
**Authority Mapping**: Direct mapping (không thêm ROLE_ prefix)

### 3. Application Properties

```properties
# JWT/OAuth2 Resource Server Configuration
spring.security.oauth2.resourceserver.jwt.issuer-uri=http://keycloak:8080/realms/Kienlongbank
spring.security.oauth2.resourceserver.jwt.jwk-set-uri=http://keycloak:8080/realms/Kienlongbank/protocol/openid-connect/certs

# Security Logging
logging.level.org.springframework.security=DEBUG
logging.level.org.springframework.security.oauth2=DEBUG

# Method Security
spring.security.method.pre-post-enabled=true
```

## Endpoint Protection

### Public Endpoints (Không cần authentication)
- `/swagger-ui/**` - API Documentation
- `/v3/api-docs/**` - OpenAPI specification
- `/actuator/health` - Health check
- `/actuator/info` - Service information
- `/api/health` - Custom health endpoint

### Authenticated Endpoints (Cần JWT token)
- `/api/customers/**` - All customer operations
  - `GET /api/customers` - List customers
  - `POST /api/customers` - Create customer
  - `GET /api/customers/{id}` - Get customer by ID
  - `PUT /api/customers/{id}` - Update customer
  - `DELETE /api/customers/{id}` - Delete customer

### Admin Endpoints (Cần ADMIN role)
- `/api/admin/**` - Administrative functions
  - `GET /api/admin/hello` - Admin test endpoint
  - `GET /api/admin/customers/stats` - Customer statistics
  - `DELETE /api/admin/customers/{id}/force` - Force delete customer
  - `GET /api/admin/system/info` - System information

## Controllers Implementation

### 1. CustomerController
- **Path**: `/api/customers`
- **Security**: Requires authentication (.authenticated())
- **Operations**: CRUD operations for customers
- **Token**: JWT token automatically validated

### 2. AdminController  
- **Path**: `/api/admin`
- **Security**: Requires ADMIN role (.hasAuthority("ADMIN"))
- **Operations**: Administrative functions
- **Annotations**: Uses `@PreAuthorize("hasAuthority('ADMIN')")`

### 3. HealthCheckController
- **Path**: `/api/health`, `/api/info` 
- **Security**: Public access (.permitAll())
- **Operations**: Health monitoring and service information

## JWT Token Flow

```
1. Client Request → Customer Service
   ├─ Header: Authorization: Bearer <JWT_TOKEN>
   
2. Spring Security → SecurityFilterChain
   ├─ Extract JWT from Authorization header
   ├─ Validate token with Keycloak (issuer-uri)
   ├─ Parse token claims
   
3. JwtAuthenticationConverter
   ├─ Extract standard scopes
   ├─ Extract realm_access.roles from Keycloak
   ├─ Convert to Spring Security authorities
   
4. Authorization Decision
   ├─ Check endpoint path against security rules
   ├─ Verify user authorities against required roles
   ├─ Grant/Deny access
   
5. Controller Execution
   ├─ @PreAuthorize annotations (if any)
   ├─ Business logic execution
   ├─ Response generation
```

## Testing

### Manual Testing Commands

```bash
# 1. Get JWT Token
curl -X POST http://localhost:8090/realms/Kienlongbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&username=testuser&password=testpassword&client_id=klb-frontend"

# 2. Test Public Endpoint
curl http://localhost:8082/api/health

# 3. Test Protected Endpoint (with token)
curl -H "Authorization: Bearer <JWT_TOKEN>" \
     http://localhost:8082/api/customers

# 4. Test Admin Endpoint (requires ADMIN role)
curl -H "Authorization: Bearer <JWT_TOKEN>" \
     http://localhost:8082/api/admin/hello
```

### Automated Testing

```powershell
# Chạy comprehensive security tests
powershell -ExecutionPolicy Bypass -File test-customer-service-security.ps1
```

## Error Handling

### Common HTTP Status Codes

| Status | Condition | Meaning |
|--------|-----------|---------|
| **200** | Success | Request processed successfully |
| **401** | Unauthorized | No JWT token or invalid token |
| **403** | Forbidden | Valid token but insufficient permissions |
| **404** | Not Found | Resource not found |
| **500** | Server Error | Internal service error |

### JWT-related Errors

1. **No Authorization Header**: 401 Unauthorized
2. **Invalid JWT Token**: 401 Unauthorized  
3. **Expired JWT Token**: 401 Unauthorized
4. **Valid Token but No ADMIN Role**: 403 Forbidden (for admin endpoints)
5. **Keycloak Connection Issue**: 500 Internal Server Error

## Dependencies

### Required Dependencies (đã có trong pom.xml)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

## Troubleshooting

### Debug Commands

```bash
# Check container connectivity
docker exec klb-customer-service curl http://keycloak:8080/realms/Kienlongbank/.well-known/openid_configuration

# Check logs
docker logs klb-customer-service

# Test Keycloak connection
curl http://localhost:8090/realms/Kienlongbank/.well-known/openid_configuration
```

### Common Issues

1. **401 on all endpoints**: 
   - Check Keycloak connectivity
   - Verify JWT issuer URI
   - Check token validity

2. **403 on admin endpoints**:
   - Verify user has ADMIN role in Keycloak
   - Check role claim in JWT token

3. **Token forwarding issues**:
   - Verify JWT is being sent in Authorization header
   - Check Spring Security debug logs

## Security Best Practices Implemented

1. **Stateless Sessions**: No server-side session storage
2. **CSRF Disabled**: Appropriate for API-only services
3. **Role-based Access Control**: Fine-grained permission system
4. **JWT Validation**: Cryptographic token verification
5. **Public Health Endpoints**: For monitoring and load balancing
6. **Method-level Security**: Additional @PreAuthorize protection
7. **Comprehensive Logging**: Debug information for troubleshooting

## Integration với Account Management Service

Customer Service security configuration hoạt động seamlessly với Account Management Service:

1. **Account Management** nhận request với JWT token
2. **JwtForwardingInterceptor** tự động forward token
3. **Customer Service SecurityConfig** validate token
4. **End-to-end Authentication** được đảm bảo

Điều này tạo ra một hệ thống microservice security hoàn chỉnh với JWT token forwarding tự động.
