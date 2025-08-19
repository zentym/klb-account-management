// trong file service/TransactionService.java
package com.kienlongbank.klbaccountmanagement.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import lombok.RequiredArgsConstructor;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;    
import org.springframework.web.client.RestTemplate;

import com.kienlongbank.klbaccountmanagement.model.Account;
import com.kienlongbank.klbaccountmanagement.model.Transaction;
import com.kienlongbank.klbaccountmanagement.repository.AccountRepository;
import com.kienlongbank.klbaccountmanagement.repository.TransactionRepository;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final AccountRepository accountRepository;
    private final TransactionRepository transactionRepository;
    private final RestTemplate restTemplate;
    private final RabbitTemplate rabbitTemplate;

    @Value("${core.banking.api.url}")
    private String coreBankingApiUrl;

    @Transactional // <-- Chú thích quan trọng!
    public Transaction performTransfer(Long fromAccountId, Double amount, Long toAccountId) {
        // 1. Lấy thông tin tài khoản nguồn và đích
        Account fromAccount = accountRepository.findById(fromAccountId)
            .orElseThrow(() -> new RuntimeException("Tài khoản nguồn không tồn tại!"));
        Account toAccount = accountRepository.findById(toAccountId)
            .orElseThrow(() -> new RuntimeException("Tài khoản đích không tồn tại!"));

        // 2. Kiểm tra số dư tài khoản nguồn
        if (fromAccount.getBalance() < amount) {
            throw new RuntimeException("Số dư không đủ để thực hiện giao dịch!");
        }

        // BƯỚC MỚI: Gọi đến Core Banking giả lập để "xin phép"
        Map<String, Object> requestBody = Map.of(
            "fromAccount", fromAccount.getAccountNumber(),
            "toAccount", toAccount.getAccountNumber(),
            "amount", amount
        );

        // Gọi API của WireMock
        ResponseEntity<String> coreResponse = restTemplate.postForEntity(
            coreBankingApiUrl + "/core/transactions",
            requestBody,
            String.class
        );

        // Kiểm tra phản hồi từ WireMock
        if (coreResponse.getStatusCode() != HttpStatus.OK) {
            // Nếu Core Banking từ chối, văng lỗi để rollback transaction
            throw new RuntimeException("Giao dịch bị Core Banking từ chối.");
        }

        // 3. Thực hiện chuyển tiền
        fromAccount.setBalance(fromAccount.getBalance() - amount);
        toAccount.setBalance(toAccount.getBalance() + amount);

        accountRepository.save(fromAccount);
        accountRepository.save(toAccount);

        // 4. Ghi lại lịch sử giao dịch
        Transaction transaction = new Transaction();
        transaction.setFromAccountId(fromAccountId);
        transaction.setToAccountId(toAccountId);
        transaction.setAmount(amount);
        transaction.setTransactionDate(LocalDateTime.now());
        transaction.setStatus("COMPLETED");
        transaction.setDescription("Chuyển khoản nội bộ");

        Transaction savedTransaction = transactionRepository.save(transaction);

        // BƯỚC MỚI: Gửi tin nhắn đến RabbitMQ sau khi giao dịch thành công
        String message = "Giao dịch thành công với ID: " + savedTransaction.getId() + 
                        ", Số tiền: " + amount + 
                        ", Từ tài khoản: " + fromAccount.getAccountNumber() + 
                        " đến tài khoản: " + toAccount.getAccountNumber();
        rabbitTemplate.convertAndSend("notificationQueue", message);

        return savedTransaction;
    }

    // Lấy tất cả giao dịch của một tài khoản
    public List<Transaction> getTransactionsByAccountId(Long accountId) {
        return transactionRepository.findByAccountId(accountId);
    }

    // Lấy giao dịch gần đây của một tài khoản
    public List<Transaction> getRecentTransactionsByAccountId(Long accountId) {
        return transactionRepository.findRecentTransactionsByAccountId(accountId);
    }

    // Lấy giao dịch theo trạng thái
    public List<Transaction> getTransactionsByStatus(String status) {
        return transactionRepository.findByStatus(status);
    }

    // Lấy giao dịch trong khoảng thời gian
    public List<Transaction> getTransactionsByDateRange(LocalDateTime startDate, LocalDateTime endDate) {
        return transactionRepository.findByDateRange(startDate, endDate);
    }

    // Lấy giao dịch của tài khoản trong khoảng thời gian
    public List<Transaction> getTransactionsByAccountIdAndDateRange(Long accountId, LocalDateTime startDate, LocalDateTime endDate) {
        return transactionRepository.findByAccountIdAndDateRange(accountId, startDate, endDate);
    }

    // Lấy giao dịch theo số tiền lớn hơn
    public List<Transaction> getTransactionsByAmountGreaterThan(Double amount) {
        return transactionRepository.findByAmountGreaterThan(amount);
    }

    // Lấy giao dịch theo khoảng số tiền
    public List<Transaction> getTransactionsByAmountRange(Double minAmount, Double maxAmount) {
        return transactionRepository.findByAmountRange(minAmount, maxAmount);
    }

    // Đếm số giao dịch theo trạng thái
    public Long countTransactionsByStatus(String status) {
        return transactionRepository.countByStatus(status);
    }

    // Tìm giao dịch theo từ khóa trong mô tả
    public List<Transaction> searchTransactionsByDescription(String keyword) {
        return transactionRepository.findByDescriptionContaining(keyword);
    }

    // Lấy tất cả giao dịch của tài khoản sắp xếp theo ngày
    public List<Transaction> getAllTransactionsByAccountIdOrderByDate(Long accountId) {
        return transactionRepository.findAllTransactionsByAccountIdOrderByDateDesc(accountId);
    }
}