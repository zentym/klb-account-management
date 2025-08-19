package com.kienlongbank.klbaccountmanagement.dto;

import lombok.Data;

/**
 * DTO để nhận dữ liệu khi tạo tài khoản mới
 * Không bao gồm id, accountNumber, và customer vì chúng sẽ được tự động tạo
 */
@Data
public class CreateAccountRequest {
    private String accountType; // VD: "SAVINGS", "CHECKING"
    private Double balance; // Số dư ban đầu (có thể null, mặc định sẽ là 0)
    
    // Manual getters and setters for backup (in case Lombok fails)
    public String getAccountType() { return accountType; }
    public void setAccountType(String accountType) { this.accountType = accountType; }
    
    public Double getBalance() { return balance; }
    public void setBalance(Double balance) { this.balance = balance; }
}
