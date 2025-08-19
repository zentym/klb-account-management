package com.example.customer_service.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

/**
 * Vault Configuration for Customer Service
 * 
 * This configuration ensures proper Vault integration with Spring Boot 3.5.4
 * and Spring Cloud 2025.0.0 (Northfields release train).
 * 
 * Key features:
 * - Token-based authentication with Vault
 * - KV secrets engine support  
 * - Configuration refresh support
 * - Graceful degradation when Vault is unavailable
 */
@Configuration
@EnableConfigurationProperties
@RefreshScope
@Profile("!test") // Skip Vault in test profiles
public class VaultConfig {
    
    // Configuration is primarily handled via bootstrap.properties
    // This class ensures proper Spring Boot auto-configuration
    
}
