// Trong file model/Account.java
package com.kienlongbank.klbaccountmanagement.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "accounts")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Account {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String accountNumber;

    @Column(nullable = false)
    private String accountType; // Ví dụ: "SAVINGS", "CHECKING"

    @Column(nullable = false)
    private Double balance;

    @Column(name = "created_date")
    private LocalDateTime createdDate;

    // Thiết lập mối quan hệ: Nhiều Account thuộc về một Customer
    // Trong microservice, chỉ lưu customerId thay vì whole Customer object
    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    @PrePersist
    protected void onCreate() {
        createdDate = LocalDateTime.now();
    }
}