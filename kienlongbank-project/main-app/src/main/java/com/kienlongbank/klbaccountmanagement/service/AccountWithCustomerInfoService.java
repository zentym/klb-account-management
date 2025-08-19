package com.kienlongbank.klbaccountmanagement.service;

import com.kienlongbank.common.dto.CustomerDTO;
import com.kienlongbank.klbaccountmanagement.model.Account;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Service demo cho việc sử dụng customer service integration
 * Ví dụ về cách gọi customer service với RestTemplate
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AccountWithCustomerInfoService {

    private final AccountService accountService;
    private final CustomerServiceClient customerServiceClient;

    /**
     * Tạo tài khoản với thông tin chi tiết khách hàng
     * Demonstrating JWT token forwarding in action
     */
    public AccountWithCustomerInfo createAccountWithCustomerInfo(Long customerId, Account account) {
        log.info("Creating account with customer info for customer ID: {}", customerId);

        // Tạo tài khoản (sẽ verify customer exists với JWT forwarding)
        Account createdAccount = accountService.createAccount(customerId, account);

        // Lấy thông tin chi tiết khách hàng (JWT token được tự động forward)
        CustomerDTO customerInfo = customerServiceClient.getCustomerById(customerId);

        // Tạo response object với đầy đủ thông tin
        AccountWithCustomerInfo result = new AccountWithCustomerInfo();
        result.setAccount(createdAccount);
        result.setCustomer(customerInfo);

        log.info("Successfully created account {} with customer info for {}", 
                createdAccount.getAccountNumber(), customerInfo != null ? customerInfo.getFullName() : "Unknown");

        return result;
    }

    /**
     * Lấy thông tin tài khoản kèm thông tin khách hàng
     */
    public AccountWithCustomerInfo getAccountWithCustomerInfo(Long accountId) {
        log.info("Fetching account with customer info for account ID: {}", accountId);

        Account account = accountService.getAccountById(accountId);
        if (account == null) {
            throw new RuntimeException("Không tìm thấy tài khoản với ID: " + accountId);
        }

        // Lấy thông tin khách hàng (JWT token được tự động forward)
        CustomerDTO customerInfo = customerServiceClient.getCustomerById(account.getCustomerId());

        AccountWithCustomerInfo result = new AccountWithCustomerInfo();
        result.setAccount(account);
        result.setCustomer(customerInfo);

        return result;
    }

    /**
     * Inner class để chứa thông tin tài khoản và khách hàng
     */
    public static class AccountWithCustomerInfo {
        private Account account;
        private CustomerDTO customer;

        // Getters and Setters
        public Account getAccount() { return account; }
        public void setAccount(Account account) { this.account = account; }
        public CustomerDTO getCustomer() { return customer; }
        public void setCustomer(CustomerDTO customer) { this.customer = customer; }
    }
}
