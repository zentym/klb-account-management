package com.example.customer_service.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.HashMap;
import java.util.Map;

/**
 * Test Controller để kiểm tra Vault Integration
 */
@RestController
@RequestMapping("/api/vault")
public class VaultTestController {

    @Value("${database.password:default-password}")
    private String databasePassword;
    
    @Value("${jwt.secret:default-jwt-secret}")
    private String jwtSecret;
    
    @Value("${redis.password:default-redis-password}")
    private String redisPassword;
    
    @Value("${test.key:default-test-value}")
    private String testKey;
    
    @GetMapping("/config")
    @PreAuthorize("permitAll()")  // Cho phép public access
    public Map<String, String> getVaultConfig() {
        Map<String, String> config = new HashMap<>();
        config.put("database.password", databasePassword);
        config.put("jwt.secret", jwtSecret);
        config.put("redis.password", redisPassword);
        config.put("test.key", testKey);
        return config;
    }
}
