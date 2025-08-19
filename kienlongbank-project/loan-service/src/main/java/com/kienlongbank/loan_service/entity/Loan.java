package com.kienlongbank.loan_service.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "loans")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Loan {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long customerId; // ID của khách hàng vay

    @Column(nullable = false)
    private Double amount; // Số tiền vay
    
    @Column(nullable = false)
    private Double interestRate; // Lãi suất
    
    @Column(nullable = false)
    private Integer term; // Kỳ hạn (ví dụ: số tháng)
    
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private LoanStatus status; // Trạng thái: "PENDING", "APPROVED", "REJECTED"
    
    @Column(nullable = false)
    private LocalDateTime applicationDate;
    
    @Column
    private LocalDateTime approvalDate;
    
    @Column
    private String approvedBy; // ID của người phê duyệt
    
    @Column
    private String rejectReason; // Lý do từ chối (nếu có)
    
    @PrePersist
    protected void onCreate() {
        if (applicationDate == null) {
            applicationDate = LocalDateTime.now();
        }
        if (status == null) {
            status = LoanStatus.PENDING;
        }
    }
    
    public enum LoanStatus {
        PENDING,
        APPROVED,
        REJECTED,
        DISBURSED,
        CLOSED
    }
}
