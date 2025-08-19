package com.kienlongbank.klbaccountmanagement.controller;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.kienlongbank.klbaccountmanagement.dto.AccountResponse;
import com.kienlongbank.klbaccountmanagement.dto.CreateAccountRequest;
import com.kienlongbank.klbaccountmanagement.model.Account;
import com.kienlongbank.klbaccountmanagement.service.AccountService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api")
@Tag(name = "Account Management", description = "APIs for managing bank accounts")
public class AccountController {

    @Autowired
    private AccountService accountService;

    // Helper method để chuyển Account entity thành AccountResponse DTO
    private AccountResponse convertToDTO(Account account) {
        AccountResponse response = new AccountResponse();
        response.setId(account.getId());
        response.setAccountNumber(account.getAccountNumber());
        response.setAccountType(account.getAccountType());
        response.setBalance(account.getBalance());
        response.setCustomerId(account.getCustomerId()); // Sử dụng customerId trực tiếp
        response.setCreatedDate(account.getCreatedDate());
        return response;
    }

    /**
     * Tạo tài khoản mới (đơn giản hóa - sẽ lấy customerId từ JWT)
     * POST /api/accounts
     */
    @PostMapping("/accounts")
    @Operation(summary = "Create new account", description = "Create a new account for the current authenticated user")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "201", description = "Account created successfully"),
        @ApiResponse(responseCode = "400", description = "Invalid input data"),
        @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<?> createAccount(@RequestBody CreateAccountRequest request) {
        try {
            // TODO: Lấy customerId từ JWT token trong thực tế
            // Hiện tại sử dụng customerId cố định = 1 để test
            Long customerId = 1L;
            
            // Chuyển đổi DTO thành Entity
            Account account = new Account();
            account.setAccountType(request.getAccountType());
            account.setBalance(request.getBalance() != null ? request.getBalance() : 0.0);
            
            Account createdAccount = accountService.createAccount(customerId, account);
            AccountResponse response = convertToDTO(createdAccount);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Lỗi: " + e.getMessage());
        }
    }

    /**
     * Tạo một tài khoản mới cho một khách hàng cụ thể
     * POST /api/customers/{customerId}/accounts
     */
    @PostMapping("/customers/{customerId}/accounts")
    @Operation(summary = "Create new account", description = "Create a new account for a specific customer")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "201", description = "Account created successfully"),
        @ApiResponse(responseCode = "404", description = "Customer not found"),
        @ApiResponse(responseCode = "400", description = "Invalid input data")
    })
    public ResponseEntity<?> createAccountForCustomer(
            @Parameter(description = "Customer ID") @PathVariable Long customerId, 
            @RequestBody CreateAccountRequest request) {
        try {
            // Chuyển đổi DTO thành Entity
            Account account = new Account();
            account.setAccountType(request.getAccountType());
            account.setBalance(request.getBalance() != null ? request.getBalance() : 0.0);
            
            Account createdAccount = accountService.createAccount(customerId, account);
            AccountResponse response = convertToDTO(createdAccount);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("Lỗi: " + e.getMessage());
        }
    }

    /**
     * Lấy danh sách tất cả tài khoản của một khách hàng
     * GET /api/customers/{customerId}/accounts
     */
    @GetMapping("/customers/{customerId}/accounts")
    @Operation(summary = "Get customer accounts", description = "Get all accounts for a specific customer")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved accounts"),
        @ApiResponse(responseCode = "404", description = "Customer not found")
    })
    public ResponseEntity<?> getAccountsByCustomerId(
            @Parameter(description = "Customer ID") @PathVariable Long customerId) {
        try {
            List<Account> accounts = accountService.getAccountsByCustomerId(customerId);
            List<AccountResponse> response = accounts.stream()
                    .map(this::convertToDTO)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("Lỗi: " + e.getMessage());
        }
    }

    /**
     * Lấy thông tin một tài khoản cụ thể
     * GET /api/accounts/{accountId}
     */
    @GetMapping("/accounts/{accountId}")
    @Operation(summary = "Get account by ID", description = "Get account information by account ID")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Account found"),
        @ApiResponse(responseCode = "404", description = "Account not found")
    })
    public ResponseEntity<?> getAccountById(
            @Parameter(description = "Account ID") @PathVariable Long accountId) {
        Account account = accountService.getAccountById(accountId);
        if (account != null) {
            AccountResponse response = convertToDTO(account);
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("Không tìm thấy tài khoản với ID: " + accountId);
        }
    }

    /**
     * Cập nhật thông tin tài khoản
     * PUT /api/accounts/{accountId}
     */
    @PutMapping("/accounts/{accountId}")
    @Operation(summary = "Update account", description = "Update account information")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Account updated successfully"),
        @ApiResponse(responseCode = "404", description = "Account not found"),
        @ApiResponse(responseCode = "400", description = "Invalid input data")
    })
    public ResponseEntity<?> updateAccount(
            @Parameter(description = "Account ID") @PathVariable Long accountId, 
            @RequestBody Account accountDetails) {
        Account updatedAccount = accountService.updateAccount(accountId, accountDetails);
        if (updatedAccount != null) {
            AccountResponse response = convertToDTO(updatedAccount);
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("Không tìm thấy tài khoản với ID: " + accountId);
        }
    }

    /**
     * Xóa tài khoản
     * DELETE /api/accounts/{accountId}
     */
    @DeleteMapping("/accounts/{accountId}")
    @Operation(summary = "Delete account", description = "Delete an account by ID")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Account deleted successfully"),
        @ApiResponse(responseCode = "404", description = "Account not found"),
        @ApiResponse(responseCode = "500", description = "Internal server error")
    })
    public ResponseEntity<?> deleteAccount(
            @Parameter(description = "Account ID") @PathVariable Long accountId) {
        try {
            accountService.deleteAccount(accountId);
            return ResponseEntity.ok("Đã xóa tài khoản thành công");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Lỗi khi xóa tài khoản: " + e.getMessage());
        }
    }

    /**
     * Lấy tất cả tài khoản trong hệ thống (có thể dùng cho admin)
     * GET /api/accounts
     */
    @GetMapping("/accounts")
    @Operation(summary = "Get all accounts", description = "Get all accounts in the system (admin only)")
    @ApiResponse(responseCode = "200", description = "Successfully retrieved all accounts")
    public List<AccountResponse> getAllAccounts() {
        List<Account> accounts = accountService.getAllAccounts();
        return accounts.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
}
