package com.kienlongbank.loan_service.dto;

import com.kienlongbank.loan_service.entity.Loan;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoanApplicationResponse {
    
    private Long loanId;
    private Long customerId;
    private Double amount;
    private Double interestRate;
    private Integer term;
    private Loan.LoanStatus status;
    private LocalDateTime applicationDate;
    private String message;
    
    public static LoanApplicationResponse fromEntity(Loan loan, String message) {
        return new LoanApplicationResponse(
            loan.getId(),
            loan.getCustomerId(),
            loan.getAmount(),
            loan.getInterestRate(),
            loan.getTerm(),
            loan.getStatus(),
            loan.getApplicationDate(),
            message
        );
    }
}
