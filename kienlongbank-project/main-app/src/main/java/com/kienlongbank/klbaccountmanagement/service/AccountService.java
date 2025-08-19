package com.kienlongbank.klbaccountmanagement.service;

import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.kienlongbank.klbaccountmanagement.model.Account;
import com.kienlongbank.klbaccountmanagement.repository.AccountRepository;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class AccountService {

    @Autowired
    private AccountRepository accountRepository;

    @Autowired
    private CustomerServiceClient customerServiceClient; // Sử dụng RestTemplate-based client

    /**
     * Tạo tài khoản mới cho một khách hàng
     * @param customerId ID của khách hàng  
     * @param account Thông tin tài khoản (không cần customerId và accountNumber)
     * @return Account đã được tạo
     * @throws RuntimeException nếu customerId không hợp lệ hoặc customer không tồn tại
     */
    public Account createAccount(Long customerId, Account account) {
        log.info("Creating account for customer ID: {}", customerId);
        
        // Kiểm tra customerId hợp lệ
        if (customerId == null || customerId <= 0) {
            throw new RuntimeException("Customer ID không hợp lệ: " + customerId);
        }

        // Kiểm tra customer có tồn tại trong customer-service không
        // Circuit Breaker sẽ được áp dụng trong CustomerServiceClientV2
        try {
            if (!customerServiceClient.customerExists(customerId)) {
                throw new RuntimeException("Không tìm thấy khách hàng với ID: " + customerId);
            }
        } catch (RuntimeException e) {
            // Re-throw Circuit Breaker exceptions hoặc customer not found exceptions
            log.error("Failed to verify customer {}: {}", customerId, e.getMessage());
            throw e;
        }

        // Tự động tạo số tài khoản duy nhất
        String accountNumber = generateAccountNumber();
        
        // Thiết lập thông tin cho tài khoản mới
        account.setAccountNumber(accountNumber);
        account.setCustomerId(customerId); // Sử dụng customerId thay vì Customer object
        
        // Nếu balance không được thiết lập, mặc định là 0
        if (account.getBalance() == null) {
            account.setBalance(0.0);
        }

        Account savedAccount = accountRepository.save(account);
        log.info("Successfully created account {} for customer {}", savedAccount.getAccountNumber(), customerId);
        return savedAccount;
    }

    /**
     * Cập nhật thông tin tài khoản
     * @param accountId ID của tài khoản cần cập nhật
     * @param accountDetails Thông tin tài khoản mới
     * @return Account đã được cập nhật hoặc null nếu không tìm thấy
     */
    public Account updateAccount(Long accountId, Account accountDetails) {
        Account existingAccount = accountRepository.findById(accountId).orElse(null);
        if (existingAccount != null) {
            // Cập nhật các trường có thể thay đổi
            if (accountDetails.getAccountType() != null) {
                existingAccount.setAccountType(accountDetails.getAccountType());
            }
            if (accountDetails.getBalance() != null) {
                existingAccount.setBalance(accountDetails.getBalance());
            }
            return accountRepository.save(existingAccount);
        }
        return null;
    }

    /**
     * Lấy danh sách tất cả tài khoản của một khách hàng
     * @param customerId ID của khách hàng
     * @return List<Account> danh sách tài khoản
     */
    public List<Account> getAccountsByCustomerId(Long customerId) {
        return accountRepository.findByCustomerId(customerId);
    }

    /**
     * Lấy thông tin một tài khoản theo ID
     * @param accountId ID của tài khoản
     * @return Account hoặc null nếu không tìm thấy
     */
    public Account getAccountById(Long accountId) {
        return accountRepository.findById(accountId).orElse(null);
    }

    /**
     * Xóa tài khoản
     * @param accountId ID của tài khoản cần xóa
     */
    public void deleteAccount(Long accountId) {
        accountRepository.deleteById(accountId);
    }

    /**
     * Lấy tất cả tài khoản trong hệ thống
     * @return List<Account> danh sách tất cả tài khoản
     */
    public List<Account> getAllAccounts() {
        return accountRepository.findAll();
    }

    /**
     * Tạo số tài khoản duy nhất
     * @return String số tài khoản
     */
    private String generateAccountNumber() {
        // Sử dụng UUID để tạo số tài khoản duy nhất
        // Có thể tùy chỉnh format theo yêu cầu ngân hàng
        String uuid = UUID.randomUUID().toString().replace("-", "").toUpperCase();
        return "KLB" + uuid.substring(0, 10); // KLB + 10 ký tự đầu của UUID
    }
}
