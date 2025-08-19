package com.kienlongbank.klbaccountmanagement.dto;

import java.time.LocalDateTime;

import lombok.Data;

/**
 * DTO để trả về thông tin Account mà không bao gồm Customer object
 * Điều này giúp tránh circular reference và lỗi với Swagger
 */
@Data
public class AccountResponse {
    private Long id;
    private String accountNumber;
    private String accountType;
    private Double balance;
    private Long customerId; // Chỉ trả về ID của customer thay vì toàn bộ object
    private LocalDateTime createdDate;
    
    // Manual getters and setters for backup (in case Lombok fails)
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }
    
    public String getAccountType() { return accountType; }
    public void setAccountType(String accountType) { this.accountType = accountType; }
    
    public Double getBalance() { return balance; }
    public void setBalance(Double balance) { this.balance = balance; }
    
    public Long getCustomerId() { return customerId; }
    public void setCustomerId(Long customerId) { this.customerId = customerId; }
    
    public LocalDateTime getCreatedDate() { return createdDate; }
    public void setCreatedDate(LocalDateTime createdDate) { this.createdDate = createdDate; }
}
