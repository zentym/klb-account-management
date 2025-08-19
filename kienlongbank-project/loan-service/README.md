# Loan Service

Service quản lý khoản vay trong hệ thống Kienlongbank.

## Tính năng chính

- **Đăng ký khoản vay**: Khách hàng có thể nộp đơn đăng ký vay
- **Xác minh khách hàng**: Tự động xác minh thông tin khách hàng qua Customer Service
- **Kiểm tra tín dụng**: Đánh giá khả năng tín dụng của khách hàng
- **Phê duyệt/Từ chối**: Quản lý phê duyệt khoản vay
- **Quản lý trạng thái**: Theo dõi trạng thái khoản vay (PENDING, APPROVED, REJECTED, DISBURSED, CLOSED)

## API Endpoints

### Đăng ký khoản vay
```
POST /api/loans/apply
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "customerId": 1,
  "amount": 10000000,
  "interestRate": 8.5,
  "term": 12,
  "purpose": "Mua nhà",
  "collateral": "Sổ đỏ nhà"
}
```

### Lấy danh sách khoản vay của khách hàng
```
GET /api/loans/customer/{customerId}
Authorization: Bearer <JWT_TOKEN>
```

### Lấy thông tin khoản vay theo ID
```
GET /api/loans/{loanId}
Authorization: Bearer <JWT_TOKEN>
```

### Lấy danh sách khoản vay theo trạng thái (Admin/Manager)
```
GET /api/loans/status/{status}
Authorization: Bearer <JWT_TOKEN>
```

### Phê duyệt khoản vay (Admin/Manager)
```
PUT /api/loans/{loanId}/approve
Authorization: Bearer <JWT_TOKEN>
```

### Từ chối khoản vay (Admin/Manager)
```
PUT /api/loans/{loanId}/reject
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "reason": "Không đủ điều kiện tín dụng"
}
```

### Health Check
```
GET /api/loans/public/health
```

## Cấu hình

### Database
- PostgreSQL database: `loan_service_db`
- Port: 5435
- User: `kienlong_loan`

### Keycloak
- Issuer URI: `http://localhost:8090/realms/Kienlongbank`
- JWK Set URI: `http://localhost:8090/realms/Kienlongbank/protocol/openid_connect/certs`

### Service Dependencies
- Customer Service: `http://localhost:8082`

## Quyền hạn

- **customer**: Có thể đăng ký khoản vay, xem khoản vay của mình
- **manager**: Có thể xem tất cả khoản vay, phê duyệt/từ chối
- **admin**: Có tất cả quyền

## Cấu trúc Database

### Bảng loans
```sql
CREATE TABLE loans (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    term INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    application_date TIMESTAMP NOT NULL,
    approval_date TIMESTAMP,
    approved_by VARCHAR(255),
    reject_reason TEXT
);
```

## Tích hợp với Services khác

### Customer Service
- `GET /api/customers/{customerId}`: Xác minh thông tin khách hàng
- `GET /api/customers/{customerId}/credit-check`: Kiểm tra tín dụng

## Security

- JWT Authentication qua Keycloak
- Method-level security với `@PreAuthorize`
- Automatic JWT forwarding cho Feign clients
- CORS support cho frontend

## Chạy ứng dụng

1. Đảm bảo PostgreSQL đang chạy trên port 5435
2. Đảm bảo Keycloak đang chạy trên port 8090
3. Đảm bảo Customer Service đang chạy trên port 8082
4. Chạy: `mvn spring-boot:run`
5. Service sẽ chạy trên port 8083

## Testing

```bash
mvn test
```

## Logs

Service ghi log ở level DEBUG cho:
- Spring Security
- Spring Web  
- com.kienlong package

## Error Handling

- Validation errors trả về HTTP 400
- Authentication errors trả về HTTP 401
- Authorization errors trả về HTTP 403
- Not found errors trả về HTTP 404
- Server errors trả về HTTP 500
