# Tài liệu API Admin - Cập nhật trạng thái khoản vay

## Tổng quan
API này cho phép Admin cập nhật trạng thái của một khoản vay thông qua một endpoint thống nhất.

## Endpoint
```
POST /api/loans/{loanId}/status
```

## Bảo mật
- **Quyền truy cập**: Chỉ dành cho ADMIN (`ROLE_admin`)
- **Xác thực**: JWT Token trong header `Authorization: Bearer <token>`
- **Bảo vệ ở 2 tầng**:
  1. URL-based security trong `SecurityConfig`
  2. Method-based security với `@PreAuthorize("hasRole('admin')")`

## Request Body
```json
{
  "status": "string",     // Bắt buộc - Trạng thái mới
  "reason": "string"      // Tùy chọn - Lý do (bắt buộc khi status = "REJECTED")
}
```

## Các trạng thái hợp lệ
- `PENDING`: Đang chờ phê duyệt
- `APPROVED`: Đã phê duyệt  
- `REJECTED`: Đã từ chối (yêu cầu lý do)
- `DISBURSED`: Đã giải ngân
- `CLOSED`: Đã đóng

## Quy tắc chuyển đổi trạng thái
1. Chỉ có thể cập nhật từ `PENDING` sang `APPROVED`/`REJECTED`
2. Có thể chuyển sang `DISBURSED` từ `APPROVED`
3. Có thể chuyển sang `CLOSED` từ `DISBURSED`
4. Khi `REJECTED`, bắt buộc phải có `reason`

## Ví dụ sử dụng

### 1. Phê duyệt khoản vay
```bash
curl -X POST "http://localhost:8082/api/loans/1/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin_token>" \
  -d '{
    "status": "APPROVED"
  }'
```

**Response:**
```json
{
  "id": 1,
  "customerId": 123,
  "amount": 50000000.0,
  "interestRate": 8.5,
  "term": 24,
  "status": "APPROVED",
  "applicationDate": "2025-08-05T10:30:00",
  "approvalDate": "2025-08-05T14:30:00",
  "approvedBy": "admin_user_id",
  "rejectReason": null
}
```

### 2. Từ chối khoản vay
```bash
curl -X POST "http://localhost:8082/api/loans/2/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin_token>" \
  -d '{
    "status": "REJECTED",
    "reason": "Thu nhập không đủ điều kiện vay theo quy định ngân hàng"
  }'
```

**Response:**
```json
{
  "id": 2,
  "customerId": 124,
  "amount": 100000000.0,
  "interestRate": 9.0,
  "term": 36,
  "status": "REJECTED",
  "applicationDate": "2025-08-05T09:00:00",
  "approvalDate": null,
  "approvedBy": "admin_user_id",
  "rejectReason": "Thu nhập không đủ điều kiện vay theo quy định ngân hàng"
}
```

### 3. Cập nhật sang trạng thái đã giải ngân
```bash
curl -X POST "http://localhost:8082/api/loans/1/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin_token>" \
  -d '{
    "status": "DISBURSED"
  }'
```

## Xử lý lỗi

### 1. Không có quyền truy cập (403 Forbidden)
```json
{
  "timestamp": "2025-08-05T14:30:00.123Z",
  "status": 403,
  "error": "Forbidden",
  "path": "/api/loans/1/status"
}
```

### 2. Trạng thái không hợp lệ (400 Bad Request)
```json
{
  "error": "Trạng thái không hợp lệ: INVALID_STATUS"
}
```

### 3. Thiếu lý do từ chối (400 Bad Request)
```json
{
  "error": "Lý do từ chối không được để trống"
}
```

### 4. Khoản vay không tồn tại (400 Bad Request)
```json
{
  "error": "Không tìm thấy khoản vay"
}
```

### 5. Không thể cập nhật trạng thái (400 Bad Request)
```json
{
  "error": "Chỉ có thể cập nhật trạng thái cho khoản vay đang chờ xử lý"
}
```

## Tích hợp với hệ thống

### Frontend Integration
```javascript
// Function để gọi API cập nhật trạng thái
async function updateLoanStatus(loanId, status, reason = null) {
  try {
    const response = await fetch(`/api/loans/${loanId}/status`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${getAdminToken()}`
      },
      body: JSON.stringify({
        status: status,
        reason: reason
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Có lỗi xảy ra');
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error updating loan status:', error);
    throw error;
  }
}

// Sử dụng
updateLoanStatus(1, 'APPROVED')
  .then(updatedLoan => console.log('Loan approved:', updatedLoan))
  .catch(error => console.error('Failed to approve loan:', error));
```

## Monitoring và Logging
- Tất cả requests đều được log với level INFO
- Errors được log với level ERROR
- JWT token được validate trước khi xử lý
- Thông tin user được lưu trong trường `approvedBy`

## Testing
- Unit tests có trong `LoanControllerUpdateStatusTest.java`
- Integration tests có thể chạy với script `test-admin-loan-status.ps1`
- Manual testing với file `test-admin-loan-status-api.md`
