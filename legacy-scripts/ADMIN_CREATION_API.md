# 🔧 Admin User Creation API - Hướng dẫn sử dụng

## 📋 Tổng quan

API này cho phép tạo admin user một cách có kiểm soát trong hệ thống KLB Account Management. Đây là cách sạch sẽ và an toàn để tạo admin đầu tiên cho hệ thống.

## 🚀 Các Endpoint mới

### 1. Tạo Admin User
```
POST /api/auth/register-admin
```

**Request Body:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response (Success):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "message": "Tạo admin thành công!"
}
```

**Response (Error):**
```json
{
  "token": null,
  "message": "Username đã tồn tại!"
}
```

### 2. Kiểm tra trạng thái Admin
```
GET /api/auth/admin-status
```

**Response:**
```json
{
  "token": null,
  "message": "Hệ thống đã có 2 admin user(s)"
}
```

## 🔍 Thay đổi trong Code

### 1. AuthService.java (Mới)
```java
// Phương thức chính để tạo admin
public AuthResponse createAdmin(RegisterRequest request) {
    // Logic tạo admin với Role.ADMIN
}

// Kiểm tra có admin trong hệ thống hay chưa
public boolean hasAdminUsers() {
    return userRepository.existsByRole(Role.ADMIN);
}

// Đếm số lượng admin
public long countAdminUsers() {
    return userRepository.countByRole(Role.ADMIN);
}
```

### 2. UserRepository.java (Cập nhật)
```java
// Thêm methods để kiểm tra role
boolean existsByRole(Role role);
long countByRole(Role role);
```

### 3. AuthController.java (Refactored)
- Di chuyển business logic vào AuthService
- Thêm endpoint `/register-admin`
- Thêm endpoint `/admin-status`

## 📝 Cách sử dụng

### 1. Sử dụng cURL:
```bash
# Tạo admin
curl -X POST http://localhost:8080/api/auth/register-admin \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'

# Kiểm tra trạng thái
curl -X GET http://localhost:8080/api/auth/admin-status
```

### 2. Sử dụng PowerShell:
```powershell
# Chạy script test tự động
.\test-admin-api.ps1
```

### 3. Sử dụng Postman:
- Import collection: `KLB_Account_Management.postman_collection.json`
- Thêm request mới với endpoint `/api/auth/register-admin`

## 🔒 Bảo mật

### Khuyến nghị:
1. **Chỉ sử dụng trong môi trường phát triển** hoặc khi setup hệ thống lần đầu
2. **Xóa hoặc vô hiệu hóa endpoint này** trong production sau khi đã tạo admin
3. **Sử dụng mật khẩu mạnh** cho tài khoản admin
4. **Ghi log** các hoạt động tạo admin để audit

### Cách vô hiệu hóa trong Production:
```java
@PostMapping("/register-admin")
@Profile("!production")  // Chỉ hoạt động khi không phải production
public ResponseEntity<AuthResponse> registerAdmin(@RequestBody RegisterRequest request) {
    // ...
}
```

Hoặc:
```java
@PostMapping("/register-admin")
public ResponseEntity<AuthResponse> registerAdmin(@RequestBody RegisterRequest request) {
    // Kiểm tra nếu đã có admin thì không cho tạo nữa
    if (authService.hasAdminUsers()) {
        return ResponseEntity.badRequest()
            .body(new AuthResponse(null, "Hệ thống đã có admin, không thể tạo thêm!"));
    }
    // ...
}
```

## 🧪 Testing

Chạy script test:
```powershell
# Đảm bảo server đang chạy trước
cd klb-account-management
mvn spring-boot:run

# Mở terminal mới và chạy test
.\test-admin-api.ps1
```

## 🎯 Lợi ích của cách tiếp cận này

1. **Clean Architecture**: Tách biệt business logic vào service layer
2. **Kiểm soát**: Có thể kiểm tra trạng thái admin trước khi tạo
3. **An toàn**: Không cần hardcode admin trong code
4. **Linh hoạt**: Có thể tạo nhiều admin nếu cần
5. **Audit**: Có thể log và theo dõi việc tạo admin

## 🔄 Luồng hoạt động

1. **Kiểm tra trạng thái** → `GET /admin-status`
2. **Tạo admin đầu tiên** → `POST /register-admin`
3. **Verify** → Đăng nhập với tài khoản admin vừa tạo
4. **Setup hoàn tất** → Có thể vô hiệu hóa endpoint nếu cần
