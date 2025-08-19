# Test API cho Admin - Cập nhật trạng thái khoản vay

## 1. Phê duyệt khoản vay (APPROVED)
```bash
curl -X POST "http://localhost:8082/api/loans/1/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  -d '{
    "status": "APPROVED"
  }'
```

## 2. Từ chối khoản vay (REJECTED)
```bash
curl -X POST "http://localhost:8082/api/loans/1/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  -d '{
    "status": "REJECTED",
    "reason": "Thu nhập không đủ điều kiện"
  }'
```

## 3. Cập nhật sang trạng thái đã giải ngân (DISBURSED)
```bash
curl -X POST "http://localhost:8082/api/loans/1/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  -d '{
    "status": "DISBURSED"
  }'
```

## 4. Đóng khoản vay (CLOSED)
```bash
curl -X POST "http://localhost:8082/api/loans/1/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  -d '{
    "status": "CLOSED"
  }'
```

## Các trạng thái hợp lệ:
- PENDING: Đang chờ phê duyệt
- APPROVED: Đã phê duyệt
- REJECTED: Đã từ chối
- DISBURSED: Đã giải ngân
- CLOSED: Đã đóng

## Lưu ý bảo mật:
- Chỉ ADMIN mới có quyền sử dụng endpoint này
- JWT token phải có role "admin"
- Khi từ chối (REJECTED), bắt buộc phải có lý do
