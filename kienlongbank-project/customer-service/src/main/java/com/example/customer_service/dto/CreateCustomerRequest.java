package com.example.customer_service.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 📝 Create Customer Request DTO - Data transfer object for creating new customers
 * 
 * 🎯 Purpose: Accept input data for customer creation via REST API
 * 🔧 Features: Input validation, no ID field (auto-generated), clean separation from entity
 * 
 * 📝 Validation Rules:
 * - fullName: Required, 2-100 characters
 * - email: Required, valid format, max 100 chars
 * - phone: Optional, Vietnamese format (+84 or 0 prefix)
 * - address: Optional, max 255 characters
 * 
 * @author GitHub Copilot
 * @version 1.0
 * @since August 2025
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateCustomerRequest {

    // 👤 Full Name - Required field with length validation
    @NotBlank(message = "Họ tên không được để trống")
    @Size(min = 2, max = 100, message = "Họ tên phải có từ 2-100 ký tự")
    private String fullName;

    // 📧 Email - Required field with format validation
    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    @Size(max = 100, message = "Email không được vượt quá 100 ký tự")
    private String email;

    // 📱 Phone - Optional field with Vietnamese format validation
    @Pattern(regexp = "^(\\+84|0)[0-9]{9,10}$", message = "Số điện thoại không đúng định dạng (VD: 0901234567 hoặc +84901234567)")
    private String phone;
    
    // 🏠 Address - Optional field with length validation
    @Size(max = 255, message = "Địa chỉ không được vượt quá 255 ký tự")
    private String address;

    // 🔐 Keycloak User ID - Optional field for linking to Keycloak user
    @Size(max = 255, message = "Keycloak ID không được vượt quá 255 ký tự")
    private String keycloakId;
}
