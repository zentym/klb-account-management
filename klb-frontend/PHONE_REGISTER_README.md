# PhoneRegisterPage Component

## Mô tả
Component đăng ký tài khoản bằng số điện thoại cho hệ thống Kienlongbank. Component hỗ trợ đầy đủ quy trình đăng ký từ nhập thông tin đến xác thực OTP.

## Tính năng

### 🔐 Bảo mật & Validation
- ✅ Validation số điện thoại Việt Nam (10-11 chữ số)
- ✅ Validation mật khẩu (tối thiểu 6 ký tự)
- ✅ Xác nhận mật khẩu khớp
- ✅ Validation email (optional)
- ✅ Validation họ tên (tối thiểu 2 ký tự)

### 📱 UI/UX
- ✅ Giao diện responsive (mobile-first)
- ✅ Progress indicator 2 bước
- ✅ Animation mượt mà
- ✅ Loading states
- ✅ Error & success messages
- ✅ Toggle hiển thị mật khẩu
- ✅ OTP input với format đẹp

### 📞 Xác thực OTP
- ✅ Mô phỏng gửi OTP qua SMS
- ✅ Input OTP 6 chữ số
- ✅ Đếm ngược thời gian (120 giây)
- ✅ Tính năng gửi lại OTP
- ✅ Validation OTP

### 🎨 Thiết kế
- ✅ Gradient background
- ✅ Card-based layout
- ✅ Icon và emoji
- ✅ Color scheme nhất quán
- ✅ Accessibility support

## Cài đặt

### Dependencies
Component sử dụng các dependencies có sẵn trong project:
- React 19+
- TypeScript
- CSS Modules (optional)

### Files
```
src/
├── components/
│   ├── PhoneRegisterPage.tsx     # Main component
│   ├── PhoneRegisterPage.css     # Styles
│   ├── PhoneRegisterDemo.tsx     # Demo wrapper
│   └── PhoneRegisterApp.tsx      # Standalone app
├── index-phone-register.tsx      # Demo entry point
└── phone-register-demo.html      # Static demo page
```

## Sử dụng

### Basic Usage
```tsx
import React from 'react';
import { PhoneRegisterPage } from './components/PhoneRegisterPage';

function App() {
  const handleRegisterSuccess = (userData: any) => {
    console.log('User registered:', userData);
    // Redirect to login or dashboard
  };

  const handleSwitchToLogin = () => {
    // Navigate to login page
  };

  return (
    <PhoneRegisterPage
      onRegisterSuccess={handleRegisterSuccess}
      onSwitchToLogin={handleSwitchToLogin}
    />
  );
}
```

### Props Interface
```tsx
interface PhoneRegisterPageProps {
  onRegisterSuccess?: (userData: any) => void;
  onSwitchToLogin?: () => void;
}

interface UserData {
  phoneNumber: string;
  fullName: string;
  email?: string;
  registeredAt: string;
}
```

## Demo

### Chạy Demo
```bash
# Cách 1: Sử dụng script PowerShell
.\start-phone-register-demo.ps1

# Cách 2: Manual
# Backup index.tsx hiện tại
cp src/index.tsx src/index.tsx.backup

# Sử dụng demo index
cp src/index-phone-register.tsx src/index.tsx

# Start development server
npm start

# Restore sau khi demo
cp src/index.tsx.backup src/index.tsx
```

### Quy trình Demo
1. **Bước 1: Nhập thông tin**
   - Số điện thoại (format VN)
   - Họ và tên
   - Email (optional)
   - Mật khẩu và xác nhận
   - Đồng ý điều khoản

2. **Bước 2: Xác thực OTP**
   - Nhập mã OTP 6 chữ số
   - Đếm ngược 2 phút
   - Có thể gửi lại OTP

3. **Thành công**
   - Hiển thị thông báo thành công
   - Chuyển hướng đến login/dashboard

## Tùy chỉnh

### CSS Variables
```css
:root {
  --primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  --success-color: #28a745;
  --error-color: #dc3545;
  --border-radius: 8px;
  --shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
}
```

### Form Validation
Có thể tùy chỉnh validation rules trong component:
```tsx
// Phone number regex cho Việt Nam
const phoneRegex = /^(\+84|0)(3[2-9]|5[6|8|9]|7[0|6-9]|8[1-6|8|9]|9[0-9])[0-9]{7}$/;

// Password minimum length
const MIN_PASSWORD_LENGTH = 6;

// Name minimum length
const MIN_NAME_LENGTH = 2;
```

## API Integration

### Backend Endpoints (Cần implement)
```typescript
// Gửi OTP
POST /api/auth/send-otp
{
  "phoneNumber": "0901234567"
}

// Xác thực OTP và tạo tài khoản
POST /api/auth/register
{
  "phoneNumber": "0901234567",
  "otpCode": "123456",
  "fullName": "Nguyễn Văn A",
  "email": "user@example.com",
  "password": "hashedPassword"
}
```

### Service Integration
```tsx
import { authService } from '../services/authService';

// Trong component, thay thế simulateApiCall bằng real API calls
const handleRegisterSubmit = async (e: React.FormEvent) => {
  // ...validation code...
  
  try {
    await authService.sendOtp(formData.phoneNumber);
    setCurrentStep('verify');
  } catch (error) {
    setError('Có lỗi khi gửi OTP');
  }
};
```

## Testing

### Manual Testing Checklist
- [ ] Validation số điện thoại VN
- [ ] Validation các trường bắt buộc
- [ ] UI responsive trên mobile/desktop
- [ ] Animation và loading states
- [ ] OTP flow hoàn chỉnh
- [ ] Error handling
- [ ] Accessibility (keyboard, screen readers)

### Test Cases
1. **Valid Registration**
   - Phone: 0901234567
   - Name: Nguyễn Văn A
   - Password: 123456
   - Expected: OTP sent successfully

2. **Invalid Phone Numbers**
   - Empty: ""
   - Invalid format: "123"
   - Foreign number: "+1234567890"
   - Expected: Validation errors

3. **Password Validation**
   - Too short: "123"
   - Mismatch confirmation
   - Expected: Validation errors

## Roadmap

### Phase 1 (Completed) ✅
- [x] Basic registration form
- [x] Phone number validation
- [x] OTP simulation
- [x] Responsive design
- [x] Error handling

### Phase 2 (Future)
- [ ] Real API integration
- [ ] SMS OTP service
- [ ] Captcha verification
- [ ] Social login options
- [ ] Multi-language support

### Phase 3 (Future)
- [ ] Biometric verification
- [ ] 2FA setup
- [ ] Account verification email
- [ ] Terms & conditions popup

## Troubleshooting

### Common Issues

**1. CSS không load**
```bash
# Đảm bảo import CSS file
import './PhoneRegisterPage.css';
```

**2. Animation không mượt trên mobile**
```css
/* Thêm vào CSS */
* {
  -webkit-transform: translateZ(0);
  transform: translateZ(0);
}
```

**3. Input focus trên iOS**
```css
.form-input {
  font-size: 16px; /* Prevent zoom */
}
```

### Browser Support
- Chrome 88+
- Firefox 85+
- Safari 14+
- Edge 88+

## License
MIT License - See project root for details.

## Liên hệ
- Developer: GitHub Copilot
- Project: KLB Account Management
- Version: 1.0.0
