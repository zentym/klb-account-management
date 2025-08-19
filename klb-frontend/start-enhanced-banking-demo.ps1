# Enhanced Phone Banking App Demo for KLB Frontend

echo "🚀 Starting Enhanced Phone Banking App Demo..."
echo "📱 Full Banking App với tất cả tính năng"
echo ""

# Backup original index.tsx
if (Test-Path "src\index.tsx") {
    Copy-Item "src\index.tsx" "src\index.tsx.backup" -Force
    echo "✅ Backed up original index.tsx"
}

echo ""
echo "🎯 Enhanced App Features:"
echo "   🔐 Phone Authentication (Register/Login/OTP)"
echo "   📊 Banking Dashboard với mock data"
echo "   💸 Transfer Page - Chuyển tiền"
echo "   📋 Transaction History - Lịch sử giao dịch"
echo "   👤 Customer Profile - Thông tin cá nhân"  
echo "   🏦 Loan Application - Đăng ký vay vốn"
echo "   💰 My Loans - Quản lý khoản vay"
echo "   🆕 Create Account - Mở tài khoản mới"
echo "   🧭 Full Navigation với React Router"
echo ""

echo "📋 Complete App Flow:"
echo "   1. 🔐 Authentication: Register → Login → OTP"
echo "   2. 🏠 Dashboard: Balance, Quick Actions, Recent Transactions"
echo "   3. 💸 Transfer: Chuyển tiền giữa các tài khoản"
echo "   4. 👤 Profile: Xem/cập nhật thông tin cá nhân"
echo "   5. 🏦 Loans: Đăng ký vay và quản lý khoản vay"
echo "   6. 📊 History: Lịch sử giao dịch chi tiết"
echo "   7. 🧭 Navigation: Bottom nav + Quick actions"
echo ""

echo "⚡ Quick Actions Available:"
echo "   • Floating action buttons (bottom-right)"
echo "   • Bottom navigation bar"
echo "   • Page headers with back buttons"
echo "   • Modal overlays cho transaction history"
echo ""

echo "🎨 UI Features:"
echo "   • Responsive design (mobile + desktop)"
echo "   • Modern gradients & animations"
echo "   • Loading states & error handling"
echo "   • Toast notifications"
echo "   • Modal popups"
echo "   • Sticky headers"
echo ""

echo "🌐 Starting development server..."
npm start

# Auto restore on exit (optional)
echo ""
echo "Demo completed. Press any key to restore original files..."
Read-Host "Press Enter to continue"

if (Test-Path "src\index.tsx.backup") {
    Copy-Item "src\index.tsx.backup" "src\index.tsx" -Force
    Remove-Item "src\index.tsx.backup" -Force
    echo "✅ Restored original index.tsx"
}
