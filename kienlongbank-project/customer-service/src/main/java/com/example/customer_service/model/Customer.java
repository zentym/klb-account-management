package com.example.customer_service.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 👤 Customer Entity - Represents bank customers in the system
 * 
 * 🎯 Purpose: Store customer information with comprehensive validation
 * 📊 Database: Maps to 'customers' table in PostgreSQL (prod) / H2 (test)
 * 🔧 Features: Full CRUD operations, unique email constraint, Vietnamese validation
 * 
 * 📝 Validation Rules:
 * - fullName: Required, 2-100 characters
 * - email: Required, valid format, unique, max 100 chars
 * - phone: Optional, Vietnamese format (+84 or 0 prefix)
 * - address: Optional, max 255 characters
 * 
 * 🚀 Integration Tests: CustomerControllerIntegrationTest (17 test methods)
 * 📚 Test Coverage: All CRUD operations, validation scenarios, edge cases
 * 
 * @author GitHub Copilot
 * @version 1.0
 * @since August 2025
 */

@Entity
@Table(name = "customers")
@Data // 🔧 Lombok: Auto-generates getters, setters, toString, equals, hashCode
@NoArgsConstructor // 🏗️ Lombok: Default constructor for JPA
@AllArgsConstructor // 🏗️ Lombok: Constructor with all fields
@Builder // 🏗️ Lombok: Builder pattern for clean object creation
public class Customer {
    
    // 🆔 Primary Key - Auto-generated ID
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 👤 Full Name - Required field with length validation
    // ✅ Valid: "Nguyễn Văn A", "Trần Thị B"
    // ❌ Invalid: "", "A", "Very very very long name that exceeds 100 characters limit..."
    @NotBlank(message = "Họ tên không được để trống")
    @Size(min = 2, max = 100, message = "Họ tên phải có từ 2-100 ký tự")
    @Column(nullable = false)
    private String fullName;

    // 📧 Email - Required, unique field with format validation
    // ✅ Valid: "user@kienlongbank.com", "test@gmail.com"
    // ❌ Invalid: "invalid-email", "user@", "@domain.com"
    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    @Size(max = 100, message = "Email không được vượt quá 100 ký tự")
    @Column(unique = true, nullable = false)
    private String email;

    // 📱 Phone - Optional field with Vietnamese format validation
    // ✅ Valid: "0901234567", "+84901234567", "0123456789"
    // ❌ Invalid: "123", "1234567890123", "abcdefghij"
    @Pattern(regexp = "^(\\+84|0)[0-9]{9,10}$", message = "Số điện thoại không đúng định dạng (VD: 0901234567 hoặc +84901234567)")
    private String phone;
    
    // 🏠 Address - Optional field with length validation
    // ✅ Valid: "123 Nguyễn Văn Cừ, Quận 5, TP.HCM", null, ""
    // ❌ Invalid: "Address that is way too long and exceeds the 255 character limit..."
    @Size(max = 255, message = "Địa chỉ không được vượt quá 255 ký tự")
    private String address;

    // 🔐 Keycloak User ID - Links to Keycloak user identity
    // ✅ Valid: "a1b2c3d4-e5f6-7890-abcd-ef1234567890", null
    // ❌ Invalid: "", "invalid-uuid-format"
    // 💡 Purpose: Direct mapping to Keycloak user, avoids hash collisions
    @Column(name = "keycloak_id", unique = true)
    @Size(max = 255, message = "Keycloak ID không được vượt quá 255 ký tự")
    private String keycloakId;

    // Manual getter/setter for keycloakId (backup if Lombok fails)
    public String getKeycloakId() {
        return keycloakId;
    }

    public void setKeycloakId(String keycloakId) {
        this.keycloakId = keycloakId;
    }

}
