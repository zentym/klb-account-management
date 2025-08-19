# Protected Routes & Router Implementation

## 📝 Tổng quan

Dự án đã được cấu trúc lại với hệ thống routing hoàn chỉnh sử dụng React Router DOM và Protected Routes để bảo vệ các trang theo quyền người dùng.

## 🔐 ProtectedRoute Component

### Tính năng:
- **Xác thực**: Kiểm tra người dùng đã đăng nhập chưa
- **Phân quyền**: Kiểm tra role của người dùng có phù hợp không
- **Auto Redirect**: Tự động chuyển hướng đến trang login nếu chưa xác thực
- **Loading State**: Hiển thị trạng thái loading khi kiểm tra quyền
- **Error Handling**: Hiển thị thông báo lỗi khi không có quyền truy cập

### Cách sử dụng:

```tsx
import ProtectedRoute from './components/ProtectedRoute';

// Bảo vệ route không cần role cụ thể
<ProtectedRoute>
  <YourComponent />
</ProtectedRoute>

// Bảo vệ route với role cụ thể
<ProtectedRoute requiredRoles={['ADMIN']}>
  <AdminComponent />
</ProtectedRoute>
```

## 🛣️ Router Structure

### Public Routes (không cần đăng nhập):
- `/login` - Trang đăng nhập
- `/register` - Trang đăng ký

### Protected Routes (cần đăng nhập):
- `/dashboard` - Trang chủ (tất cả roles)
- `/customers` - Quản lý khách hàng (ADMIN only)
- `/transfer` - Chuyển tiền (USER, ADMIN)
- `/transactions` - Lịch sử giao dịch (USER, ADMIN)
- `/admin` - Trang quản trị (ADMIN only)

### Special Routes:
- `/` - Auto redirect đến `/dashboard` hoặc `/login`
- `/*` - 404 page

## 🧭 Navigation Component

### Tính năng:
- **Role-based menu**: Chỉ hiển thị menu phù hợp với role
- **Active state**: Highlight trang hiện tại
- **Responsive**: Tương thích với mobile

### Menu items theo role:

#### USER:
- 🏠 Trang chủ
- 💸 Chuyển tiền  
- 📊 Lịch sử giao dịch

#### ADMIN (có tất cả):
- 👥 Quản lý khách hàng
- ⚙️ Quản trị

## 🏗️ Layout Component

### Tính năng:
- **Header**: Logo, thông tin user, nút logout
- **Backend status**: Hiển thị trạng thái kết nối backend
- **Navigation**: Menu điều hướng (chỉ khi đã login)
- **Main content**: Nội dung trang

## 📁 File Structure

```
src/
├── components/
│   ├── AppRouter.tsx      # Main routing configuration
│   ├── ProtectedRoute.tsx # Route protection logic
│   ├── Navigation.tsx     # Navigation menu
│   ├── Layout.tsx         # Page layout wrapper
│   ├── AuthProvider.tsx   # Authentication context
│   └── ...other components
├── App.tsx               # Main app component
└── index.tsx            # App entry point
```

## 🚀 Cách hoạt động

1. **App.tsx** render `AppRouter`
2. **AppRouter** setup các routes với `BrowserRouter`
3. **ProtectedRoute** kiểm tra authentication & authorization
4. **Layout** wrap nội dung với header & navigation
5. **Navigation** hiển thị menu theo role

## 🔄 Flow hoạt động

### User chưa đăng nhập:
1. Truy cập bất kỳ URL nào
2. ProtectedRoute redirect về `/login`
3. Hiển thị LoginPage trong Layout
4. Sau khi đăng nhập thành công → redirect về URL ban đầu

### User đã đăng nhập:
1. Truy cập protected route
2. ProtectedRoute kiểm tra role
3. Nếu có quyền → hiển thị component
4. Nếu không có quyền → hiển thị thông báo lỗi

## ⚡ Quick Commands

```bash
# Install dependencies
npm install react-router-dom @types/react-router-dom

# Start development server
npm start

# Build for production
npm run build
```

## 🔧 Customization

### Thêm route mới:
1. Thêm route trong `AppRouter.tsx`
2. Wrap với `ProtectedRoute` nếu cần bảo vệ
3. Chỉ định `requiredRoles` nếu cần phân quyền

### Thêm role mới:
1. Cập nhật backend để trả về role mới
2. Thêm role vào `requiredRoles` trong routes
3. Cập nhật Navigation menu items

## 🛡️ Security Features

- ✅ Route protection by authentication
- ✅ Role-based access control  
- ✅ Auto redirect unauthenticated users
- ✅ Prevent access to unauthorized pages
- ✅ Loading states during auth checks
- ✅ Error messages for insufficient permissions

## 📱 Responsive Design

- ✅ Mobile-friendly navigation
- ✅ Flexible layout structure
- ✅ Touch-friendly buttons and menus
