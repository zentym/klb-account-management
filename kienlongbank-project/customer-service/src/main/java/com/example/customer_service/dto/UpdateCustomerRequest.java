package com.example.customer_service.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 📝 Update Customer Request DTO - Data transfer object for updating existing customers
 * 
 * 🎯 Purpose: Accept input data for customer updates via REST API
 * 🔧 Features: Flexible validation (fields can be null for partial updates), no ID field
 * 
 * 📝 Validation Rules:
 * - fullName: Optional, but if provided must be 2-100 characters
 * - email: Optional, but if provided must be valid format, max 100 chars
 * - phone: Optional, but if provided must be Vietnamese format
 * - address: Optional, but if provided must be max 255 characters
 * 
 * @author GitHub Copilot
 * @version 1.0
 * @since August 2025
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateCustomerRequest {

    // 👤 Full Name - Optional field with length validation when provided
    @Size(min = 2, max = 100, message = "Họ tên phải có từ 2-100 ký tự")
    private String fullName;

    // 📧 Email - Optional field with format validation when provided
    @Email(message = "Email không đúng định dạng")
    @Size(max = 100, message = "Email không được vượt quá 100 ký tự")
    private String email;

    // 📱 Phone - Optional field with Vietnamese format validation when provided
    @Pattern(regexp = "^(\\+84|0)[0-9]{9,10}$", message = "Số điện thoại không đúng định dạng (VD: 0901234567 hoặc +84901234567)")
    private String phone;
    
    // 🏠 Address - Optional field with length validation when provided
    @Size(max = 255, message = "Địa chỉ không được vượt quá 255 ký tự")
    private String address;

    // 🔐 Keycloak User ID - Optional field for linking to Keycloak user
    @Size(max = 255, message = "Keycloak ID không được vượt quá 255 ký tự")
    private String keycloakId;
}
