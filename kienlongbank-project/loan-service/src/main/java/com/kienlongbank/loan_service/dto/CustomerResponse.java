package com.kienlongbank.loan_service.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomerResponse {
    
    private Long id;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String identityNumber;
    private String address;
    private String status;
    private Double creditScore;
    private Double monthlyIncome;
}
