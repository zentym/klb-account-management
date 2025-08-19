# 📱 Hướng Dẫn Đăng Nhập Bằng Số Điện Thoại

## 🎯 Tổng Quan

Hệ thống KLB Account Management đã được cập nhật để sử dụng **số điện thoại (SĐT)** thay vì username để đăng nhập.

## 🔄 Những Thay Đổi Chính

### 1. Frontend Components
- ✅ **CustomLoginPage**: Thay đổi từ "Tên đăng nhập" → "📱 Số điện thoại"
- ✅ **RegisterPage**: Cập nhật interface để đăng ký bằng SĐT
- ✅ **Demo Accounts**: 
  - Cũ: `admin` / `testuser` 
  - Mới: `0901234567` / `0987654321`

### 2. Authentication Service
- ✅ **Interface Updates**: `LoginRequest` và `RegisterRequest` sử dụng `phoneNumber`
- ✅ **Validation**: Thêm validation cho định dạng SĐT Việt Nam
- ✅ **Demo Files**: Cập nhật `custom-login-demo.html` và `custom-login-demo-fixed.html`

### 3. Backend Changes
- ✅ **User Entity**: Tạo mới với `phoneNumber` làm username
- ✅ **UserService**: Xử lý đăng ký và xác thực bằng SĐT
- ✅ **AuthController**: REST API cho đăng ký/đăng nhập
- ✅ **Security Config**: Cấu hình authentication với SĐT

### 4. Database Schema
```sql
-- Bảng users mới
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    password VARCHAR(60) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_date TIMESTAMP,
    last_login_date TIMESTAMP
);
```

## 📱 Định Dạng Số Điện Thoại

Hệ thống chấp nhận các định dạng SĐT Việt Nam:
- ✅ `0901234567` (10 số, bắt đầu bằng 0)
- ✅ `+84901234567` (với mã quốc gia +84)
- ✅ `0123456789` (11 số, bắt đầu bằng 0)
- ❌ `123456789` (không đủ số)
- ❌ `12345678901234` (quá dài)

## 🧪 Tài Khoản Demo

### Tài khoản Admin:
- **SĐT**: `0901234567`
- **Mật khẩu**: `admin123`
- **Quyền**: ADMIN

### Tài khoản User:
- **SĐT**: `0987654321` 
- **Mật khẩu**: `password123`
- **Quyền**: USER

## 🔧 Cách Sử Dụng

### 1. Đăng Ký Tài Khoản Mới
```javascript
// Frontend API call
const response = await authService.register('0912345678', 'password123');
```

### 2. Đăng Nhập
```javascript
// Frontend API call  
const response = await authService.login('0912345678', 'password123', true);
```

### 3. API Endpoints
- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/login` - Đăng nhập
- `GET /api/auth/health` - Kiểm tra trạng thái

## ⚡ Testing

### Kiểm tra Frontend
1. Mở `http://localhost:3000`
2. Thử đăng nhập với SĐT: `0901234567`
3. Kiểm tra validation với SĐT không hợp lệ

### Kiểm tra API
```bash
# Đăng ký tài khoản mới
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"0912345678","password":"password123"}'

# Đăng nhập
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"0912345678","password":"password123"}'
```

## 🔒 Bảo Mật

- ✅ Mật khẩu được mã hóa bằng BCrypt
- ✅ Validation định dạng SĐT ở cả frontend và backend  
- ✅ Kiểm tra SĐT trùng lặp khi đăng ký
- ✅ Session management với JWT token
- ✅ CORS configuration cho cross-origin requests

## 📋 TODO

- [ ] Tích hợp JWT token generation
- [ ] Thêm remember me functionality
- [ ] Phone number verification via SMS
- [ ] Password reset via SMS
- [ ] Admin panel cho quản lý user

## 🚀 Deployment

Khi deploy lên production:

1. Cập nhật database với bảng `users`
2. Cấu hình SMS gateway cho verification
3. Update environment variables
4. Test thoroughly với real phone numbers

## 📞 Hỗ Trợ

Nếu có vấn đề gì, vui lòng:
1. Kiểm tra console logs
2. Verify API endpoints đang hoạt động
3. Kiểm tra database connection
4. Test với Postman/curl

---

**Lưu ý**: Đây là version đầu tiên của phone-based authentication. Các tính năng như SMS verification sẽ được thêm trong các version sau.
