package com.example.customer_service.controller;

import com.example.customer_service.dto.CreateCustomerRequest;
import com.example.customer_service.dto.CustomerResponse;
import com.example.customer_service.dto.UpdateCustomerRequest;
import com.example.customer_service.mapper.CustomerMapper;
import com.example.customer_service.model.Customer;
import com.example.customer_service.service.CustomerService;
import com.kienlongbank.common.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 🏦 Customer Controller - REST API endpoints for customer management
 * <p>
 * This controller handles external HTTP requests from clients (e.g., Frontend).
 * It uses the "legacyCustomerService" for direct business logic and the CustomerMapper
 * for converting between DTOs and Entities.
 *
 * @version 3.0
 * @since August 2025
 */
@RestController
@RequestMapping("/api/customers")
@Tag(name = "Customer Management", description = "APIs for managing customers")
public class CustomerController {

    private final CustomerService customerService;
    private final CustomerMapper customerMapper;

    // Sử dụng Constructor Injection cho cả Service và Mapper.
    public CustomerController(@Qualifier("legacyCustomerService") CustomerService customerService, CustomerMapper customerMapper) {
        this.customerService = customerService;
        this.customerMapper = customerMapper;
    }

    @GetMapping
    @Operation(summary = "Get all customers", description = "Retrieve a list of all customers")
    public ApiResponse<List<CustomerResponse>> getAllCustomers() {
        List<Customer> customers = customerService.getAllCustomers();
        List<CustomerResponse> responses = customers.stream()
                .map(customerMapper::toResponse)
                .collect(Collectors.toList());
        return ApiResponse.success(responses, "Lấy danh sách khách hàng thành công");
    }

    @PostMapping
    @Operation(summary = "Create a new customer", description = "Create a new customer with the provided information")
    public ApiResponse<CustomerResponse> createCustomer(@Valid @RequestBody CreateCustomerRequest request) {
        // 1. Chuyển đổi DTO (request) thành Entity
        Customer customerToCreate = customerMapper.toEntity(request);
        
        // 2. Gọi service để lưu Entity
        Customer createdCustomer = customerService.createCustomer(customerToCreate);
        
        // 3. Chuyển đổi Entity kết quả thành DTO Response
        CustomerResponse response = customerMapper.toResponse(createdCustomer);
        
        return ApiResponse.success(response, "Tạo khách hàng thành công");
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get customer by ID", description = "Retrieve a customer by their unique ID")
    public ApiResponse<CustomerResponse> getCustomerById(@Parameter(description = "Customer ID") @PathVariable Long id) {
        Customer customer = customerService.getCustomerById(id);
        CustomerResponse response = customerMapper.toResponse(customer);
        return ApiResponse.success(response, "Lấy thông tin khách hàng thành công");
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update customer", description = "Update an existing customer's information")
    public ApiResponse<CustomerResponse> updateCustomer(@Parameter(description = "Customer ID") @PathVariable Long id, @Valid @RequestBody UpdateCustomerRequest request) {
        // 1. Tìm khách hàng hiện tại
        Customer existingCustomer = customerService.getCustomerById(id);
        
        // 2. Cập nhật thông tin từ DTO vào Entity
        customerMapper.updateEntity(existingCustomer, request);
        
        // 3. Gọi service để lưu lại
        Customer updatedCustomer = customerService.updateCustomer(id, existingCustomer);
        
        CustomerResponse response = customerMapper.toResponse(updatedCustomer);
        return ApiResponse.success(response, "Cập nhật khách hàng thành công");
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a customer", description = "Delete a customer by their ID")
    public ApiResponse<Void> deleteCustomer(@Parameter(description = "Customer ID") @PathVariable Long id) {
        customerService.deleteCustomer(id);
        return ApiResponse.success(null, "Xóa khách hàng thành công");
    }

    @GetMapping("/my-info")
    @Operation(summary = "Get my personal information", description = "Get current user's personal information from their authentication token.")
    public ApiResponse<CustomerResponse> getMyInfo(@AuthenticationPrincipal Jwt jwt) {
        String keycloakId = jwt.getSubject();
        Customer customer = customerService.getCustomerByKeycloakId(keycloakId);
        CustomerResponse response = customerMapper.toResponse(customer);
        return ApiResponse.success(response, "Lấy thông tin cá nhân thành công");
    }
}