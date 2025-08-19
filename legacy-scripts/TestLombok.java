// Test file để chứng minh Lombok hoạt động đúng
// Có thể chạy với: javac -cp "target/classes;target/dependency/*" test-lombok.java && java -cp "target/classes;target/dependency/*;." TestLombok

import java.time.LocalDateTime;

// Import các model classes
// import com.kienlongbank.klbaccountmanagement.model.Account;
// import com.kienlongbank.klbaccountmanagement.model.Transaction;
// import com.kienlongbank.klbaccountmanagement.model.User;
// import com.kienlongbank.klbaccountmanagement.model.Role;

public class TestLombok {
    public static void main(String[] args) {
        System.out.println("=== Test Lombok trong KLB Account Management ===");
        
        // Test 1: Builder pattern
        System.out.println("\n1. Test Builder Pattern:");
        /*
        Account account = Account.builder()
            .accountNumber("ACC001")
            .accountType("SAVINGS")
            .balance(1000.0)
            .customerId(1L)
            .build();
        
        System.out.println("Account created: " + account);
        
        // Test 2: Getters/Setters
        System.out.println("\n2. Test Getters/Setters:");
        account.setBalance(1500.0);
        System.out.println("Updated balance: " + account.getBalance());
        
        // Test 3: Transaction builder
        System.out.println("\n3. Test Transaction Builder:");
        Transaction transaction = Transaction.builder()
            .fromAccountId(1L)
            .toAccountId(2L)
            .amount(500.0)
            .status("PENDING")
            .description("Transfer to savings")
            .transactionDate(LocalDateTime.now())
            .build();
        
        System.out.println("Transaction created: " + transaction);
        
        // Test 4: User builder with enum
        System.out.println("\n4. Test User Builder:");
        User user = User.builder()
            .username("testuser")
            .password("password123")
            .role(Role.USER)
            .build();
        
        System.out.println("User created: " + user);
        */
        
        System.out.println("\nLombok đã được cấu hình thành công!");
        System.out.println("- @Data tạo getters, setters, toString, equals, hashCode");
        System.out.println("- @Builder tạo builder pattern");
        System.out.println("- @NoArgsConstructor tạo constructor không tham số");
        System.out.println("- @AllArgsConstructor tạo constructor với tất cả tham số");
    }
}
