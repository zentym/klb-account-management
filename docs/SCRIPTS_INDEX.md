# Scripts Index - KLB Account Management

## 🚀 Scripts Thiết lập (Setup)

| Script | Mô tả | Cách sử dụng |
|--------|-------|--------------|
| `setup-keycloak.ps1` | Thiết lập Keycloak server | `.\scripts\setup\setup-keycloak.ps1` |
| `setup-keycloak.sh` | Thiết lập Keycloak (Linux) | `bash scripts/setup/setup-keycloak.sh` |
| `setup-keycloak-phone.ps1` | Thiết lập đăng nhập phone | `.\scripts\setup\setup-keycloak-phone.ps1` |
| `setup-customer-data.ps1` | Thiết lập dữ liệu khách hàng | `.\scripts\setup\setup-customer-data.ps1` |
| `setup-customer-data-via-gateway.ps1` | Thiết lập qua API Gateway | `.\scripts\setup\setup-customer-data-via-gateway.ps1` |
| `setup-direct-grant.ps1` | Thiết lập direct grant flow | `.\scripts\setup\setup-direct-grant.ps1` |
| `create-admin-user.ps1` | Tạo user admin | `.\scripts\setup\create-admin-user.ps1` |
| `create-customer-mapping.ps1` | Tạo customer mapping | `.\scripts\setup\create-customer-mapping.ps1` |
| `create-test-user-and-test-api.ps1` | Tạo user test và test API | `.\scripts\setup\create-test-user-and-test-api.ps1` |

## 🧪 Scripts Kiểm tra (Testing)

| Script | Mô tả | Cách sử dụng |
|--------|-------|--------------|
| `test-auth-flow.ps1` | Test luồng xác thực | `.\scripts\test\test-auth-flow.ps1` |
| `test-api-gateway-user-info.ps1` | Test API Gateway user info | `.\scripts\test\test-api-gateway-user-info.ps1` |
| `test-my-info-api.ps1` | Test My Info API | `.\scripts\test\test-my-info-api.ps1` |
| `test-direct-grant.ps1` | Test direct grant flow | `.\scripts\test\test-direct-grant.ps1` |
| `final-test-my-info.ps1` | Test cuối cùng My Info | `.\scripts\test\final-test-my-info.ps1` |
| `ultimate-test-my-info.ps1` | Test toàn diện My Info | `.\scripts\test\ultimate-test-my-info.ps1` |
| `comprehensive-user-permission-check.ps1` | Kiểm tra quyền user | `.\scripts\test\comprehensive-user-permission-check.ps1` |
| `performance-test.js` | Test hiệu suất | `node scripts/test/performance-test.js` |

## 🐛 Scripts Debug

| Script | Mô tả | Cách sử dụng |
|--------|-------|--------------|
| `debug-jwt-token.ps1` | Debug JWT token | `.\scripts\debug\debug-jwt-token.ps1` |
| `debug-jwt-config.ps1` | Debug JWT config | `.\scripts\debug\debug-jwt-config.ps1` |
| `debug-token.ps1` | Debug token general | `.\scripts\debug\debug-token.ps1` |
| `debug-api-gateway.ps1` | Debug API Gateway | `.\scripts\debug\debug-api-gateway.ps1` |
| `verify-keycloak.ps1` | Kiểm tra Keycloak | `.\scripts\debug\verify-keycloak.ps1` |

## 🛠️ Scripts Tiện ích (Utilities)

### Quản lý Roles
| Script | Mô tả |
|--------|-------|
| `check-user-roles.ps1` | Kiểm tra roles của user |
| `fix-user-role.ps1` | Sửa role của user |
| `fix-user-roles.ps1` | Sửa roles của users |
| `alternative-role-fix.ps1` | Sửa role cách khác |
| `manual-role-fix.ps1` | Sửa role thủ công |
| `recreate-user-with-role.ps1` | Tạo lại user với role |

### Quản lý Hệ thống
| Script | Mô tả |
|--------|-------|
| `start-react-dev.ps1` | Start React development |
| `start-react.ps1` | Start React production |
| `restart-react-with-proxy.ps1` | Restart React với proxy |
| `start-custom-login-demo.ps1` | Start demo custom login |
| `start-chrome-no-cors.ps1` | Start Chrome no CORS |

### Dọn dẹp
| Script | Mô tả |
|--------|-------|
| `cleanup-all.ps1` | Dọn dẹp toàn bộ |
| `cleanup-unnecessary-files.ps1` | Dọn dẹp file không cần |
| `safe-cleanup.ps1` | Dọn dẹp an toàn |
| `quick-cleanup.ps1` | Dọn dẹp nhanh |
| `final-cleanup.ps1` | Dọn dẹp cuối cùng |

### Khác
| Script | Mô tả |
|--------|-------|
| `check-status.ps1` | Kiểm tra trạng thái hệ thống |
| `monitor-build.ps1` | Theo dõi build |
| `reset-project.ps1` | Reset dự án |
| `integrate-react-login.ps1` | Tích hợp React login |
| `quick-api-test.ps1` | Test API nhanh |
| `quick-test-customer.ps1` | Test customer nhanh |

## 📁 Cấu trúc Scripts

```
scripts/
├── setup/          # Thiết lập hệ thống
├── test/           # Kiểm tra và test
├── debug/          # Debug và troubleshoot
└── utilities/      # Tiện ích và quản lý
```

## 💡 Gợi ý sử dụng

1. **Thiết lập lần đầu:** Chạy các script trong `setup/` theo thứ tự
2. **Development:** Sử dụng các script trong `utilities/` để start/stop services
3. **Testing:** Chạy các script trong `test/` để kiểm tra chức năng
4. **Troubleshooting:** Sử dụng các script trong `debug/` khi gặp vấn đề
