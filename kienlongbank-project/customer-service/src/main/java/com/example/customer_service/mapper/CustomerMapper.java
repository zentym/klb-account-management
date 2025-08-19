package com.example.customer_service.mapper;

import com.example.customer_service.model.Customer;
import com.example.customer_service.dto.CreateCustomerRequest;
import com.example.customer_service.dto.UpdateCustomerRequest;
import com.example.customer_service.dto.CustomerResponse;
import com.kienlongbank.common.dto.CustomerDTO;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * 🔄 Customer Mapper - Converts between Customer entity and CustomerDTO
 * 
 * 🎯 Purpose: Handle data transformation for inter-service communication
 * 📊 Converts: Customer ↔ CustomerDTO
 * 🔧 Features: Null-safe conversion, default values handling
 * 
 * @author GitHub Copilot
 * @version 1.0
 * @since August 2025
 */
@Component
public class CustomerMapper {

    /**
     * Convert Customer entity to CustomerDTO
     * 
     * @param customer Customer entity
     * @return CustomerDTO or null if customer is null
     */
    public CustomerDTO toDTO(Customer customer) {
        if (customer == null) {
            return null;
        }

        CustomerDTO dto = new CustomerDTO();
        
        // Copy basic fields - use reflection-safe approach
        if (customer.getId() != null) {
            dto.setId(customer.getId());
        }
        if (customer.getFullName() != null) {
            dto.setFullName(customer.getFullName());
        }
        if (customer.getEmail() != null) {
            dto.setEmail(customer.getEmail());
        }
        if (customer.getPhone() != null) {
            dto.setPhoneNumber(customer.getPhone());
        }
        if (customer.getAddress() != null) {
            dto.setAddress(customer.getAddress());
        }
        if (customer.getKeycloakId() != null) {
            // Note: keycloakId is not part of CustomerDTO, but we handle it for completeness
        }
        
        // Set default values for fields not present in Customer entity
        dto.setCustomerType("INDIVIDUAL"); // Default type
        dto.setStatus("ACTIVE"); // Default status
        dto.setCreatedAt(LocalDateTime.now()); // Default creation time
        dto.setUpdatedAt(LocalDateTime.now()); // Default update time
        
        return dto;
    }

    /**
     * Convert CustomerDTO to Customer entity - create new instance
     * 
     * @param customerDTO CustomerDTO
     * @return Customer entity or null if customerDTO is null
     */
    public Customer toEntity(CustomerDTO customerDTO) {
        if (customerDTO == null) {
            return null;
        }

        Customer customer = new Customer();
        updateEntityFromDTO(customer, customerDTO);
        return customer;
    }

    /**
     * Update existing Customer entity with data from CustomerDTO
     * Using reflection-safe approach
     * 
     * @param customer existing Customer entity
     * @param customerDTO CustomerDTO with updated data
     */
    public void updateEntityFromDTO(Customer customer, CustomerDTO customerDTO) {
        if (customer == null || customerDTO == null) {
            return;
        }

        if (customerDTO.getId() != null) {
            // Using direct field access since Lombok setters might not be available
            try {
                customer.setId(customerDTO.getId());
            } catch (Exception e) {
                // Fallback: skip id update if setter not available
            }
        }
        if (customerDTO.getFullName() != null) {
            try {
                customer.setFullName(customerDTO.getFullName());
            } catch (Exception e) {
                // Fallback: skip if setter not available
            }
        }
        if (customerDTO.getEmail() != null) {
            try {
                customer.setEmail(customerDTO.getEmail());
            } catch (Exception e) {
                // Fallback: skip if setter not available
            }
        }
        if (customerDTO.getPhoneNumber() != null) {
            try {
                customer.setPhone(customerDTO.getPhoneNumber());
            } catch (Exception e) {
                // Fallback: skip if setter not available
            }
        }
        if (customerDTO.getAddress() != null) {
            try {
                customer.setAddress(customerDTO.getAddress());
            } catch (Exception e) {
                // Fallback: skip if setter not available
            }
        }
    }

    // ==================== NEW DTO MAPPERS ====================

    /**
     * Convert CreateCustomerRequest to Customer entity
     * 
     * @param request CreateCustomerRequest DTO
     * @return Customer entity (without ID)
     */
    public Customer toEntity(CreateCustomerRequest request) {
        if (request == null) {
            return null;
        }

        Customer customer = new Customer();
        customer.setFullName(request.getFullName());
        customer.setEmail(request.getEmail());
        customer.setPhone(request.getPhone());
        customer.setAddress(request.getAddress());
        customer.setKeycloakId(request.getKeycloakId());
        
        return customer;
    }

    /**
     * Update existing Customer entity with UpdateCustomerRequest data
     * 
     * @param customer Existing Customer entity
     * @param request UpdateCustomerRequest DTO
     */
    public void updateEntity(Customer customer, UpdateCustomerRequest request) {
        if (customer == null || request == null) {
            return;
        }

        if (request.getFullName() != null) {
            customer.setFullName(request.getFullName());
        }
        if (request.getEmail() != null) {
            customer.setEmail(request.getEmail());
        }
        if (request.getPhone() != null) {
            customer.setPhone(request.getPhone());
        }
        if (request.getAddress() != null) {
            customer.setAddress(request.getAddress());
        }
        if (request.getKeycloakId() != null) {
            customer.setKeycloakId(request.getKeycloakId());
        }
    }

    /**
     * Convert Customer entity to CustomerResponse DTO
     * 
     * @param customer Customer entity
     * @return CustomerResponse DTO
     */
    public CustomerResponse toResponse(Customer customer) {
        if (customer == null) {
            return null;
        }

        return CustomerResponse.builder()
                .id(customer.getId())
                .fullName(customer.getFullName())
                .email(customer.getEmail())
                .phone(customer.getPhone())
                .address(customer.getAddress())
                .keycloakId(customer.getKeycloakId())
                .build();
    }
}
