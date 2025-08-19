package com.kienlongbank.klbaccountmanagement.controller;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.kienlongbank.klbaccountmanagement.model.Transaction;
import com.kienlongbank.klbaccountmanagement.service.TransactionService;

@RestController
@RequestMapping("/api/transactions")
public class TransactionController {

    @Autowired
    private TransactionService transactionService;

    @PostMapping("/transfer")
    public ResponseEntity<?> performTransfer(@RequestBody TransferRequest request) {
        try {
            // Validate input
            if (request.getFromAccountId() == null || request.getToAccountId() == null || request.getAmount() == null) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Thiếu thông tin bắt buộc: fromAccountId, toAccountId, amount"));
            }

            if (request.getAmount() <= 0) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Số tiền phải lớn hơn 0"));
            }

            if (request.getFromAccountId().equals(request.getToAccountId())) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Không thể chuyển tiền cho chính tài khoản của mình"));
            }

            // Perform transfer
            Transaction transaction = transactionService.performTransfer(
                request.getFromAccountId(),
                request.getAmount(),
                request.getToAccountId()
            );

            return ResponseEntity.ok(Map.of(
                "message", "Chuyển khoản thành công",
                "transaction", transaction
            ));

        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Có lỗi xảy ra trong quá trình chuyển khoản"));
        }
    }

    // API để lấy tất cả giao dịch của một tài khoản
    @GetMapping("/account/{accountId}")
    public ResponseEntity<?> getTransactionsByAccountId(@PathVariable Long accountId) {
        try {
            List<Transaction> transactions = transactionService.getTransactionsByAccountId(accountId);
            return ResponseEntity.ok(Map.of(
                "message", "Lấy danh sách giao dịch thành công",
                "transactions", transactions
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Có lỗi xảy ra khi lấy danh sách giao dịch"));
        }
    }

    // API để lấy giao dịch gần đây của một tài khoản
    @GetMapping("/account/{accountId}/recent")
    public ResponseEntity<?> getRecentTransactionsByAccountId(@PathVariable Long accountId) {
        try {
            List<Transaction> transactions = transactionService.getRecentTransactionsByAccountId(accountId);
            return ResponseEntity.ok(Map.of(
                "message", "Lấy giao dịch gần đây thành công",
                "transactions", transactions
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Có lỗi xảy ra khi lấy giao dịch gần đây"));
        }
    }

    // API để lấy giao dịch theo trạng thái
    @GetMapping("/status/{status}")
    public ResponseEntity<?> getTransactionsByStatus(@PathVariable String status) {
        try {
            List<Transaction> transactions = transactionService.getTransactionsByStatus(status);
            return ResponseEntity.ok(Map.of(
                "message", "Lấy giao dịch theo trạng thái thành công",
                "transactions", transactions
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Có lỗi xảy ra khi lấy giao dịch theo trạng thái"));
        }
    }

    // API để lấy giao dịch trong khoảng thời gian
    @GetMapping("/date-range")
    public ResponseEntity<?> getTransactionsByDateRange(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        try {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
            LocalDateTime start = LocalDateTime.parse(startDate + " 00:00:00", formatter);
            LocalDateTime end = LocalDateTime.parse(endDate + " 23:59:59", formatter);
            
            List<Transaction> transactions = transactionService.getTransactionsByDateRange(start, end);
            return ResponseEntity.ok(Map.of(
                "message", "Lấy giao dịch theo khoảng thời gian thành công",
                "transactions", transactions
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", "Định dạng ngày không hợp lệ hoặc có lỗi xảy ra"));
        }
    }

    // API để lấy giao dịch của tài khoản trong khoảng thời gian
    @GetMapping("/account/{accountId}/date-range")
    public ResponseEntity<?> getTransactionsByAccountIdAndDateRange(
            @PathVariable Long accountId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        try {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
            LocalDateTime start = LocalDateTime.parse(startDate + " 00:00:00", formatter);
            LocalDateTime end = LocalDateTime.parse(endDate + " 23:59:59", formatter);
            
            List<Transaction> transactions = transactionService.getTransactionsByAccountIdAndDateRange(accountId, start, end);
            return ResponseEntity.ok(Map.of(
                "message", "Lấy giao dịch của tài khoản theo thời gian thành công",
                "transactions", transactions
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", "Định dạng ngày không hợp lệ hoặc có lỗi xảy ra"));
        }
    }

    // API để lấy giao dịch theo số tiền lớn hơn
    @GetMapping("/amount-greater-than/{amount}")
    public ResponseEntity<?> getTransactionsByAmountGreaterThan(@PathVariable Double amount) {
        try {
            List<Transaction> transactions = transactionService.getTransactionsByAmountGreaterThan(amount);
            return ResponseEntity.ok(Map.of(
                "message", "Lấy giao dịch theo số tiền thành công",
                "transactions", transactions
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Có lỗi xảy ra khi lấy giao dịch theo số tiền"));
        }
    }

    // API để lấy giao dịch theo khoảng số tiền
    @GetMapping("/amount-range")
    public ResponseEntity<?> getTransactionsByAmountRange(
            @RequestParam Double minAmount,
            @RequestParam Double maxAmount) {
        try {
            List<Transaction> transactions = transactionService.getTransactionsByAmountRange(minAmount, maxAmount);
            return ResponseEntity.ok(Map.of(
                "message", "Lấy giao dịch theo khoảng số tiền thành công",
                "transactions", transactions
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", "Có lỗi xảy ra khi lấy giao dịch theo khoảng số tiền"));
        }
    }

    // API để đếm số giao dịch theo trạng thái
    @GetMapping("/count/status/{status}")
    public ResponseEntity<?> countTransactionsByStatus(@PathVariable String status) {
        try {
            Long count = transactionService.countTransactionsByStatus(status);
            return ResponseEntity.ok(Map.of(
                "message", "Đếm giao dịch thành công",
                "count", count,
                "status", status
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Có lỗi xảy ra khi đếm giao dịch"));
        }
    }

    // API để tìm giao dịch theo từ khóa trong mô tả
    @GetMapping("/search")
    public ResponseEntity<?> searchTransactionsByDescription(@RequestParam String keyword) {
        try {
            List<Transaction> transactions = transactionService.searchTransactionsByDescription(keyword);
            return ResponseEntity.ok(Map.of(
                "message", "Tìm kiếm giao dịch thành công",
                "transactions", transactions,
                "keyword", keyword
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Có lỗi xảy ra khi tìm kiếm giao dịch"));
        }
    }

    // API để lấy tất cả giao dịch của tài khoản sắp xếp theo ngày
    @GetMapping("/account/{accountId}/all-sorted")
    public ResponseEntity<?> getAllTransactionsByAccountIdOrderByDate(@PathVariable Long accountId) {
        try {
            List<Transaction> transactions = transactionService.getAllTransactionsByAccountIdOrderByDate(accountId);
            return ResponseEntity.ok(Map.of(
                "message", "Lấy tất cả giao dịch sắp xếp thành công",
                "transactions", transactions
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Có lỗi xảy ra khi lấy danh sách giao dịch"));
        }
    }

    // Inner class for request body
    public static class TransferRequest {
        private Long fromAccountId;
        private Long toAccountId;
        private Double amount;

        // Constructors
        public TransferRequest() {}

        public TransferRequest(Long fromAccountId, Long toAccountId, Double amount) {
            this.fromAccountId = fromAccountId;
            this.toAccountId = toAccountId;
            this.amount = amount;
        }

        // Getters and Setters
        public Long getFromAccountId() {
            return fromAccountId;
        }

        public void setFromAccountId(Long fromAccountId) {
            this.fromAccountId = fromAccountId;
        }

        public Long getToAccountId() {
            return toAccountId;
        }

        public void setToAccountId(Long toAccountId) {
            this.toAccountId = toAccountId;
        }

        public Double getAmount() {
            return amount;
        }

        public void setAmount(Double amount) {
            this.amount = amount;
        }
    }
}
