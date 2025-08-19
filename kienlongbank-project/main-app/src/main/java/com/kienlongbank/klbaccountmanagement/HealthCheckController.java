package com.kienlongbank.klbaccountmanagement;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@Tag(name = "Health Check", description = "System health monitoring")
public class HealthCheckController {

    @GetMapping("/api/health")
    @Operation(summary = "Health check", description = "Check if the backend service is running")
    @ApiResponse(responseCode = "200", description = "Service is healthy")
    public Map<String, String> checkHealth() {
        return Map.of("status", "Backend is running!");
    }
}