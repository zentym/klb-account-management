# Hướng dẫn Sử dụng Trang "Khoản vay của tôi"

## 🎯 Tổng quan
Trang "Khoản vay của tôi" cho phép người dùng xem danh sách tất cả các khoản vay của họ, bao gồm thông tin chi tiết và trạng thái của từng khoản vay.

## 🔗 Cách truy cập

### 1. Từ Dashboard
- Đăng nhập vào hệ thống
- Trên trang Dashboard, click vào nút **"📋 Các khoản vay của tôi"**

### 2. Từ Navigation Menu
- Sau khi đăng nhập, sử dụng menu điều hướng phía trên
- Click vào **"📋 Khoản vay của tôi"**

### 3. Truy cập trực tiếp
- Truy cập URL: `http://localhost:3000/loans/my-loans`

## 📋 Thông tin hiển thị

Bảng danh sách khoản vay bao gồm các cột:

| Cột | Mô tả |
|-----|-------|
| **Mã vay** | Số định danh duy nhất của khoản vay |
| **Ngày đăng ký** | Ngày nộp đơn xin vay |
| **Số tiền** | Số tiền vay (định dạng VND) |
| **Kỳ hạn** | Thời gian vay tính bằng tháng |
| **Lãi suất** | Lãi suất năm (%) |
| **Trả hàng tháng** | Số tiền phải trả mỗi tháng |
| **Trạng thái** | Trạng thái hiện tại của khoản vay |
| **Mục đích** | Mục đích sử dụng khoản vay |

## 🎨 Trạng thái khoản vay

| Trạng thái | Màu sắc | Ý nghĩa |
|------------|---------|---------|
| **Đang chờ duyệt** | 🟡 Cam | Đơn đã nộp, đang chờ xét duyệt |
| **Đã duyệt** | 🟢 Xanh lá | Đơn đã được phê duyệt |
| **Từ chối** | 🔴 Đỏ | Đơn bị từ chối |
| **Đang hoạt động** | 🔵 Xanh dương | Khoản vay đang trong quá trình trả |
| **Đã đóng** | ⚫ Xám | Khoản vay đã được thanh toán hoàn tất |

## 📊 Thông tin tổng quan

Phía dưới bảng có phần tổng quan hiển thị:
- Tổng số khoản vay
- Số khoản vay đang chờ duyệt
- Số khoản vay đã duyệt
- Tổng dư nợ hiện tại

## 🛡️ Bảo mật

- **Khách hàng (USER)**: Chỉ có thể xem khoản vay của chính mình
- **Admin/Manager**: Có thể xem khoản vay của tất cả khách hàng
- Hệ thống tự động kiểm tra quyền truy cập dựa trên JWT token

## 🔧 Các tính năng bổ sung

### Nút hành động
- **➕ Đăng ký vay mới**: Chuyển đến trang đăng ký khoản vay mới
- **← Về trang chủ**: Quay lại Dashboard

### Trạng thái không có dữ liệu
- Hiển thị thông báo khuyến khích khi chưa có khoản vay nào
- Nút "Đăng ký vay ngay" để dễ dàng bắt đầu

### Xử lý lỗi
- Thông báo lỗi chi tiết khi không thể tải dữ liệu
- Nút "Thử lại" để tải lại trang

## 🧪 Test Cases

### Test 1: Hiển thị danh sách khoản vay
1. Đăng nhập với tài khoản có khoản vay
2. Truy cập trang "Khoản vay của tôi"
3. Kiểm tra hiển thị đúng thông tin

### Test 2: Trạng thái không có khoản vay
1. Đăng nhập với tài khoản chưa có khoản vay
2. Truy cập trang "Khoản vay của tôi"
3. Kiểm tra hiển thị thông báo phù hợp

### Test 3: Quyền truy cập
1. Thử truy cập khoản vay của khách hàng khác
2. Kiểm tra thông báo lỗi 403 Forbidden

### Test 4: Navigation
1. Kiểm tra link từ Dashboard
2. Kiểm tra link từ Navigation menu
3. Kiểm tra URL trực tiếp

## 🔗 API Endpoint liên quan

```
GET /api/loans/customer/{customerId}
```

**Headers cần thiết:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Response:**
```json
[
  {
    "id": 1,
    "customerId": 1,
    "amount": 50000000,
    "interestRate": 12.5,
    "termMonths": 24,
    "monthlyPayment": 2500000,
    "status": "APPROVED",
    "applicationDate": "2024-01-15",
    "purpose": "Mua nhà"
  }
]
```

## 🚀 Triển khai

1. **Start Backend:**
   ```bash
   cd kienlongbank-project
   docker-compose up -d
   cd loan-service
   ./mvnw spring-boot:run
   ```

2. **Start Frontend:**
   ```bash
   cd klb-frontend
   npm start
   ```

3. **Truy cập:**
   - Frontend: http://localhost:3000
   - My Loans Page: http://localhost:3000/loans/my-loans

## 📞 Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra backend có đang chạy
2. Kiểm tra JWT token có hợp lệ
3. Kiểm tra console browser để xem lỗi chi tiết
4. Kiểm tra logs backend để debug API
