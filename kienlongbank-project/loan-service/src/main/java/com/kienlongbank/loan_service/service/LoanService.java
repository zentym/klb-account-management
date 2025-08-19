package com.kienlongbank.loan_service.service;

import com.kienlongbank.loan_service.dto.LoanApplicationRequest;
import com.kienlongbank.loan_service.dto.LoanApplicationResponse;
import com.kienlongbank.loan_service.entity.Loan;
import com.kienlongbank.loan_service.repository.LoanRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class LoanService {

    private final LoanRepository loanRepository;

    @Transactional
    public LoanApplicationResponse applyForLoan(LoanApplicationRequest request) {
        log.info("Processing loan application for customer: {}", request.getCustomerId());
        
        try {
            // TODO: Implement Dubbo-based customer service verification here
            // For now, we assume customer exists if customerId is provided
            if (request.getCustomerId() == null) {
                throw new RuntimeException("Customer ID is required");
            }
            
            log.info("Processing loan for customer ID: {}", request.getCustomerId());
            
            // 2. Kiểm tra khách hàng có khoản vay đang chờ phê duyệt không
            if (loanRepository.existsByCustomerIdAndStatus(request.getCustomerId(), Loan.LoanStatus.PENDING)) {
                throw new RuntimeException("Khách hàng đã có khoản vay đang chờ phê duyệt");
            }
            
            // 3. Kiểm tra tín dụng (gọi service khác hoặc logic đơn giản)
            boolean creditEligible = checkCreditEligibility(request.getCustomerId(), request.getAmount());
            if (!creditEligible) {
                // Tạo loan với trạng thái REJECTED
                Loan rejectedLoan = createLoan(request, Loan.LoanStatus.REJECTED);
                rejectedLoan.setRejectReason("Không đủ điều kiện tín dụng");
                rejectedLoan = loanRepository.save(rejectedLoan);
                
                return LoanApplicationResponse.fromEntity(rejectedLoan, "Đơn vay bị từ chối do không đủ điều kiện tín dụng");
            }
            
            // 4. Tạo khoản vay với trạng thái PENDING
            Loan loan = createLoan(request, Loan.LoanStatus.PENDING);
            loan = loanRepository.save(loan);
            
            log.info("Loan application created successfully with ID: {}", loan.getId());
            return LoanApplicationResponse.fromEntity(loan, "Đơn vay đã được nộp thành công và đang chờ phê duyệt");
            
        } catch (Exception e) {
            log.error("Error processing loan application: {}", e.getMessage(), e);
            throw new RuntimeException("Lỗi khi xử lý đơn vay: " + e.getMessage());
        }
    }
    
    private Loan createLoan(LoanApplicationRequest request, Loan.LoanStatus status) {
        Loan loan = new Loan();
        loan.setCustomerId(request.getCustomerId());
        loan.setAmount(request.getAmount());
        loan.setInterestRate(request.getInterestRate());
        loan.setTerm(request.getTerm());
        loan.setStatus(status);
        loan.setApplicationDate(LocalDateTime.now());
        return loan;
    }
    
    private boolean checkCreditEligibility(Long customerId, Double amount) {
        try {
            // TODO: Implement Dubbo-based credit eligibility check
            log.info("Checking credit eligibility for customer {} with amount {}", customerId, amount);
            
            // Fallback logic for now
            return amount <= 50000; // Simple rule: approve loans under 50k
        } catch (Exception e) {
            log.warn("Could not check credit eligibility, using fallback logic: {}", e.getMessage());
        }
        
        // Fallback logic: kiểm tra đơn giản
        // Ví dụ: số tiền vay không quá 100 triệu
        return amount <= 100_000_000.0;
    }
    
    public List<Loan> getLoansByCustomerId(Long customerId) {
        return loanRepository.findByCustomerIdOrderByApplicationDateDesc(customerId);
    }
    
    public Optional<Loan> getLoanById(Long loanId) {
        return loanRepository.findById(loanId);
    }
    
    public List<Loan> getLoansByStatus(Loan.LoanStatus status) {
        return loanRepository.findByStatus(status);
    }
    
    @Transactional
    public Loan approveLoan(Long loanId) {
        Loan loan = loanRepository.findById(loanId)
            .orElseThrow(() -> new RuntimeException("Không tìm thấy khoản vay"));
        
        if (loan.getStatus() != Loan.LoanStatus.PENDING) {
            throw new RuntimeException("Chỉ có thể phê duyệt khoản vay đang chờ xử lý");
        }
        
        loan.setStatus(Loan.LoanStatus.APPROVED);
        loan.setApprovalDate(LocalDateTime.now());
        loan.setApprovedBy(getCurrentUserId());
        
        return loanRepository.save(loan);
    }
    
    @Transactional
    public Loan rejectLoan(Long loanId, String reason) {
        Loan loan = loanRepository.findById(loanId)
            .orElseThrow(() -> new RuntimeException("Không tìm thấy khoản vay"));
        
        if (loan.getStatus() != Loan.LoanStatus.PENDING) {
            throw new RuntimeException("Chỉ có thể từ chối khoản vay đang chờ xử lý");
        }
        
        loan.setStatus(Loan.LoanStatus.REJECTED);
        loan.setRejectReason(reason);
        loan.setApprovedBy(getCurrentUserId());
        
        return loanRepository.save(loan);
    }
    
    @Transactional
    public Loan updateLoanStatus(Long loanId, String newStatus, String reason) {
        Loan loan = loanRepository.findById(loanId)
            .orElseThrow(() -> new RuntimeException("Không tìm thấy khoản vay"));
        
        // Xác thực trạng thái hợp lệ
        Loan.LoanStatus targetStatus;
        try {
            targetStatus = Loan.LoanStatus.valueOf(newStatus.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Trạng thái không hợp lệ: " + newStatus);
        }
        
        // Kiểm tra quy tắc chuyển đổi trạng thái
        if (loan.getStatus() != Loan.LoanStatus.PENDING && 
            targetStatus != Loan.LoanStatus.DISBURSED && 
            targetStatus != Loan.LoanStatus.CLOSED) {
            throw new RuntimeException("Chỉ có thể cập nhật trạng thái cho khoản vay đang chờ xử lý, hoặc chuyển sang DISBURSED/CLOSED");
        }
        
        // Cập nhật trạng thái
        loan.setStatus(targetStatus);
        loan.setApprovedBy(getCurrentUserId());
        
        if (targetStatus == Loan.LoanStatus.APPROVED) {
            loan.setApprovalDate(LocalDateTime.now());
        } else if (targetStatus == Loan.LoanStatus.REJECTED) {
            if (reason == null || reason.trim().isEmpty()) {
                throw new RuntimeException("Lý do từ chối không được để trống");
            }
            loan.setRejectReason(reason);
        }
        
        return loanRepository.save(loan);
    }
    
    private String getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken) {
            JwtAuthenticationToken jwtAuth = (JwtAuthenticationToken) authentication;
            Jwt jwt = jwtAuth.getToken();
            return jwt.getClaimAsString("sub"); // hoặc preferred_username
        }
        return "system";
    }
}
