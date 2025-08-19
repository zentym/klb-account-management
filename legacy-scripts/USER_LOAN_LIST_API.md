# Tài liệu API User - Xem danh sách khoản vay

## Tổng quan
API này cho phép người dùng xem danh sách tất cả các khoản vay mà họ đã đăng ký.

## Endpoint
```
GET /api/loans/customer/{customerId}
```

## Bảo mật
- **Quyền truy cập**: 
  - `ROLE_customer`: Chỉ có thể xem khoản vay của chính mình
  - `ROLE_admin`: Có thể xem khoản vay của bất kỳ khách hàng nào
  - `ROLE_manager`: Có thể xem khoản vay của bất kỳ khách hàng nào
- **Xác thực**: JWT Token trong header `Authorization: Bearer <token>`
- **Bảo vệ dữ liệu**: Customer chỉ có thể truy cập dữ liệu của chính mình

## Path Parameters
- `customerId` (Long): ID của khách hàng cần xem danh sách khoản vay

## Response
### Thành công (200 OK)
```json
[
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
  },
  {
    "id": 2,
    "customerId": 123,
    "amount": 30000000.0,
    "interestRate": 9.0,
    "term": 12,
    "status": "PENDING",
    "applicationDate": "2025-08-05T09:00:00",
    "approvalDate": null,
    "approvedBy": null,
    "rejectReason": null
  }
]
```

**Lưu ý**: Danh sách được sắp xếp theo thứ tự `applicationDate` giảm dần (khoản vay mới nhất sẽ hiển thị đầu tiên).

## Ví dụ sử dụng

### 1. Customer xem danh sách khoản vay của chính mình
```bash
curl -X GET "http://localhost:8082/api/loans/customer/123" \
  -H "Authorization: Bearer <customer_token>"
```

### 2. Admin xem danh sách khoản vay của một khách hàng
```bash
curl -X GET "http://localhost:8082/api/loans/customer/123" \
  -H "Authorization: Bearer <admin_token>"
```

## Xử lý lỗi

### 1. Không có quyền truy cập (403 Forbidden)
```json
{
  "error": "Bạn chỉ có thể xem các khoản vay của chính mình"
}
```

### 2. Token không hợp lệ (401 Unauthorized)
```json
{
  "timestamp": "2025-08-05T14:30:00.123Z",
  "status": 401,
  "error": "Unauthorized",
  "path": "/api/loans/customer/123"
}
```

### 3. Lỗi hệ thống (500 Internal Server Error)
```json
{
  "error": "Lỗi hệ thống khi lấy danh sách khoản vay"
}
```

## Tích hợp với Frontend

### JavaScript/React Example
```javascript
// Function để lấy danh sách khoản vay
async function getCustomerLoans(customerId) {
  try {
    const response = await fetch(`/api/loans/customer/${customerId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${getAuthToken()}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Có lỗi xảy ra');
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error fetching customer loans:', error);
    throw error;
  }
}

// Component hiển thị danh sách khoản vay
function LoanList({ customerId }) {
  const [loans, setLoans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    getCustomerLoans(customerId)
      .then(setLoans)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [customerId]);
  
  if (loading) return <div>Đang tải...</div>;
  if (error) return <div>Lỗi: {error.message}</div>;
  
  return (
    <div className="loan-list">
      <h2>Danh sách khoản vay</h2>
      {loans.length === 0 ? (
        <p>Bạn chưa có khoản vay nào.</p>
      ) : (
        <ul>
          {loans.map(loan => (
            <li key={loan.id} className="loan-item">
              <div className="loan-details">
                <p><strong>Số tiền:</strong> {loan.amount.toLocaleString()} VND</p>
                <p><strong>Lãi suất:</strong> {loan.interestRate}%</p>
                <p><strong>Kỳ hạn:</strong> {loan.term} tháng</p>
                <p><strong>Trạng thái:</strong> 
                  <span className={`status ${loan.status.toLowerCase()}`}>
                    {getStatusText(loan.status)}
                  </span>
                </p>
                <p><strong>Ngày đăng ký:</strong> {formatDate(loan.applicationDate)}</p>
                {loan.approvalDate && (
                  <p><strong>Ngày phê duyệt:</strong> {formatDate(loan.approvalDate)}</p>
                )}
                {loan.rejectReason && (
                  <p><strong>Lý do từ chối:</strong> {loan.rejectReason}</p>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

// Helper functions
function getStatusText(status) {
  const statusMap = {
    'PENDING': 'Đang chờ phê duyệt',
    'APPROVED': 'Đã phê duyệt',
    'REJECTED': 'Đã từ chối',
    'DISBURSED': 'Đã giải ngân',
    'CLOSED': 'Đã đóng'
  };
  return statusMap[status] || status;
}

function formatDate(dateString) {
  return new Date(dateString).toLocaleDateString('vi-VN');
}
```

## Trạng thái khoản vay
- `PENDING`: Đang chờ phê duyệt
- `APPROVED`: Đã phê duyệt
- `REJECTED`: Đã từ chối
- `DISBURSED`: Đã giải ngân
- `CLOSED`: Đã đóng

## Phân quyền chi tiết

### Customer Role
- Chỉ có thể xem các khoản vay của chính mình
- Token phải chứa `customer_id` hoặc `sub` khớp với `customerId` trong URL

### Admin/Manager Role
- Có thể xem khoản vay của bất kỳ khách hàng nào
- Không bị giới hạn bởi `customerId` trong token

## Monitoring và Logging
- Tất cả requests đều được log với level INFO
- Cảnh báo về vi phạm bảo mật được log với level WARN
- Errors được log với level ERROR
- Thông tin số lượng khoản vay trả về được ghi log

## Testing

### Script PowerShell
```powershell
# test-user-loan-list.ps1

# Test customer xem khoản vay của chính mình
$customerToken = "eyJ..." # Customer JWT token
$customerId = 123

$response = Invoke-RestMethod -Uri "http://localhost:8082/api/loans/customer/$customerId" `
  -Method GET `
  -Headers @{
    "Authorization" = "Bearer $customerToken"
    "Content-Type" = "application/json"
  }

Write-Host "Customer loans:" -ForegroundColor Green
$response | ConvertTo-Json -Depth 3

# Test customer cố gắng xem khoản vay của người khác (nên bị từ chối)
$otherCustomerId = 456
try {
  $response = Invoke-RestMethod -Uri "http://localhost:8082/api/loans/customer/$otherCustomerId" `
    -Method GET `
    -Headers @{
      "Authorization" = "Bearer $customerToken"
      "Content-Type" = "application/json"
    }
} catch {
  Write-Host "Access denied (expected): $($_.Exception.Message)" -ForegroundColor Yellow
}
```

## Tích hợp với các API khác
- Có thể kết hợp với API `/api/loans/{loanId}` để xem chi tiết từng khoản vay
- Kết hợp với API đăng ký khoản vay `/api/loans/apply` để tạo khoản vay mới
- Admin có thể sử dụng kết hợp với API cập nhật trạng thái `/api/loans/{loanId}/status`
