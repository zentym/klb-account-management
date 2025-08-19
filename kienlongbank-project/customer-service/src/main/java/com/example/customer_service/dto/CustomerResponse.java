package com.example.customer_service.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 📤 Customer Response DTO - Data transfer object for customer API responses
 * 
 * 🎯 Purpose: Return customer data via REST API responses
 * 🔧 Features: Clean response format, includes ID, no validation annotations needed
 * 
 * 📝 Fields:
 * - id: Customer unique identifier
 * - fullName: Customer full name
 * - email: Customer email address
 * - phone: Customer phone number
 * - address: Customer address
 * 
 * @author GitHub Copilot
 * @version 1.0
 * @since August 2025
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerResponse {

    // 🆔 Customer ID
    private Long id;

    // 👤 Full Name
    private String fullName;

    // 📧 Email
    private String email;

    // 📱 Phone
    private String phone;
    
    // 🏠 Address
    private String address;

    // 🔐 Keycloak User ID
    private String keycloakId;
}
