package com.kienlongbank.common.model;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.time.LocalDateTime;

/**
 * 👤 User DTO - Data Transfer Object for user information
 * 
 * 🎯 Purpose: Share user data between microservices 
 * 🔧 Features: Phone number based authentication, role-based access control
 * 
 * 📝 Validation Rules:
 * - phoneNumber: Required, Vietnamese format (+84 or 0 prefix)
 * - role: Required, default USER
 * - enabled: Required, default true
 * 
 * @author GitHub Copilot
 * @version 1.0
 * @since August 2025
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class User {
    
    private Long id;

    // 📱 Phone Number - Used as username for authentication
    @NotBlank(message = "Số điện thoại không được để trống")
    @Pattern(regexp = "^(\\+84|0)[0-9]{9,10}$", 
             message = "Số điện thoại không đúng định dạng (VD: 0901234567 hoặc +84901234567)")
    private String phoneNumber;

    // 🔒 Password - BCrypt encoded password
    @NotBlank(message = "Mật khẩu không được để trống")
    private String password;

    // 🎭 Role - User role for authorization
    private Role role = Role.USER;

    // ✅ Enabled - Account status
    private Boolean enabled = true;

    // 📅 Created Date
    private LocalDateTime createdDate;

    // 📅 Last Login Date
    private LocalDateTime lastLoginDate;

    // Default constructor
    public User() {
        this.createdDate = LocalDateTime.now();
        this.role = Role.USER;
        this.enabled = true;
    }

    // Constructor with basic fields
    public User(String phoneNumber, String password) {
        this();
        this.phoneNumber = phoneNumber;
        this.password = password;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public Boolean getEnabled() {
        return enabled;
    }

    public void setEnabled(Boolean enabled) {
        this.enabled = enabled;
    }

    public LocalDateTime getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(LocalDateTime createdDate) {
        this.createdDate = createdDate;
    }

    public LocalDateTime getLastLoginDate() {
        return lastLoginDate;
    }

    public void setLastLoginDate(LocalDateTime lastLoginDate) {
        this.lastLoginDate = lastLoginDate;
    }

    // Enum for user roles
    public enum Role {
        USER, ADMIN
    }
}
