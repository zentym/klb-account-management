package com.kienlongbank.klbaccountmanagement.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.kienlongbank.klbaccountmanagement.model.Transaction;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {

    // Tìm tất cả giao dịch của một tài khoản (cả gửi và nhận)
    @Query("SELECT t FROM Transaction t WHERE t.fromAccountId = :accountId OR t.toAccountId = :accountId")
    List<Transaction> findByAccountId(@Param("accountId") Long accountId);

    // Tìm giao dịch theo tài khoản gửi
    List<Transaction> findByFromAccountId(Long fromAccountId);

    // Tìm giao dịch theo tài khoản nhận
    List<Transaction> findByToAccountId(Long toAccountId);

    // Tìm giao dịch theo trạng thái
    List<Transaction> findByStatus(String status);

    // Tìm giao dịch trong khoảng thời gian
    @Query("SELECT t FROM Transaction t WHERE t.transactionDate BETWEEN :startDate AND :endDate")
    List<Transaction> findByDateRange(@Param("startDate") LocalDateTime startDate, 
                                     @Param("endDate") LocalDateTime endDate);

    // Tìm giao dịch của một tài khoản trong khoảng thời gian
    @Query("SELECT t FROM Transaction t WHERE (t.fromAccountId = :accountId OR t.toAccountId = :accountId) " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate")
    List<Transaction> findByAccountIdAndDateRange(@Param("accountId") Long accountId,
                                                 @Param("startDate") LocalDateTime startDate,
                                                 @Param("endDate") LocalDateTime endDate);

    // Tìm giao dịch theo số tiền lớn hơn một giá trị
    List<Transaction> findByAmountGreaterThan(Double amount);

    // Tìm giao dịch theo số tiền trong khoảng
    @Query("SELECT t FROM Transaction t WHERE t.amount BETWEEN :minAmount AND :maxAmount")
    List<Transaction> findByAmountRange(@Param("minAmount") Double minAmount, 
                                       @Param("maxAmount") Double maxAmount);

    // Tìm giao dịch gần đây nhất của một tài khoản
    @Query("SELECT t FROM Transaction t WHERE (t.fromAccountId = :accountId OR t.toAccountId = :accountId) " +
           "ORDER BY t.transactionDate DESC")
    List<Transaction> findRecentTransactionsByAccountId(@Param("accountId") Long accountId);

    // Đếm số giao dịch theo trạng thái
    Long countByStatus(String status);

    // Tìm giao dịch theo mô tả (tìm kiếm gần đúng)
    @Query("SELECT t FROM Transaction t WHERE t.description LIKE %:keyword%")
    List<Transaction> findByDescriptionContaining(@Param("keyword") String keyword);

    // Tìm tất cả giao dịch liên quan đến một tài khoản, sắp xếp theo ngày mới nhất
    @Query("SELECT t FROM Transaction t WHERE (t.fromAccountId = :accountId OR t.toAccountId = :accountId) " +
           "ORDER BY t.transactionDate DESC")
    List<Transaction> findAllTransactionsByAccountIdOrderByDateDesc(@Param("accountId") Long accountId);
}
