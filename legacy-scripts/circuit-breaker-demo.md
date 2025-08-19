# Circuit Breaker Implementation Demo

## Tổng quan
Đã thành công implement Circuit Breaker pattern cho AccountService với các tính năng sau:

## 1. Cấu hình Circuit Breaker (application.properties)

```properties
# Kích hoạt Circuit Breaker cho OpenFeign
feign.circuitbreaker.enabled=true

# Cấu hình chi tiết cho Circuit Breaker tên "customerService"
resilience4j.circuitbreaker.instances.customerService.failure-rate-threshold=50
# Ngắt mạch nếu 50% request trong cửa sổ trượt bị lỗi

resilience4j.circuitbreaker.instances.customerService.sliding-window-size=10
# Kích thước của cửa sổ trượt là 10 request

resilience4j.circuitbreaker.instances.customerService.wait-duration-in-open-state=5s
# Thời gian chờ ở trạng thái OPEN là 5 giây trước khi chuyển sang HALF_OPEN

resilience4j.circuitbreaker.instances.customerService.permitted-number-of-calls-in-half-open-state=3
# Số request được phép thử trong trạng thái HALF_OPEN
```

## 2. Implementation trong CustomerServiceClientV2

### CircuitBreaker được áp dụng trên method customerExists():

```java
@CircuitBreaker(name = "customerService", fallbackMethod = "customerExistsFallback")
public boolean customerExists(Long customerId) {
    try {
        CustomerDTO customer = getCustomerById(customerId);
        return customer != null;
    } catch (FeignException.NotFound e) {
        log.debug("Customer with ID {} not found", customerId);
        return false;
    } catch (Exception e) {
        log.error("Error checking customer existence for ID {}: {}", customerId, e.getMessage());
        // Ném exception để trigger circuit breaker
        throw new RuntimeException("Customer service unavailable", e);
    }
}
```

### Phương thức Fallback:

```java
public boolean customerExistsFallback(Long customerId, Throwable throwable) {
    log.error("Circuit breaker activated for customer service. Customer ID: {}, Error: {}", 
             customerId, throwable.getMessage());
    
    log.debug("Customer service fallback triggered due to: ", throwable);
    
    // Ném exception để báo cho AccountService biết rằng không thể xác minh customer
    throw new RuntimeException("Hệ thống khách hàng đang tạm thời gián đoạn, không thể xác minh thông tin khách hàng. " +
                             "Mã lỗi: CB-CUST-001");
}
```

## 3. Cách hoạt động trong AccountService

```java
public Account createAccount(Long customerId, Account account) {
    log.info("Creating account for customer ID: {}", customerId);
    
    // Kiểm tra customerId hợp lệ
    if (customerId == null || customerId <= 0) {
        throw new RuntimeException("Customer ID không hợp lệ: " + customerId);
    }

    // Kiểm tra customer có tồn tại - Circuit Breaker sẽ được áp dụng tự động
    try {
        if (!customerServiceClient.customerExists(customerId)) {
            throw new RuntimeException("Không tìm thấy khách hàng với ID: " + customerId);
        }
    } catch (RuntimeException e) {
        // Re-throw Circuit Breaker exceptions hoặc customer not found exceptions
        log.error("Failed to verify customer {}: {}", customerId, e.getMessage());
        throw e;
    }

    // Tiếp tục logic tạo tài khoản...
}
```

## 4. Cách test Circuit Breaker

### Test Case 1: Customer Service hoạt động bình thường
- Gọi API tạo tài khoản với customerId hợp lệ
- Circuit breaker ở trạng thái CLOSED
- Request được xử lý bình thường

### Test Case 2: Customer Service gặp lỗi
- Stop customer-service hoặc simulate network error
- Gọi API tạo tài khoản
- Sau 5/10 requests lỗi (50% threshold), circuit breaker chuyển sang OPEN
- Fallback method được gọi, trả về error message với mã lỗi CB-CUST-001

### Test Case 3: Circuit Breaker Recovery
- Khởi động lại customer-service
- Sau 5 giây, circuit breaker chuyển sang HALF_OPEN
- Cho phép 3 requests thử nghiệm
- Nếu thành công, chuyển về CLOSED

## 5. Lợi ích của implementation này

1. **Fail Fast**: Không chờ timeout khi service downstream gặp sự cố
2. **Service Recovery**: Tự động phát hiện khi service downstream phục hồi
3. **User Experience**: Trả về error message rõ ràng thay vì timeout
4. **System Stability**: Giảm tải cho service đang gặp sự cố
5. **Monitoring**: Log chi tiết để theo dõi trạng thái circuit breaker

## 6. Monitoring và Metrics

Circuit Breaker tự động expose metrics qua Micrometer:
- `resilience4j_circuitbreaker_state`: Trạng thái hiện tại (OPEN/CLOSED/HALF_OPEN)
- `resilience4j_circuitbreaker_calls`: Số lượng calls theo loại (successful/failed)
- `resilience4j_circuitbreaker_failure_rate`: Tỷ lệ lỗi hiện tại

## 7. Dependencies cần thiết

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-circuitbreaker-resilience4j</artifactId>
</dependency>
```

Circuit Breaker pattern đã được implement thành công và sẵn sàng để testing!
