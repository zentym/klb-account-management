# Common API Module

This module contains shared interfaces, DTOs, and constants used across all KienLongBank microservices.

## Purpose

The `common-api` module serves as a contract layer between different microservices, providing:

- **Data Transfer Objects (DTOs)**: Standardized data structures for inter-service communication
- **API Interfaces**: Define contracts that services can implement
- **Constants**: Shared constants and enums used across services
- **Response Wrappers**: Consistent response formats

## Key Benefits

1. **Decoupling**: Services don't depend on each other's internal database entities
2. **Consistency**: Standardized data formats across all services
3. **Type Safety**: Compile-time validation of inter-service contracts
4. **Versioning**: Centralized place to manage API versions

## Structure

```
src/main/java/com/kienlongbank/common/
├── api/
│   └── CustomerApi.java           # Customer service interface
├── dto/
│   ├── CustomerDTO.java           # Customer data transfer object
│   ├── ApiResponse.java           # Generic API response wrapper
│   └── PagedResponse.java         # Paginated response wrapper
└── constants/
    └── CustomerConstants.java     # Customer-related constants
```

## Usage

### 1. Add as Dependency

In your service's `pom.xml`:

```xml
<dependency>
    <groupId>com.kienlongbank</groupId>
    <artifactId>common-api</artifactId>
    <version>1.0.0-SNAPSHOT</version>
</dependency>
```

### 2. Implement Interfaces

In the service that provides functionality:

```java
@Service
public class CustomerServiceImpl implements CustomerApi {
    
    @Override
    public CustomerDTO findCustomerById(Long customerId) {
        // Implementation here
        return customerDTO;
    }
}
```

### 3. Use DTOs for Communication

```java
// In another service that needs customer data
@Autowired
private CustomerApi customerApi;

public void processLoan(Long customerId) {
    CustomerDTO customer = customerApi.findCustomerById(customerId);
    if (customer != null) {
        // Process with customer data
    }
}
```

### 4. Use Response Wrappers

```java
@RestController
public class CustomerController {
    
    @GetMapping("/customers/{id}")
    public ApiResponse<CustomerDTO> getCustomer(@PathVariable Long id) {
        CustomerDTO customer = customerService.findCustomerById(id);
        if (customer != null) {
            return ApiResponse.success(customer, "Customer found");
        } else {
            return ApiResponse.error("Customer not found", 
                CustomerConstants.ErrorCode.CUSTOMER_NOT_FOUND);
        }
    }
}
```

## Best Practices

1. **Use DTOs, not Entities**: Always use DTOs for inter-service communication
2. **Implement Serializable**: All DTOs implement Serializable for caching/messaging
3. **Validate Data**: Use validation annotations on DTOs
4. **Version Control**: Maintain backward compatibility when updating interfaces
5. **Document Changes**: Update this README when adding new interfaces or DTOs

## Dependencies

This module has minimal dependencies to avoid conflicts:

- Java 17
- Jackson for JSON serialization
- Validation API for bean validation
- JUnit for testing

## Building

```bash
mvn clean compile
mvn clean package
mvn clean install
```

## Notes

- This module does NOT include Spring Boot dependencies to avoid conflicts
- Keep this module lightweight and focused on contracts only
- Implementation details should remain in individual services
- Use semantic versioning for releases
