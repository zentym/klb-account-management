package com.example.customer_service.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.customer_service.model.Customer;
import com.example.customer_service.repository.CustomerRepository;
import com.example.customer_service.exception.CustomerNotFoundException;

/**
 * 🏦 Legacy Customer Service - Original customer service implementation
 * 
 * 🔄 Status: This service is being replaced by CustomerServiceImpl
 * ⚠️ Note: Keep for backward compatibility and REST controller operations
 * 📍 Future: Consider using CustomerServiceImpl (implements CustomerApi) for new features
 * 
 * @author GitHub Copilot
 * @version 1.0 (Legacy)
 * @since August 2025
 */
@Service("legacyCustomerService")
public class CustomerService {

    @Autowired
    private CustomerRepository customerRepository;
    
    // Default constructor
    public CustomerService() {}
    
    // Constructor with repository
    public CustomerService(CustomerRepository customerRepository) {
        this.customerRepository = customerRepository;
    }

    public List<Customer> getAllCustomers() {
        return customerRepository.findAll();
    }

    public Customer createCustomer(Customer customer) {
        // (Nâng cao sau) Có thể thêm logic kiểm tra email đã tồn tại chưa
        return customerRepository.save(customer);
    }

    // Thêm các hàm getCustomerById, updateCustomer, deleteCustomer...
    public Customer getCustomerById(Long id) {
        return customerRepository.findById(id)
                .orElseThrow(() -> new CustomerNotFoundException("Khách hàng không tồn tại với ID: " + id));
    }
    
    /**
     * 🔐 Find customer by Keycloak ID
     * Used for JWT authentication-based lookups
     * 
     * @param keycloakId Keycloak user ID from JWT subject
     * @return Customer entity or null if not found
     */
    public Customer getCustomerByKeycloakId(String keycloakId) {
    if (keycloakId == null || keycloakId.trim().isEmpty()) {
        throw new IllegalArgumentException("Keycloak ID cannot be null or empty");
    }
    
    // Dùng Optional để xử lý, nếu không có sẽ ném ra exception
    return customerRepository.findByKeycloakId(keycloakId)
            .orElseThrow(() -> new CustomerNotFoundException("Khách hàng không tồn tại với Keycloak ID: " + keycloakId));
}
    
    public Customer updateCustomer(Long id, Customer customer) {
        if (customerRepository.existsById(id)) {
            // Use reflection to safely set ID
            try {
                customer.getClass().getMethod("setId", Long.class).invoke(customer, id);
            } catch (Exception e) {
                // If reflection fails, the customer entity should handle ID assignment
            }
            return customerRepository.save(customer);
        }
        return null; // Hoặc ném ngoại lệ nếu không tìm thấy
    }
    
    public void deleteCustomer(Long id) {
        customerRepository.deleteById(id);
    }
}
