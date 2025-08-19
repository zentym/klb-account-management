package com.kienlongbank.loan_service.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.kienlongbank.loan_service.entity.Loan;

@Repository
public interface LoanRepository extends JpaRepository<Loan, Long> {
    
    // Tìm tất cả khoản vay theo customer ID
    List<Loan> findByCustomerId(Long customerId);
    
    // Tìm tất cả khoản vay theo customer ID, sắp xếp theo ngày đăng ký giảm dần (mới nhất trước)
    List<Loan> findByCustomerIdOrderByApplicationDateDesc(Long customerId);
    
    // Tìm khoản vay theo trạng thái
    List<Loan> findByStatus(Loan.LoanStatus status);
    
    // Tìm khoản vay theo customer ID và trạng thái
    List<Loan> findByCustomerIdAndStatus(Long customerId, Loan.LoanStatus status);
    
    // Tìm tổng số tiền vay đang chờ phê duyệt của khách hàng
    @Query("SELECT COALESCE(SUM(l.amount), 0) FROM Loan l WHERE l.customerId = :customerId AND l.status = :status")
    Double getTotalAmountByCustomerIdAndStatus(@Param("customerId") Long customerId, @Param("status") Loan.LoanStatus status);
    
    // Kiểm tra khách hàng có khoản vay đang chờ phê duyệt không
    boolean existsByCustomerIdAndStatus(Long customerId, Loan.LoanStatus status);
}
