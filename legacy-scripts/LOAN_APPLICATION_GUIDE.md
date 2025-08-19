# Hướng dẫn sử dụng tính năng Đăng ký vay

## Tổng quan
Tính năng đăng ký vay cho phép khách hàng nộp đơn xin vay trực tuyến với các thông tin cần thiết.

## Cách truy cập
1. Đăng nhập vào hệ thống Kien Long Bank
2. Trên trang Dashboard, nhấn vào **"💰 Đăng ký vay"** trong phần "Dịch vụ nhanh"
3. Hoặc sử dụng menu điều hướng, nhấn vào **"💰 Đăng ký vay"**
4. Hoặc truy cập trực tiếp qua URL: `/loans/apply`

## Thông tin cần cung cấp

### Thông tin bắt buộc:
- **Số tiền vay**: Từ 1 triệu đến 10 tỷ VND
- **Thời hạn vay**: 6, 12, 24, 36, 48, hoặc 60 tháng
- **Mục đích vay**: Chọn từ danh sách có sẵn (Mua nhà, Mua xe, Kinh doanh, v.v.)
- **Thu nhập hàng tháng**: Tối thiểu 1 triệu VND
- **Trạng thái công việc**: Chọn từ danh sách có sẵn

### Thông tin tùy chọn:
- **Tài sản đảm bảo**: Giá trị và mô tả tài sản (nếu có)

## Quy trình xử lý
1. **Gửi đơn**: Người dùng điền form và nhấn "Gửi đơn vay"
2. **API Call**: Hệ thống gọi `POST /api/loans/apply`
3. **Xác nhận**: Hiển thị thông báo thành công
4. **Chờ duyệt**: Ngân hàng sẽ liên hệ trong 2-3 ngày làm việc

## Tính năng kiểm tra tự động
- **Kiểm tra khả năng thanh toán**: Thu nhập phải ít nhất gấp 3 lần số tiền trả hàng tháng
- **Định dạng tiền tệ**: Tự động hiển thị định dạng VND
- **Tính toán dự kiến**: Hiển thị số tiền trả hàng tháng (chưa bao gồm lãi suất)

## Quyền truy cập
- **USER**: Có thể đăng ký vay cho chính mình
- **ADMIN**: Có thể đăng ký vay và quản lý các đơn vay

## Giao diện thân thiện
- Form responsive, hoạt động tốt trên mobile và desktop
- Validation real-time với thông báo lỗi rõ ràng
- Giao diện trực quan với màu sắc phân biệt rõ ràng
- Hiệu ứng hover và transition mượt mà

## Lưu ý
- Tất cả số tiền được hiển thị theo định dạng VND
- Hệ thống sẽ tự động reset form sau khi gửi thành công
- Có thể quay lại trang trước bằng nút "Quay lại"
- Thông tin người dùng được lấy từ token xác thực

## Xử lý lỗi
- Hiển thị thông báo lỗi rõ ràng khi có vấn đề
- Loading state khi đang gửi đơn
- Validation client-side trước khi gửi đến server
