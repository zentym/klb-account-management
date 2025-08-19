package com.kienlongbank.common.api;

import java.util.List;
import java.util.Optional;

import com.kienlongbank.common.dto.CustomerDTO;

/**
 * Customer API interface defining operations that customer-service provides
 * This interface can be implemented by customer-service and used by other services
 * for inter-service communication
 */
public interface CustomerApi {
    
    /**
     * Find customer by ID
     * 
     * @param customerId the customer ID to search for
     * @return CustomerDTO if found, null if not found
     */
    CustomerDTO findCustomerById(Long customerId);
    
    /**
     * Find customer by ID with Optional wrapper
     * 
     * @param customerId the customer ID to search for
     * @return Optional containing CustomerDTO if found, empty Optional otherwise
     */
    Optional<CustomerDTO> findCustomerByIdOptional(Long customerId);
    
    /**
     * Find customer by email
     * 
     * @param email the customer email to search for
     * @return CustomerDTO if found, null if not found
     */
    CustomerDTO findCustomerByEmail(String email);
    
    /**
     * Find customer by ID number (National ID, Passport, etc.)
     * 
     * @param idNumber the customer ID number to search for
     * @return CustomerDTO if found, null if not found
     */
    CustomerDTO findCustomerByIdNumber(String idNumber);
    
    /**
     * Check if customer exists by ID
     * 
     * @param customerId the customer ID to check
     * @return true if customer exists, false otherwise
     */
    boolean existsById(Long customerId);
    
    /**
     * Check if customer exists by email
     * 
     * @param email the customer email to check
     * @return true if customer exists, false otherwise
     */
    boolean existsByEmail(String email);
    
    /**
     * Get all customers with pagination
     * 
     * @param page page number (0-based)
     * @param size page size
     * @return list of CustomerDTO
     */
    List<CustomerDTO> findAllCustomers(int page, int size);
    
    /**
     * Find customers by status
     * 
     * @param status customer status (ACTIVE, INACTIVE, BLOCKED)
     * @return list of CustomerDTO with the specified status
     */
    List<CustomerDTO> findCustomersByStatus(String status);
    
    /**
     * Find customers by customer type
     * 
     * @param customerType customer type (INDIVIDUAL, CORPORATE)
     * @return list of CustomerDTO with the specified type
     */
    List<CustomerDTO> findCustomersByType(String customerType);
    
    /**
     * Create a new customer
     * 
     * @param customerDTO customer data to create
     * @return created CustomerDTO with generated ID
     */
    CustomerDTO createCustomer(CustomerDTO customerDTO);
    
    /**
     * Update existing customer
     * 
     * @param customerId ID of customer to update
     * @param customerDTO updated customer data
     * @return updated CustomerDTO
     */
    CustomerDTO updateCustomer(Long customerId, CustomerDTO customerDTO);
    
    /**
     * Delete customer by ID
     * 
     * @param customerId ID of customer to delete
     * @return true if deleted successfully, false if customer not found
     */
    boolean deleteCustomer(Long customerId);
    
    /**
     * Update customer status
     * 
     * @param customerId ID of customer to update
     * @param status new status (ACTIVE, INACTIVE, BLOCKED)
     * @return updated CustomerDTO
     */
    CustomerDTO updateCustomerStatus(Long customerId, String status);
    
    /**
     * Get total count of customers
     * 
     * @return total number of customers
     */
    long getTotalCustomerCount();
    
    /**
     * Search customers by full name (partial match)
     * 
     * @param fullName full name to search for (partial match)
     * @param page page number (0-based)
     * @param size page size
     * @return list of CustomerDTO matching the search criteria
     */
    List<CustomerDTO> searchCustomersByFullName(String fullName, int page, int size);
}
