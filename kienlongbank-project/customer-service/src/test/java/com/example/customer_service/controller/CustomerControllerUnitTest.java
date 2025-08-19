package com.example.customer_service.controller;

import com.example.customer_service.model.Customer;
import com.example.customer_service.service.CustomerService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.List;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Unit Test cho CustomerController sử dụng @WebMvcTest
 * Test chỉ Controller layer với MockBean cho Service layer
 * Nhanh hơn integration test vì không load toàn bộ Spring context
 */
@WebMvcTest(CustomerController.class)
public class CustomerControllerUnitTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private CustomerService customerService;

    @Autowired
    private ObjectMapper objectMapper;

    private Customer testCustomer;

    @BeforeEach
    void setUp() {
        testCustomer = Customer.builder()
                .id(1L)
                .fullName("Nguyễn Văn Test")
                .email("test@kienlongbank.com")
                .phone("0901234567")
                .address("123 Test Street")
                .build();
    }

    // ========== TEST GET ALL CUSTOMERS ==========

    @Test
    void testGetAllCustomers_ShouldReturnCustomerList() throws Exception {
        // Arrange
        List<Customer> customers = Arrays.asList(testCustomer);
        when(customerService.getAllCustomers()).thenReturn(customers);

        // Act & Assert
        mockMvc.perform(get("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].id").value(1))
                .andExpect(jsonPath("$.data[0].fullName").value("Nguyễn Văn Test"))
                .andExpect(jsonPath("$.data[0].email").value("test@kienlongbank.com"))
                .andExpect(jsonPath("$.message").value("Lấy danh sách khách hàng thành công"));

        verify(customerService).getAllCustomers();
    }

    @Test
    void testGetAllCustomers_WhenEmpty_ShouldReturnEmptyList() throws Exception {
        // Arrange
        when(customerService.getAllCustomers()).thenReturn(Arrays.asList());

        // Act & Assert
        mockMvc.perform(get("/api/customers"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data", hasSize(0)));

        verify(customerService).getAllCustomers();
    }

    // ========== TEST CREATE CUSTOMER ==========

    @Test
    void testCreateCustomer_WithValidData_ShouldCreateSuccessfully() throws Exception {
        // Arrange
        Customer newCustomer = Customer.builder()
                .fullName("Lê Văn Mới")
                .email("lemoi@test.com")
                .phone("0987654321")
                .address("New Address")
                .build();

        Customer savedCustomer = Customer.builder()
                .id(2L)
                .fullName("Lê Văn Mới")
                .email("lemoi@test.com")
                .phone("0987654321")
                .address("New Address")
                .build();

        when(customerService.createCustomer(any(Customer.class))).thenReturn(savedCustomer);

        String customerJson = objectMapper.writeValueAsString(newCustomer);

        // Act & Assert
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.id").value(2))
                .andExpect(jsonPath("$.data.fullName").value("Lê Văn Mới"))
                .andExpect(jsonPath("$.data.email").value("lemoi@test.com"))
                .andExpect(jsonPath("$.message").value("Tạo khách hàng thành công"));

        verify(customerService).createCustomer(any(Customer.class));
    }

    @Test
    void testCreateCustomer_WithInvalidEmail_ShouldReturnBadRequest() throws Exception {
        // Arrange
        Customer invalidCustomer = Customer.builder()
                .fullName("Test User")
                .email("invalid-email") // Email không hợp lệ
                .phone("0901234567")
                .address("Test Address")
                .build();

        String customerJson = objectMapper.writeValueAsString(invalidCustomer);

        // Act & Assert
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isBadRequest());

        verifyNoInteractions(customerService);
    }

    // ========== TEST GET CUSTOMER BY ID ==========

    @Test
    void testGetCustomerById_WithValidId_ShouldReturnCustomer() throws Exception {
        // Arrange
        when(customerService.getCustomerById(1L)).thenReturn(testCustomer);

        // Act & Assert
        mockMvc.perform(get("/api/customers/{id}", 1L))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.fullName").value("Nguyễn Văn Test"))
                .andExpect(jsonPath("$.data.email").value("test@kienlongbank.com"))
                .andExpect(jsonPath("$.message").value("Lấy thông tin khách hàng thành công"));

        verify(customerService).getCustomerById(1L);
    }

    @Test
    void testGetCustomerById_WithInvalidId_ShouldReturnNullData() throws Exception {
        // Arrange
        when(customerService.getCustomerById(999L)).thenReturn(null);

        // Act & Assert
        mockMvc.perform(get("/api/customers/{id}", 999L))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").doesNotExist())
                .andExpect(jsonPath("$.message").value("Lấy thông tin khách hàng thành công"));

        verify(customerService).getCustomerById(999L);
    }

    // ========== TEST UPDATE CUSTOMER ==========

    @Test
    void testUpdateCustomer_WithValidData_ShouldUpdateSuccessfully() throws Exception {
        // Arrange
        Customer updateData = Customer.builder()
                .fullName("Nguyễn Văn Updated")
                .email("updated@test.com")
                .phone("0999999999")
                .address("Updated Address")
                .build();

        Customer updatedCustomer = Customer.builder()
                .id(1L)
                .fullName("Nguyễn Văn Updated")
                .email("updated@test.com")
                .phone("0999999999")
                .address("Updated Address")
                .build();

        when(customerService.updateCustomer(eq(1L), any(Customer.class))).thenReturn(updatedCustomer);

        String updateJson = objectMapper.writeValueAsString(updateData);

        // Act & Assert
        mockMvc.perform(put("/api/customers/{id}", 1L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateJson))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.fullName").value("Nguyễn Văn Updated"))
                .andExpect(jsonPath("$.data.email").value("updated@test.com"))
                .andExpect(jsonPath("$.message").value("Cập nhật khách hàng thành công"));

        verify(customerService).updateCustomer(eq(1L), any(Customer.class));
    }

    @Test
    void testUpdateCustomer_WithInvalidId_ShouldReturnNullData() throws Exception {
        // Arrange
        Customer updateData = Customer.builder()
                .fullName("Test Name")
                .email("test@example.com")
                .phone("0901234567")
                .address("Test Address")
                .build();

        when(customerService.updateCustomer(eq(999L), any(Customer.class))).thenReturn(null);

        String updateJson = objectMapper.writeValueAsString(updateData);

        // Act & Assert
        mockMvc.perform(put("/api/customers/{id}", 999L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateJson))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").doesNotExist())
                .andExpect(jsonPath("$.message").value("Cập nhật khách hàng thành công"));

        verify(customerService).updateCustomer(eq(999L), any(Customer.class));
    }

    // ========== TEST DELETE CUSTOMER ==========

    @Test
    void testDeleteCustomer_ShouldCallServiceDeleteMethod() throws Exception {
        // Arrange
        doNothing().when(customerService).deleteCustomer(1L);

        // Act & Assert
        mockMvc.perform(delete("/api/customers/{id}", 1L))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").doesNotExist())
                .andExpect(jsonPath("$.message").value("Xóa khách hàng thành công"));

        verify(customerService).deleteCustomer(1L);
    }

    // ========== TEST VALIDATION SCENARIOS ==========

    @Test
    void testCreateCustomer_WithBlankFullName_ShouldReturnBadRequest() throws Exception {
        // Arrange
        Customer invalidCustomer = Customer.builder()
                .fullName("") // Tên trống
                .email("test@example.com")
                .phone("0901234567")
                .address("Test Address")
                .build();

        String customerJson = objectMapper.writeValueAsString(invalidCustomer);

        // Act & Assert
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isBadRequest());

        verifyNoInteractions(customerService);
    }

    @Test
    void testCreateCustomer_WithInvalidPhoneNumber_ShouldReturnBadRequest() throws Exception {
        // Arrange
        Customer invalidCustomer = Customer.builder()
                .fullName("Test User")
                .email("test@example.com")
                .phone("123") // Phone number không hợp lệ
                .address("Test Address")
                .build();

        String customerJson = objectMapper.writeValueAsString(invalidCustomer);

        // Act & Assert
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isBadRequest());

        verifyNoInteractions(customerService);
    }

    @Test
    void testCreateCustomer_WithNullRequiredFields_ShouldReturnBadRequest() throws Exception {
        // Arrange
        Customer invalidCustomer = Customer.builder()
                .fullName(null) // Required field null
                .email(null) // Required field null
                .phone("0901234567")
                .address("Test Address")
                .build();

        String customerJson = objectMapper.writeValueAsString(invalidCustomer);

        // Act & Assert
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isBadRequest());

        verifyNoInteractions(customerService);
    }

    // ========== TEST EDGE CASES ==========

    @Test
    void testCreateCustomer_WithMinimalValidData_ShouldWork() throws Exception {
        // Arrange
        Customer minimalCustomer = Customer.builder()
                .fullName("AB") // Minimum length
                .email("a@b.co") // Minimal valid email
                .build(); // phone và address có thể null

        Customer savedCustomer = Customer.builder()
                .id(3L)
                .fullName("AB")
                .email("a@b.co")
                .build();

        when(customerService.createCustomer(any(Customer.class))).thenReturn(savedCustomer);

        String customerJson = objectMapper.writeValueAsString(minimalCustomer);

        // Act & Assert
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.fullName").value("AB"))
                .andExpect(jsonPath("$.data.email").value("a@b.co"));

        verify(customerService).createCustomer(any(Customer.class));
    }

    @Test
    void testUpdateCustomer_WithValidationErrors_ShouldReturnBadRequest() throws Exception {
        // Arrange
        Customer invalidUpdateData = Customer.builder()
                .fullName("A") // Quá ngắn (< 2 chars)
                .email("invalid")
                .phone("123")
                .address("Test")
                .build();

        String updateJson = objectMapper.writeValueAsString(invalidUpdateData);

        // Act & Assert
        mockMvc.perform(put("/api/customers/{id}", 1L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateJson))
                .andDo(print())
                .andExpect(status().isBadRequest());

        verifyNoInteractions(customerService);
    }
}
