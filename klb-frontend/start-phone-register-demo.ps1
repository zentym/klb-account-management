# Complete Phone Banking App Demo for KLB Frontend

echo "🚀 Starting Complete Phone Banking App Demo..."
echo "📱 Full App Flow: Register → Login → Dashboard"
echo ""

# Backup original index.tsx
if (Test-Path "src\index.tsx") {
    Copy-Item "src\index.tsx" "src\index.tsx.backup" -Force
    echo "✅ Backed up original index.tsx"
}

# Replace index.tsx with demo version
Copy-Item "src\index-phone-register.tsx" "src\index.tsx" -Force
echo "✅ Replaced index.tsx with demo version"

echo ""
echo "🎯 Complete App Features:"
echo "   📝 Phone Registration with OTP verification"
echo "   🔐 Phone Login with optional OTP"
echo "   📊 Banking Dashboard with mock data"
echo "   💰 Balance display and quick actions"
echo "   📱 Mobile-first responsive design"
echo "   🎨 Modern UI with animations"
echo "   🌙 Dark mode support"
echo ""

echo "📋 Demo Flow:"
echo "   1. Start with Login page (can switch to Register)"
echo "   2. Fill form → OTP verification"
echo "   3. Success → Banking Dashboard"
echo "   4. View balance, transactions, profile"
echo "   5. Logout to return to auth flow"
echo ""

echo "🌐 Starting development server..."
npm start
