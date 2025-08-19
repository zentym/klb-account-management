package com.example.customer_service.controller;

import com.kienlongbank.common.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Health Check Controller for Customer Service
 * Provides endpoints for monitoring service health
 */
@RestController
@RequestMapping("/api")
@Tag(name = "Health Check", description = "Health monitoring endpoints")
public class HealthCheckController {

    @GetMapping("/health")
    @Operation(summary = "Health check", description = "Check if the customer service is running properly")
    public ApiResponse<Map<String, Object>> health() {
        Map<String, Object> healthData = new HashMap<>();
        healthData.put("status", "UP");
        healthData.put("service", "customer-service");
        healthData.put("timestamp", LocalDateTime.now());
        healthData.put("version", "1.0.0");
        
        return ApiResponse.success(healthData, "Customer Service is running healthy");
    }

    @GetMapping("/info")
    @Operation(summary = "Service info", description = "Get information about the customer service")
    public ApiResponse<Map<String, Object>> info() {
        Map<String, Object> serviceInfo = new HashMap<>();
        serviceInfo.put("name", "KLB Customer Service");
        serviceInfo.put("description", "Microservice for managing customer data");
        serviceInfo.put("version", "1.0.0");
        serviceInfo.put("built-by", "KienLongBank Team");
        serviceInfo.put("database", "PostgreSQL");
        serviceInfo.put("security", "JWT/OAuth2 with Keycloak");
        
        return ApiResponse.success(serviceInfo, "Service information retrieved successfully");
    }
}
