#!/usr/bin/env pwsh
# Tổng hợp vấn đề Role và cách giải quyết

Write-Host "🎯 KLB Banking System - Role Issue Analysis & Solutions" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

Write-Host "`n📊 Current Situation Analysis:" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow

Write-Host "`n✅ What's Working:" -ForegroundColor Green
Write-Host "   - Keycloak is running and accessible at http://localhost:8090" -ForegroundColor White
Write-Host "   - Kienlongbank realm has been created" -ForegroundColor White
Write-Host "   - klb-frontend client is configured" -ForegroundColor White
Write-Host "   - testuser exists and can login" -ForegroundColor White
Write-Host "   - JWT tokens are being generated correctly" -ForegroundColor White
Write-Host "   - ADMIN and USER roles have been created in Keycloak" -ForegroundColor White
Write-Host "   - Spring Boot service is configured with correct JWT issuer URI" -ForegroundColor White

Write-Host "`n❌ What's NOT Working:" -ForegroundColor Red
Write-Host "   - testuser does NOT have ADMIN role assigned" -ForegroundColor White
Write-Host "   - JWT tokens contain only default Keycloak roles" -ForegroundColor White
Write-Host "   - API calls to /api/admin/** return 401 Unauthorized" -ForegroundColor White
Write-Host "   - Programmatic role assignment fails with 400 Bad Request" -ForegroundColor White

Write-Host "`n🔍 Current User Roles (from JWT):" -ForegroundColor Blue
Write-Host "   - default-roles-kienlongbank" -ForegroundColor Gray
Write-Host "   - offline_access" -ForegroundColor Gray
Write-Host "   - uma_authorization" -ForegroundColor Gray
Write-Host "   - manage-account (client role)" -ForegroundColor Gray
Write-Host "   - manage-account-links (client role)" -ForegroundColor Gray
Write-Host "   - view-profile (client role)" -ForegroundColor Gray

Write-Host "`n🎯 Required for Admin Access:" -ForegroundColor Yellow
Write-Host "   - ADMIN role in realm_access.roles in JWT token" -ForegroundColor White
Write-Host "   - Spring Security expects ROLE_ADMIN authority" -ForegroundColor White

Write-Host "`n🛠️ SOLUTIONS (trong thứ tự ưu tiên):" -ForegroundColor Cyan
Write-Host "=====================================/" -ForegroundColor Cyan

Write-Host "`n1. 🌐 MANUAL KEYCLOAK ASSIGNMENT (RECOMMENDED):" -ForegroundColor Green
Write-Host "   Steps:" -ForegroundColor Yellow
Write-Host "   a) Mở trình duyệt: http://localhost:8090" -ForegroundColor White
Write-Host "   b) Login: admin / admin" -ForegroundColor White
Write-Host "   c) Switch to 'Kienlongbank' realm (dropdown top-left)" -ForegroundColor White
Write-Host "   d) Go to: Users → View all users → Click 'testuser'" -ForegroundColor White
Write-Host "   e) Tab 'Role Mappings'" -ForegroundColor White
Write-Host "   f) In 'Available Roles', find 'ADMIN' và click 'Add selected'" -ForegroundColor White
Write-Host "   g) Verify 'ADMIN' appears in 'Assigned Roles'" -ForegroundColor White

Write-Host "`n2. 🔄 ALTERNATIVE - Reset và Recreate User:" -ForegroundColor Blue
Write-Host "   Nếu role assignment vẫn không work, delete user và tạo lại:" -ForegroundColor White
Write-Host "   - Delete testuser trong Keycloak" -ForegroundColor Gray
Write-Host "   - Chạy lại setup script" -ForegroundColor Gray
Write-Host "   - Manually assign ADMIN role ngay sau khi tạo" -ForegroundColor Gray

Write-Host "`n3. 🎯 CREATE NEW ADMIN USER:" -ForegroundColor Blue
Write-Host "   Tạo user mới với ADMIN role từ đầu" -ForegroundColor White

Write-Host "`n🧪 Testing Steps:" -ForegroundColor Yellow
Write-Host "================/" -ForegroundColor Yellow

Write-Host "`nSau khi assign ADMIN role thành công:" -ForegroundColor White
Write-Host "1. Test JWT token: powershell -ExecutionPolicy Bypass -File check-user-roles.ps1" -ForegroundColor Gray
Write-Host "2. Verify token contains ADMIN in realm_access.roles" -ForegroundColor Gray
Write-Host "3. Test admin API: Should return 200 instead of 401" -ForegroundColor Gray

Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Yellow
Write-Host "==================" -ForegroundColor Yellow

Write-Host "`nNếu vẫn gặp issues:" -ForegroundColor White
Write-Host "1. Clear browser cache/logout and login again" -ForegroundColor Gray
Write-Host "2. Restart Spring Boot services: docker-compose restart account-management" -ForegroundColor Gray
Write-Host "3. Check Keycloak logs: docker logs klb-keycloak" -ForegroundColor Gray
Write-Host "4. Check Spring Boot logs: docker logs klb-account-management" -ForegroundColor Gray

Write-Host "`n🎉 Expected Result:" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green

Write-Host "Sau khi fix successfully:" -ForegroundColor White
Write-Host "✅ JWT token sẽ chứa: realm_access.roles = ['ADMIN', 'default-roles-kienlongbank', ...]" -ForegroundColor Green
Write-Host "✅ API call tới /api/admin/hello sẽ return: 'Hello, Admin testuser!...'" -ForegroundColor Green
Write-Host "✅ Status code: 200 OK thay vì 401 Unauthorized" -ForegroundColor Green

Write-Host "`n🚀 Quick Action Items:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

Write-Host "1. Mở Keycloak Admin Console ngay bây giờ:" -ForegroundColor Yellow
Write-Host "   http://localhost:8090" -ForegroundColor White

Write-Host "`n2. Assign ADMIN role manually như hướng dẫn trên" -ForegroundColor Yellow

Write-Host "`n3. Test lại bằng:" -ForegroundColor Yellow
Write-Host "   powershell -ExecutionPolicy Bypass -File check-user-roles.ps1" -ForegroundColor White

Write-Host "`n💡 Pro Tip:" -ForegroundColor Blue
Write-Host "Keycloak Web Admin Console là cách dễ nhất và reliable nhất để manage roles!" -ForegroundColor Gray

Write-Host "`n🔗 Useful URLs:" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "Keycloak Admin: http://localhost:8090" -ForegroundColor White
Write-Host "Account Management API: http://localhost:8080/swagger-ui/index.html" -ForegroundColor White
Write-Host "Customer Service API: http://localhost:8082/swagger-ui/index.html" -ForegroundColor White
Write-Host "React Frontend: http://localhost:3000 (when running)" -ForegroundColor White
