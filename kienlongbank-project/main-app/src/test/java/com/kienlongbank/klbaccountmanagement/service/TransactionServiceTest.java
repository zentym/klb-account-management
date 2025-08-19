package com.kienlongbank.klbaccountmanagement.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import com.kienlongbank.klbaccountmanagement.model.Account;
import com.kienlongbank.klbaccountmanagement.model.Transaction;
import com.kienlongbank.klbaccountmanagement.repository.AccountRepository;
import com.kienlongbank.klbaccountmanagement.repository.TransactionRepository;

/**
 * Unit Test cho TransactionService
 * Kiểm thử các kịch bản khác nhau của phương thức performTransfer
 */
@ExtendWith(MockitoExtension.class)
class TransactionServiceTest {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private RabbitTemplate rabbitTemplate;

    @InjectMocks
    private TransactionService transactionService;

    private Account fromAccount;
    private Account toAccount;
    private Transaction mockTransaction;

    @BeforeEach
    void setUp() {
        // Thiết lập dữ liệu test
        fromAccount = Account.builder()
                .id(1L)
                .accountNumber("ACC001")
                .accountType("SAVINGS")
                .balance(1000.0)
                .customerId(1L)
                .createdDate(LocalDateTime.now())
                .build();

        toAccount = Account.builder()
                .id(2L)
                .accountNumber("ACC002")
                .accountType("CHECKING")
                .balance(500.0)
                .customerId(2L)
                .createdDate(LocalDateTime.now())
                .build();

        mockTransaction = Transaction.builder()
                .id(1L)
                .fromAccountId(1L)
                .toAccountId(2L)
                .amount(100.0)
                .transactionDate(LocalDateTime.now())
                .status("COMPLETED")
                .description("Chuyển khoản nội bộ")
                .build();

        // Thiết lập giá trị cho thuộc tính private coreBankingApiUrl
        ReflectionTestUtils.setField(transactionService, "coreBankingApiUrl", "http://localhost:9999");
    }

    @Test
    void testPerformTransfer_Success() {
        // Given
        Long fromAccountId = 1L;
        Long toAccountId = 2L;
        Double amount = 100.0;

        // Mock các repository calls
        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.of(fromAccount));
        when(accountRepository.findById(toAccountId)).thenReturn(Optional.of(toAccount));
        
        // Mock Core Banking API response
        ResponseEntity<String> coreResponse = new ResponseEntity<>("OK", HttpStatus.OK);
        when(restTemplate.postForEntity(anyString(), any(), eq(String.class)))
                .thenReturn(coreResponse);
        
        // Mock transaction save
        when(transactionRepository.save(any(Transaction.class))).thenReturn(mockTransaction);

        // When
        Transaction result = transactionService.performTransfer(fromAccountId, amount, toAccountId);

        // Then
        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals("COMPLETED", result.getStatus());
        assertEquals(100.0, result.getAmount());

        // Verify balance changes
        assertEquals(900.0, fromAccount.getBalance()); // 1000 - 100
        assertEquals(600.0, toAccount.getBalance());   // 500 + 100

