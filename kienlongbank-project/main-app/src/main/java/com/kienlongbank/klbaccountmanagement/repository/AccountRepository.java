// Trong file repository/AccountRepository.java
package com.kienlongbank.klbaccountmanagement.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.kienlongbank.klbaccountmanagement.model.Account;

@Repository
public interface AccountRepository extends JpaRepository<Account, Long> {
    // Tìm tất cả tài khoản theo ID của khách hàng
    List<Account> findByCustomerId(Long customerId);
}