# Customer Service Migration

## Tổng quan
Đã thành công di chuyển toàn bộ các components liên quan đến Customer từ project monolith `klb-account-management` sang microservice `customer-service`.

## Các file đã di chuyển

### Model
- `Customer.java` - Entity chính của Customer

### Repository  
- `CustomerRepository.java` - JPA Repository cho Customer

### Service
- `CustomerService.java` - Business logic cho Customer operations

### Controller
- `CustomerController.java` - REST API endpoints cho Customer

### DTO
- `ApiResponse.java` - Generic response wrapper

## Cấu hình
- **Port**: 8082 (khác với main service là 8080)
- **Database**: Dùng chung database `account_management` với main service
- **Swagger UI**: `http://localhost:8082/swagger-ui.html`

## Thay đổi trong project gốc
1. **Account model**: Thay thế `Customer customer` relationship bằng `Long customerId`
2. **AccountService**: Cập nhật logic để sử dụng `customerId` thay vì Customer object
3. **AccountController**: Cập nhật để sử dụng `customerId` trực tiếp

## Endpoints Customer Service
- `GET /api/customers` - Lấy danh sách tất cả customers
- `POST /api/customers` - Tạo customer mới
- `GET /api/customers/{id}` - Lấy customer theo ID
- `PUT /api/customers/{id}` - Cập nhật customer
- `DELETE /api/customers/{id}` - Xóa customer

## Chạy Customer Service
```bash
cd customer-service/customer-service
mvn spring-boot:run
```

## Chạy cả hai services
1. **Main Service (Account Management)**: Port 8080
2. **Customer Service**: Port 8082

Trong tương lai, Account Service có thể gọi Customer Service API để verify customer existence thay vì direct database access.
