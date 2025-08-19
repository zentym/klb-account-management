package com.example.customer_service.service.impl;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import org.mockito.Mock;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.mockito.MockitoAnnotations;
import org.springframework.boot.test.context.SpringBootTest;

import com.example.customer_service.model.Customer;
import com.example.customer_service.repository.CustomerRepository;
import com.kienlongbank.common.api.CustomerApi;
import com.kienlongbank.common.dto.CustomerDTO;

/**
 * 🧪 Customer Service Implementation Test
 * 
 * 🎯 Purpose: Test CustomerServiceImpl implementation of CustomerApi interface
 * 📊 Coverage: Basic CRUD operations and data conversion
 * 🔧 Framework: JUnit 5 + Mockito
 * 
 * @author GitHub Copilot
 * @version 1.0
 * @since August 2025
 */
@SpringBootTest
class CustomerServiceImplTest {

    @Mock
    private CustomerRepository customerRepository;

    private CustomerApi customerService;
    private Customer testCustomer;
    private CustomerDTO testCustomerDTO;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        customerService = new CustomerServiceImpl(customerRepository);
        
        // Setup test data
        testCustomer = new Customer();
        try {
            // Use reflection to set values safely
            testCustomer.getClass().getMethod("setId", Long.class).invoke(testCustomer, 1L);
            testCustomer.getClass().getMethod("setFullName", String.class).invoke(testCustomer, "Nguyen Van A");
            testCustomer.getClass().getMethod("setEmail", String.class).invoke(testCustomer, "nguyenvana@example.com");
            testCustomer.getClass().getMethod("setPhone", String.class).invoke(testCustomer, "0901234567");
            testCustomer.getClass().getMethod("setAddress", String.class).invoke(testCustomer, "123 ABC Street");
        } catch (Exception e) {
            // If reflection fails, create a simple customer for testing
            System.err.println("Error setting up test customer: " + e.getMessage());
        }
        
        testCustomerDTO = new CustomerDTO();
        testCustomerDTO.setId(1L);
        testCustomerDTO.setFullName("Nguyen Van A");
        testCustomerDTO.setEmail("nguyenvana@example.com");
        testCustomerDTO.setPhoneNumber("0901234567");
        testCustomerDTO.setAddress("123 ABC Street");
    }

    @Test
    void testFindCustomerById_Success() {
        // Given
        when(customerRepository.findById(1L)).thenReturn(Optional.of(testCustomer));
        
        // When
        CustomerDTO result = customerService.findCustomerById(1L);
        
        // Then
        assertNotNull(result);
        assertEquals("nguyenvana@example.com", result.getEmail());
        verify(customerRepository).findById(1L);
    }

    @Test
    void testFindCustomerById_NotFound() {
        // Given
        when(customerRepository.findById(anyLong())).thenReturn(Optional.empty());
        
        // When
        CustomerDTO result = customerService.findCustomerById(999L);
        
        // Then
        assertNull(result);
        verify(customerRepository).findById(999L);
    }

    @Test
    void testFindCustomerByEmail_Success() {
        // Given
        when(customerRepository.findByEmail("nguyenvana@example.com")).thenReturn(Optional.of(testCustomer));
        
        // When
        CustomerDTO result = customerService.findCustomerByEmail("nguyenvana@example.com");
        
        // Then
        assertNotNull(result);
        assertEquals("Nguyen Van A", result.getFullName());
        verify(customerRepository).findByEmail("nguyenvana@example.com");
    }

    @Test
    void testExistsById() {
        // Given
        when(customerRepository.existsById(1L)).thenReturn(true);
        when(customerRepository.existsById(999L)).thenReturn(false);
        
        // When & Then
        assertTrue(customerService.existsById(1L));
        assertFalse(customerService.existsById(999L));
        
        verify(customerRepository).existsById(1L);
        verify(customerRepository).existsById(999L);
    }

    @Test
    void testExistsByEmail() {
        // Given
        when(customerRepository.existsByEmail("existing@example.com")).thenReturn(true);
        when(customerRepository.existsByEmail("nonexistent@example.com")).thenReturn(false);
        
        // When & Then
        assertTrue(customerService.existsByEmail("existing@example.com"));
        assertFalse(customerService.existsByEmail("nonexistent@example.com"));
        
        verify(customerRepository).existsByEmail("existing@example.com");
        verify(customerRepository).existsByEmail("nonexistent@example.com");
    }

    @Test
    void testCreateCustomer_Success() {
        // Given
        when(customerRepository.existsByEmail(any())).thenReturn(false);
        when(customerRepository.save(any())).thenReturn(testCustomer);
        
        // When
        CustomerDTO result = customerService.createCustomer(testCustomerDTO);
        
        // Then
        assertNotNull(result);
        assertEquals("Nguyen Van A", result.getFullName());
        verify(customerRepository).existsByEmail("nguyenvana@example.com");
        verify(customerRepository).save(any());
    }

    @Test
    void testCreateCustomer_EmailAlreadyExists() {
        // Given
        when(customerRepository.existsByEmail("nguyenvana@example.com")).thenReturn(true);
        
        // When & Then
        assertThrows(RuntimeException.class, () -> {
            customerService.createCustomer(testCustomerDTO);
        });
        
        verify(customerRepository).existsByEmail("nguyenvana@example.com");
        verify(customerRepository, never()).save(any());
    }

    @Test
    void testDeleteCustomer_Success() {
        // Given
        when(customerRepository.existsById(1L)).thenReturn(true);
        doNothing().when(customerRepository).deleteById(1L);
        
        // When
        boolean result = customerService.deleteCustomer(1L);
        
        // Then
        assertTrue(result);
        verify(customerRepository).existsById(1L);
        verify(customerRepository).deleteById(1L);
    }

    @Test
    void testDeleteCustomer_NotFound() {
        // Given
        when(customerRepository.existsById(999L)).thenReturn(false);
        
        // When
        boolean result = customerService.deleteCustomer(999L);
        
        // Then
        assertFalse(result);
        verify(customerRepository).existsById(999L);
        verify(customerRepository, never()).deleteById(any());
    }

    @Test
    void testGetTotalCustomerCount() {
        // Given
        when(customerRepository.count()).thenReturn(5L);
        
        // When
        long result = customerService.getTotalCustomerCount();
        
        // Then
        assertEquals(5L, result);
        verify(customerRepository).count();
    }
}