        // Verify repository interactions
        verify(accountRepository, times(1)).findById(fromAccountId);
        verify(accountRepository, times(1)).findById(toAccountId);
        verify(accountRepository, times(2)).save(any(Account.class));
        verify(transactionRepository, times(1)).save(any(Transaction.class));
        verify(rabbitTemplate, times(1)).convertAndSend(eq("notificationQueue"), anyString());
    }

    @Test
    void testPerformTransfer_FromAccountNotFound() {
        // Given
        Long fromAccountId = 999L;
        Long toAccountId = 2L;
        Double amount = 100.0;

        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.empty());

        // When & Then
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            transactionService.performTransfer(fromAccountId, amount, toAccountId);
        });

        assertEquals("Tài khoản nguồn không tồn tại!", exception.getMessage());
        
        // Verify no further interactions
        verify(accountRepository, times(1)).findById(fromAccountId);
        verify(accountRepository, never()).findById(toAccountId);
        verify(accountRepository, never()).save(any(Account.class));
        verify(transactionRepository, never()).save(any(Transaction.class));
    }

    @Test
    void testPerformTransfer_ToAccountNotFound() {
        // Given
        Long fromAccountId = 1L;
        Long toAccountId = 999L;
        Double amount = 100.0;

        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.of(fromAccount));
        when(accountRepository.findById(toAccountId)).thenReturn(Optional.empty());

        // When & Then
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            transactionService.performTransfer(fromAccountId, amount, toAccountId);
        });

        assertEquals("Tài khoản đích không tồn tại!", exception.getMessage());
        
        // Verify interactions
        verify(accountRepository, times(1)).findById(fromAccountId);
        verify(accountRepository, times(1)).findById(toAccountId);
        verify(accountRepository, never()).save(any(Account.class));
        verify(transactionRepository, never()).save(any(Transaction.class));
    }

    @Test
    void testPerformTransfer_InsufficientBalance() {
        // Given
        Long fromAccountId = 1L;
        Long toAccountId = 2L;
        Double amount = 1500.0; // Lớn hơn số dư (1000.0)

        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.of(fromAccount));
        when(accountRepository.findById(toAccountId)).thenReturn(Optional.of(toAccount));

        // When & Then
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            transactionService.performTransfer(fromAccountId, amount, toAccountId);
        });

        assertEquals("Số dư không đủ để thực hiện giao dịch!", exception.getMessage());
        
        // Verify interactions
        verify(accountRepository, times(1)).findById(fromAccountId);
        verify(accountRepository, times(1)).findById(toAccountId);
        verify(accountRepository, never()).save(any(Account.class));
        verify(transactionRepository, never()).save(any(Transaction.class));
    }

    @Test
    void testPerformTransfer_CoreBankingRejects() {
        // Given
        Long fromAccountId = 1L;
        Long toAccountId = 2L;
        Double amount = 100.0;

        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.of(fromAccount));
        when(accountRepository.findById(toAccountId)).thenReturn(Optional.of(toAccount));
        
        // Mock Core Banking API rejection
        ResponseEntity<String> coreResponse = new ResponseEntity<>("REJECTED", HttpStatus.BAD_REQUEST);
        when(restTemplate.postForEntity(anyString(), any(), eq(String.class)))
                .thenReturn(coreResponse);

        // When & Then
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            transactionService.performTransfer(fromAccountId, amount, toAccountId);
        });

        assertEquals("Giao dịch bị Core Banking từ chối.", exception.getMessage());
        
        // Verify interactions - accounts should not be updated
        verify(accountRepository, times(1)).findById(fromAccountId);
        verify(accountRepository, times(1)).findById(toAccountId);
        verify(accountRepository, never()).save(any(Account.class));
        verify(transactionRepository, never()).save(any(Transaction.class));
        verify(rabbitTemplate, never()).convertAndSend(anyString(), anyString());
    }

    @Test
    void testPerformTransfer_ZeroAmount() {
        // Given
        Long fromAccountId = 1L;
        Long toAccountId = 2L;
        Double amount = 0.0;

        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.of(fromAccount));
        when(accountRepository.findById(toAccountId)).thenReturn(Optional.of(toAccount));
        
        // Mock Core Banking API success
        ResponseEntity<String> coreResponse = new ResponseEntity<>("OK", HttpStatus.OK);
        when(restTemplate.postForEntity(anyString(), any(), eq(String.class)))
                .thenReturn(coreResponse);
        
        when(transactionRepository.save(any(Transaction.class))).thenReturn(mockTransaction);

        // When
        Transaction result = transactionService.performTransfer(fromAccountId, amount, toAccountId);

        // Then
        assertNotNull(result);
        
        // Verify balances remain unchanged for zero amount
        assertEquals(1000.0, fromAccount.getBalance()); // Unchanged
        assertEquals(500.0, toAccount.getBalance());    // Unchanged
        
        verify(accountRepository, times(2)).save(any(Account.class));
        verify(transactionRepository, times(1)).save(any(Transaction.class));
    }

    @Test
    void testPerformTransfer_NegativeAmount() {
        // Given
        Long fromAccountId = 1L;
        Long toAccountId = 2L;
        Double amount = -100.0;

        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.of(fromAccount));
        when(accountRepository.findById(toAccountId)).thenReturn(Optional.of(toAccount));
        
        // Mock Core Banking API success
        ResponseEntity<String> coreResponse = new ResponseEntity<>("OK", HttpStatus.OK);
        when(restTemplate.postForEntity(anyString(), any(), eq(String.class)))
                .thenReturn(coreResponse);
        
        when(transactionRepository.save(any(Transaction.class))).thenReturn(mockTransaction);

        // When
        Transaction result = transactionService.performTransfer(fromAccountId, amount, toAccountId);

        // Then
        assertNotNull(result);
        
        // Verify balances change according to negative amount
        assertEquals(1100.0, fromAccount.getBalance()); // 1000 - (-100) = 1100
        assertEquals(400.0, toAccount.getBalance());    // 500 + (-100) = 400
        
        verify(accountRepository, times(2)).save(any(Account.class));
        verify(transactionRepository, times(1)).save(any(Transaction.class));
    }

    @Test
    void testPerformTransfer_SameAccount() {
        // Given - Chuyển tiền cho chính tài khoản của mình
        Long fromAccountId = 1L;
        Long toAccountId = 1L; // Same account
        Double amount = 100.0;

        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.of(fromAccount));
        // toAccount sẽ là cùng instance với fromAccount

        // Mock Core Banking API success
        ResponseEntity<String> coreResponse = new ResponseEntity<>("OK", HttpStatus.OK);
        when(restTemplate.postForEntity(anyString(), any(), eq(String.class)))
                .thenReturn(coreResponse);
        
        when(transactionRepository.save(any(Transaction.class))).thenReturn(mockTransaction);

        // When
        Transaction result = transactionService.performTransfer(fromAccountId, amount, toAccountId);

        // Then
        assertNotNull(result);
        
        // Verify balance remains unchanged (transfer to same account)
        assertEquals(1000.0, fromAccount.getBalance()); // Balance should remain same: 1000 - 100 + 100 = 1000
        
        verify(accountRepository, times(2)).findById(fromAccountId); // Called twice for from and to
        verify(accountRepository, times(2)).save(any(Account.class)); // Save called twice
        verify(transactionRepository, times(1)).save(any(Transaction.class));
    }

    @Test
    void testPerformTransfer_LargeAmount() {
        // Given
        Long fromAccountId = 1L;
        Long toAccountId = 2L;
        Double amount = 999.99; // Gần hết số dư

        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.of(fromAccount));
        when(accountRepository.findById(toAccountId)).thenReturn(Optional.of(toAccount));
        
        // Mock Core Banking API success
        ResponseEntity<String> coreResponse = new ResponseEntity<>("OK", HttpStatus.OK);
        when(restTemplate.postForEntity(anyString(), any(), eq(String.class)))
                .thenReturn(coreResponse);
        
        when(transactionRepository.save(any(Transaction.class))).thenReturn(mockTransaction);

        // When
        Transaction result = transactionService.performTransfer(fromAccountId, amount, toAccountId);

        // Then
        assertNotNull(result);
        
        // Verify balance changes
        assertEquals(0.01, fromAccount.getBalance(), 0.001); // 1000 - 999.99 = 0.01
        assertEquals(1499.99, toAccount.getBalance(), 0.001); // 500 + 999.99 = 1499.99
        
        verify(accountRepository, times(2)).save(any(Account.class));
        verify(transactionRepository, times(1)).save(any(Transaction.class));
        verify(rabbitTemplate, times(1)).convertAndSend(eq("notificationQueue"), anyString());
    }

    @Test
    void testPerformTransfer_VerifyTransactionFields() {
        // Given
        Long fromAccountId = 1L;
        Long toAccountId = 2L;
        Double amount = 100.0;

        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.of(fromAccount));
        when(accountRepository.findById(toAccountId)).thenReturn(Optional.of(toAccount));
        
        // Mock Core Banking API success
        ResponseEntity<String> coreResponse = new ResponseEntity<>("OK", HttpStatus.OK);
        when(restTemplate.postForEntity(anyString(), any(), eq(String.class)))
                .thenReturn(coreResponse);
        
        when(transactionRepository.save(any(Transaction.class))).thenReturn(mockTransaction);

        // When
        Transaction result = transactionService.performTransfer(fromAccountId, amount, toAccountId);

        // Then
        assertNotNull(result);
        assertEquals(fromAccountId, result.getFromAccountId());
        assertEquals(toAccountId, result.getToAccountId());
        assertEquals(amount, result.getAmount());
        assertEquals("COMPLETED", result.getStatus());
        assertEquals("Chuyển khoản nội bộ", result.getDescription());
        assertNotNull(result.getTransactionDate());
        
        // Verify save was called with correct transaction data
        verify(transactionRepository, times(1)).save(argThat(transaction -> 
            transaction.getFromAccountId().equals(fromAccountId) &&
            transaction.getToAccountId().equals(toAccountId) &&
            transaction.getAmount().equals(amount) &&
            transaction.getStatus().equals("COMPLETED") &&
            transaction.getDescription().equals("Chuyển khoản nội bộ") &&
            transaction.getTransactionDate() != null
        ));
    }

    @Test
    void testPerformTransfer_VerifyRabbitMQMessage() {
        // Given
        Long fromAccountId = 1L;
        Long toAccountId = 2L;
        Double amount = 100.0;

        when(accountRepository.findById(fromAccountId)).thenReturn(Optional.of(fromAccount));
        when(accountRepository.findById(toAccountId)).thenReturn(Optional.of(toAccount));
        
        // Mock Core Banking API success
        ResponseEntity<String> coreResponse = new ResponseEntity<>("OK", HttpStatus.OK);
        when(restTemplate.postForEntity(anyString(), any(), eq(String.class)))
                .thenReturn(coreResponse);
        
        when(transactionRepository.save(any(Transaction.class))).thenReturn(mockTransaction);

        // When
        transactionService.performTransfer(fromAccountId, amount, toAccountId);

        // Then - Verify RabbitMQ message content
        verify(rabbitTemplate, times(1)).convertAndSend(
            eq("notificationQueue"), 
            argThat((String message) -> {
                String expectedMessage = "Giao dịch thành công với ID: " + mockTransaction.getId() + 
                                       ", Số tiền: " + amount + 
                                       ", Từ tài khoản: " + fromAccount.getAccountNumber() + 
                                       " đến tài khoản: " + toAccount.getAccountNumber();
                return message.equals(expectedMessage);
            })
        );
    }
}
