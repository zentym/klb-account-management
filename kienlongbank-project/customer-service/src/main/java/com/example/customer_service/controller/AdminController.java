package com.example.customer_service.controller;

import com.kienlongbank.common.dto.ApiResponse;
import com.example.customer_service.model.Customer;
import com.example.customer_service.service.CustomerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Admin Controller for Customer Service
 * Provides administrative endpoints that require ADMIN role
 */
@RestController
@RequestMapping("/api/admin")
@Tag(name = "Admin Management", description = "Administrative endpoints requiring ADMIN role")
@SecurityRequirement(name = "bearerAuth")
@RequiredArgsConstructor
public class AdminController {

    private final CustomerService customerService;

    @GetMapping("/hello")
    @Operation(summary = "Admin hello endpoint", description = "Test endpoint for admin authentication")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ApiResponse<Map<String, Object>> adminHello(Authentication authentication) {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Hello, Admin " + authentication.getName() + "!");
        response.put("timestamp", LocalDateTime.now());
        response.put("service", "customer-service");
        response.put("authorities", authentication.getAuthorities());
        
        return ApiResponse.success(response, "Admin access confirmed for Customer Service");
    }

    @GetMapping("/customers/stats")
    @Operation(summary = "Customer statistics", description = "Get customer statistics (admin only)")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ApiResponse<Map<String, Object>> getCustomerStats() {
        List<Customer> allCustomers = customerService.getAllCustomers();
        
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalCustomers", allCustomers.size());
        stats.put("generatedAt", LocalDateTime.now());
        
        // Additional statistics could be added here
        // e.g., customers by city, age groups, etc.
        
        return ApiResponse.success(stats, "Customer statistics retrieved successfully");
    }

    @DeleteMapping("/customers/{id}/force")
    @Operation(summary = "Force delete customer", description = "Permanently delete a customer (admin only)")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ApiResponse<String> forceDeleteCustomer(@PathVariable Long id, Authentication authentication) {
        // This could be a more privileged delete operation
        // that bypasses normal business rules
        customerService.deleteCustomer(id);
        
        Map<String, Object> auditInfo = new HashMap<>();
        auditInfo.put("action", "FORCE_DELETE_CUSTOMER");
        auditInfo.put("customerId", id);
        auditInfo.put("performedBy", authentication.getName());
        auditInfo.put("timestamp", LocalDateTime.now());
        
        // In a real application, you would log this audit information
        System.out.println("AUDIT: " + auditInfo);
        
        return ApiResponse.success(null, 
            "Customer " + id + " has been permanently deleted by admin " + authentication.getName());
    }

    @GetMapping("/system/info")
    @Operation(summary = "System information", description = "Get detailed system information (admin only)")
    @PreAuthorize("hasAuthority('ADMIN')")
    public ApiResponse<Map<String, Object>> getSystemInfo(Authentication authentication) {
        Map<String, Object> systemInfo = new HashMap<>();
        systemInfo.put("service", "customer-service");
        systemInfo.put("version", "1.0.0");
        systemInfo.put("database", "PostgreSQL");
        systemInfo.put("security", "JWT/OAuth2 with Keycloak");
        systemInfo.put("requestedBy", authentication.getName());
        systemInfo.put("authorities", authentication.getAuthorities());
        systemInfo.put("timestamp", LocalDateTime.now());
        
        // Add JVM info
        Runtime runtime = Runtime.getRuntime();
        Map<String, Object> jvmInfo = new HashMap<>();
        jvmInfo.put("totalMemory", runtime.totalMemory());
        jvmInfo.put("freeMemory", runtime.freeMemory());
        jvmInfo.put("maxMemory", runtime.maxMemory());
        jvmInfo.put("availableProcessors", runtime.availableProcessors());
        systemInfo.put("jvm", jvmInfo);
        
        return ApiResponse.success(systemInfo, "System information retrieved successfully");
    }
}
