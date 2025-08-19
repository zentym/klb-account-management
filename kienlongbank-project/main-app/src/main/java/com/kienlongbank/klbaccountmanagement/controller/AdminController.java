package com.kienlongbank.klbaccountmanagement.controller;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controller cho các API dành riêng cho Admin
 * Chỉ có user với role ADMIN mới có thể truy cập
 */
@RestController
@RequestMapping("/api/admin")
@CrossOrigin(originPatterns = "*", allowCredentials = "true")
public class AdminController {

    /**
     * API kiểm tra quyền admin
     * @return Thông báo chào mừng admin
     */
    @GetMapping("/hello")
    public String sayHelloAdmin() {
        // Lấy thông tin user hiện tại từ SecurityContext
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        
        return "Hello, Admin " + username + "! Bạn có quyền truy cập vào khu vực Admin.";
    }

    /**
     * API lấy thông tin dashboard admin
     * @return Thông tin dashboard
     */
    @GetMapping("/dashboard")
    public String getAdminDashboard() {
        return "🎛️ Admin Dashboard - Quản lý toàn bộ hệ thống KLB Account Management";
    }

    /**
     * API lấy thống kê hệ thống (demo)
     * @return Thống kê hệ thống
     */
    @GetMapping("/stats")
    public String getSystemStats() {
        return "📊 System Statistics:\n" +
               "- Total Users: 150\n" +
               "- Total Customers: 1,250\n" +
               "- Total Transactions: 5,480\n" +
               "- System Status: ✅ Healthy";
    }

    /**
     * API kiểm tra quyền và authorities của user hiện tại
     * @return Thông tin chi tiết về quyền
     */
    @GetMapping("/check-permissions")
    public String checkPermissions() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        
        StringBuilder info = new StringBuilder();
        info.append("🔐 Current User Permissions:\n");
        info.append("Username: ").append(authentication.getName()).append("\n");
        info.append("Authenticated: ").append(authentication.isAuthenticated()).append("\n");
        info.append("Authorities: ");
        
        authentication.getAuthorities().forEach(authority -> 
            info.append(authority.getAuthority()).append(" ")
        );
        
        info.append("\nPrincipal Type: ").append(authentication.getPrincipal().getClass().getSimpleName());
        
        return info.toString();
    }
}
