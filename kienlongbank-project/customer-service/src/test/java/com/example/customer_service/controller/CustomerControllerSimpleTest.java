package com.example.customer_service.controller;

import com.example.customer_service.model.Customer;
import com.example.customer_service.repository.CustomerRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Simplified Integration Test Example cho CustomerController
 * Đây là phiên bản đơn giản hóa để demo cách test hoạt động
 */
@SpringBootTest
@AutoConfigureWebMvc
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
@Transactional
public class CustomerControllerSimpleTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        // Xóa toàn bộ dữ liệu trước mỗi test
        customerRepository.deleteAll();
    }

    @Test
    void testGetAllCustomers_WhenEmpty_ShouldReturnEmptyList() throws Exception {
        // Test GET /api/customers khi database trống
        mockMvc.perform(get("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print()) // Print request/response details
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data", hasSize(0)))
                .andExpect(jsonPath("$.message").value("Lấy danh sách khách hàng thành công"));
    }

    @Test
    void testCreateCustomer_WithValidData_ShouldCreateSuccessfully() throws Exception {
        // Tạo customer data
        Customer newCustomer = new Customer();
        newCustomer.setFullName("Nguyễn Văn Test");
        newCustomer.setEmail("test@kienlongbank.com");
        newCustomer.setPhone("0901234567");
        newCustomer.setAddress("123 Test Street");

        String customerJson = objectMapper.writeValueAsString(newCustomer);

        // Test POST /api/customers
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.fullName").value("Nguyễn Văn Test"))
                .andExpect(jsonPath("$.data.email").value("test@kienlongbank.com"))
                .andExpect(jsonPath("$.data.phone").value("0901234567"))
                .andExpect(jsonPath("$.data.address").value("123 Test Street"))
                .andExpect(jsonPath("$.data.id").exists())
                .andExpect(jsonPath("$.message").value("Tạo khách hàng thành công"));

        // Verify customer được lưu vào database
        long totalCustomers = customerRepository.count();
        assertEquals(1, totalCustomers);
    }

    @Test
    void testCreateCustomer_WithInvalidEmail_ShouldReturnBadRequest() throws Exception {
        // Tạo customer với email không hợp lệ
        Customer invalidCustomer = new Customer();
        invalidCustomer.setFullName("Test User");
        invalidCustomer.setEmail("invalid-email"); // Email không hợp lệ
        invalidCustomer.setPhone("0901234567");
        invalidCustomer.setAddress("Test Address");

        String customerJson = objectMapper.writeValueAsString(invalidCustomer);

        // Test POST /api/customers với dữ liệu không hợp lệ
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isBadRequest());
        
        // Verify không có customer nào được tạo
        assertEquals(0, customerRepository.count());
    }

    @Test
    void testFullCrudWorkflow() throws Exception {
        // 1. CREATE - Tạo customer mới
        Customer newCustomer = new Customer();
        newCustomer.setFullName("Lê Văn CRUD");
        newCustomer.setEmail("crud@test.com");
        newCustomer.setPhone("0912345678");
        newCustomer.setAddress("CRUD Address");

        String createJson = objectMapper.writeValueAsString(newCustomer);

        // POST /api/customers
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"));

        // Lấy customer ID từ database
        Long customerId = customerRepository.findAll().get(0).getId();

        // 2. READ - Đọc customer vừa tạo
        mockMvc.perform(get("/api/customers/{id}", customerId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.fullName").value("Lê Văn CRUD"))
                .andExpect(jsonPath("$.data.email").value("crud@test.com"));

        // 3. UPDATE - Cập nhật customer
        Customer updateData = new Customer();
        updateData.setFullName("Lê Văn CRUD Updated");
        updateData.setEmail("crud-updated@test.com");
        updateData.setPhone("0987654321");
        updateData.setAddress("Updated Address");

        String updateJson = objectMapper.writeValueAsString(updateData);

        mockMvc.perform(put("/api/customers/{id}", customerId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.fullName").value("Lê Văn CRUD Updated"));

        // 4. DELETE - Xóa customer
        mockMvc.perform(delete("/api/customers/{id}", customerId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"));

        // 5. VERIFY - Verify đã bị xóa
        assertEquals(0, customerRepository.count());
    }

    @Test
    void testGetCustomerById_WithValidId_ShouldReturnCustomer() throws Exception {
        // Arrange: Lưu customer vào database trước
        Customer testCustomer = new Customer();
        testCustomer.setFullName("Test Customer");
        testCustomer.setEmail("test@example.com");
        testCustomer.setPhone("0901234567");
        testCustomer.setAddress("Test Address");
        
        Customer savedCustomer = customerRepository.save(testCustomer);

        // Act & Assert: Test GET /api/customers/{id}
        mockMvc.perform(get("/api/customers/{id}", savedCustomer.getId())
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.id").value(savedCustomer.getId()))
                .andExpect(jsonPath("$.data.fullName").value("Test Customer"))
                .andExpect(jsonPath("$.data.email").value("test@example.com"))
                .andExpect(jsonPath("$.message").value("Lấy thông tin khách hàng thành công"));
    }

    @Test
    void testDeleteCustomer_WithValidId_ShouldDeleteSuccessfully() throws Exception {
        // Arrange: Lưu customer vào database
        Customer testCustomer = new Customer();
        testCustomer.setFullName("To Be Deleted");
        testCustomer.setEmail("delete@test.com");
        testCustomer.setPhone("0901234567");
        testCustomer.setAddress("Delete Address");
        
        Customer savedCustomer = customerRepository.save(testCustomer);
        Long customerId = savedCustomer.getId();

        // Verify customer tồn tại trước khi xóa
        assertTrue(customerRepository.findById(customerId).isPresent());

        // Act: Test DELETE /api/customers/{id}
        mockMvc.perform(delete("/api/customers/{id}", customerId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.message").value("Xóa khách hàng thành công"));

        // Assert: Verify customer đã bị xóa khỏi database
        assertFalse(customerRepository.findById(customerId).isPresent());
        assertEquals(0, customerRepository.count());
    }
}
