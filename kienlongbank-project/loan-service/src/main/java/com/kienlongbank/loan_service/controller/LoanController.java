package com.kienlongbank.loan_service.controller;

import com.kienlongbank.loan_service.dto.LoanApplicationRequest;
import com.kienlongbank.loan_service.dto.LoanApplicationResponse;
import com.kienlongbank.loan_service.dto.UpdateLoanStatusRequest;
import com.kienlongbank.loan_service.entity.Loan;
import com.kienlongbank.loan_service.service.LoanService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/loans")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = {"http://localhost:3000", "http://localhost:8080"})
public class LoanController {

    private final LoanService loanService;

    @PostMapping("/apply")
    @PreAuthorize("hasRole('customer') or hasRole('admin')")
    public ResponseEntity<?> applyForLoan(@Valid @RequestBody LoanApplicationRequest request) {
        try {
            log.info("Received loan application request: {}", request);
            LoanApplicationResponse response = loanService.applyForLoan(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error processing loan application: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/customer/{customerId}")
    @PreAuthorize("hasRole('customer') or hasRole('admin')")
    public ResponseEntity<?> getLoansByCustomer(@PathVariable Long customerId) {
        try {
            // Bảo mật: Đảm bảo customer chỉ có thể xem khoản vay của chính họ
            // Admin và manager có thể xem tất cả
            if (!isAdminOrManager() && !isCurrentUser(customerId)) {
                log.warn("Access denied: User trying to access loans of customer {}", customerId);
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Bạn chỉ có thể xem các khoản vay của chính mình"));
            }
            
            List<Loan> loans = loanService.getLoansByCustomerId(customerId);
            log.info("Retrieved {} loans for customer {}", loans.size(), customerId);
            return ResponseEntity.ok(loans);
        } catch (Exception e) {
            log.error("Error retrieving loans for customer {}: {}", customerId, e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Lỗi hệ thống khi lấy danh sách khoản vay"));
        }
    }

    @GetMapping("/{loanId}")
    @PreAuthorize("hasRole('customer') or hasRole('admin')")
    public ResponseEntity<?> getLoanById(@PathVariable Long loanId) {
        try {
            return loanService.getLoanById(loanId)
                .map(loan -> ResponseEntity.ok(loan))
                .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            log.error("Error retrieving loan {}: {}", loanId, e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<List<Loan>> getLoansByStatus(@PathVariable String status) {
        try {
            Loan.LoanStatus loanStatus = Loan.LoanStatus.valueOf(status.toUpperCase());
            List<Loan> loans = loanService.getLoansByStatus(loanStatus);
            return ResponseEntity.ok(loans);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            log.error("Error retrieving loans by status {}: {}", status, e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PutMapping("/{loanId}/approve")
    @PreAuthorize("hasRole('admin') or hasRole('manager')")
    public ResponseEntity<?> approveLoan(@PathVariable Long loanId) {
        try {
            Loan approvedLoan = loanService.approveLoan(loanId);
            return ResponseEntity.ok(approvedLoan);
        } catch (Exception e) {
            log.error("Error approving loan {}: {}", loanId, e.getMessage());
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/{loanId}/reject")
    @PreAuthorize("hasRole('admin') or hasRole('manager')")
    public ResponseEntity<?> rejectLoan(@PathVariable Long loanId, @RequestBody Map<String, String> payload) {
        try {
            String reason = payload.get("reason");
            if (reason == null || reason.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Lý do từ chối không được để trống"));
            }
            
            Loan rejectedLoan = loanService.rejectLoan(loanId, reason);
            return ResponseEntity.ok(rejectedLoan);
        } catch (Exception e) {
            log.error("Error rejecting loan {}: {}", loanId, e.getMessage());
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/{loanId}/status")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<?> updateLoanStatus(
            @PathVariable Long loanId, 
            @Valid @RequestBody UpdateLoanStatusRequest request) {
        try {
            log.info("Admin updating loan {} status to: {}", loanId, request.getStatus());
            Loan updatedLoan = loanService.updateLoanStatus(loanId, request.getStatus(), request.getReason());
            return ResponseEntity.ok(updatedLoan);
        } catch (Exception e) {
            log.error("Error updating loan {} status: {}", loanId, e.getMessage());
            return ResponseEntity.badRequest()
                .body(Map.of("error", e.getMessage()));
        }
    }

    // Health check endpoint
    @GetMapping("/public/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "service", "loan-service",
            "timestamp", java.time.LocalDateTime.now().toString()
        ));
    }
    
    // Helper methods for security
    private boolean isAdminOrManager() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getAuthorities().stream()
            .anyMatch(authority -> authority.getAuthority().equals("ROLE_admin") || 
                                 authority.getAuthority().equals("ROLE_manager"));
    }
    
    private boolean isCurrentUser(Long customerId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken jwtAuth) {
            Jwt jwt = jwtAuth.getToken();
            
            // Lấy customer_id từ JWT token
            String customerIdFromToken = jwt.getClaimAsString("customer_id");
            if (customerIdFromToken != null) {
                return Long.valueOf(customerIdFromToken).equals(customerId);
            }
            
            // Fallback: so sánh với sub nếu không có customer_id
            String sub = jwt.getClaimAsString("sub");
            if (sub != null) {
                try {
                    return Long.valueOf(sub).equals(customerId);
                } catch (NumberFormatException e) {
                    log.warn("Could not parse sub as customer ID: {}", sub);
                }
            }
        }
        return false;
    }
}
