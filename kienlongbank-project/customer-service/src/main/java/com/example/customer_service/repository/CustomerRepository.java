package com.example.customer_service.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.customer_service.model.Customer;
import java.util.Optional;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Long> {
    
    /**
     * Find customer by email address
     * @param email the email to search for
     * @return Optional containing the customer if found
     */
    Optional<Customer> findByEmail(String email);
    
    /**
     * Check if customer exists by email
     * @param email the email to check
     * @return true if customer with email exists
     */
    boolean existsByEmail(String email);
    
    /**
     * 🔐 Find customer by Keycloak ID
     * Used for JWT authentication-based lookups
     * @param keycloakId the Keycloak user ID from JWT subject
     * @return Customer entity if found, null otherwise
     */
    Optional<Customer> findByKeycloakId(String keycloakId);
    
    /**
     * Check if customer exists by Keycloak ID
     * @param keycloakId the Keycloak user ID to check
     * @return true if customer with keycloakId exists
     */
    boolean existsByKeycloakId(String keycloakId);
    
    // Có thể thêm các phương thức tìm kiếm phức tạp hơn ở đây sau này
}
