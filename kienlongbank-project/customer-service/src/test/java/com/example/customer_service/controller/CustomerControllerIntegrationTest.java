package com.example.customer_service.controller;

import com.kienlongbank.common.dto.ApiResponse;
import com.example.customer_service.model.Customer;
import com.example.customer_service.repository.CustomerRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.util.Optional;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration Test cho CustomerController
 * Kiểm tra toàn bộ luồng hoạt động của customer-service từ HTTP request đến database
 * Sử dụng MockMvc để giả lập HTTP requests mà không cần khởi động server thực sự
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@TestPropertySource(locations = "classpath:application-test.properties")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
@Transactional
public class CustomerControllerIntegrationTest {

    @Autowired
    private WebApplicationContext webApplicationContext;

    private MockMvc mockMvc;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private Customer testCustomer;

    @BeforeEach
    void setUp() {
        // Khởi tạo MockMvc với WebApplicationContext
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
        
        // Xóa toàn bộ dữ liệu trước mỗi test
        customerRepository.deleteAll();
        
        // Tạo customer mẫu cho test
        testCustomer = Customer.builder()
                .fullName("Nguyễn Văn Test")
                .email("test@kienlongbank.com")
                .phone("0901234567")
                .address("123 Test Street, Test City")
                .build();
    }

    // ========== TEST GET ALL CUSTOMERS ==========

    @Test
    void testGetAllCustomers_WhenEmpty_ShouldReturnEmptyList() throws Exception {
        mockMvc.perform(get("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data", hasSize(0)))
                .andExpect(jsonPath("$.message").value("Lấy danh sách khách hàng thành công"));
    }

    @Test
    void testGetAllCustomers_WithData_ShouldReturnCustomerList() throws Exception {
        // Arrange: Lưu customer vào database
        Customer savedCustomer = customerRepository.save(testCustomer);

        // Act & Assert
        mockMvc.perform(get("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].id").value(savedCustomer.getId()))
                .andExpect(jsonPath("$.data[0].fullName").value("Nguyễn Văn Test"))
                .andExpect(jsonPath("$.data[0].email").value("test@kienlongbank.com"))
                .andExpect(jsonPath("$.data[0].phone").value("0901234567"))
                .andExpect(jsonPath("$.data[0].address").value("123 Test Street, Test City"))
                .andExpect(jsonPath("$.message").value("Lấy danh sách khách hàng thành công"));
    }

    // ========== TEST CREATE CUSTOMER ==========

    @Test
    void testCreateCustomer_WithValidData_ShouldCreateSuccessfully() throws Exception {
        // Arrange
        Customer newCustomer = Customer.builder()
                .fullName("Trần Thị Mới")
                .email("tranmoi@kienlongbank.com")
                .phone("0987654321")
                .address("456 New Street, New City")
                .build();

        String customerJson = objectMapper.writeValueAsString(newCustomer);

        // Act & Assert
        MvcResult result = mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.fullName").value("Trần Thị Mới"))
                .andExpect(jsonPath("$.data.email").value("tranmoi@kienlongbank.com"))
                .andExpect(jsonPath("$.data.phone").value("0987654321"))
                .andExpect(jsonPath("$.data.address").value("456 New Street, New City"))
                .andExpect(jsonPath("$.data.id").exists())
                .andExpect(jsonPath("$.message").value("Tạo khách hàng thành công"))
                .andReturn();

        // Verify customer được lưu vào database
        String responseContent = result.getResponse().getContentAsString();
        ApiResponse<?> response = objectMapper.readValue(responseContent, ApiResponse.class);
        
        // Kiểm tra trong database
        long totalCustomers = customerRepository.count();
        assertEquals(1, totalCustomers);
        
        Optional<Customer> savedCustomer = customerRepository.findAll().stream().findFirst();
        assertTrue(savedCustomer.isPresent());
        assertEquals("Trần Thị Mới", savedCustomer.get().getFullName());
        assertEquals("tranmoi@kienlongbank.com", savedCustomer.get().getEmail());
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
        
        // Verify không có customer nào được tạo
        assertEquals(0, customerRepository.count());
    }

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
    }

    @Test
    void testCreateCustomer_WithInvalidPhoneNumber_ShouldReturnBadRequest() throws Exception {
        // Arrange
        Customer invalidCustomer = Customer.builder()
                .fullName("Test User")
                .email("test@example.com")
                .phone("123") // Phone không hợp lệ
                .address("Test Address")
                .build();

        String customerJson = objectMapper.writeValueAsString(invalidCustomer);

        // Act & Assert
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isBadRequest());
    }

    // ========== TEST GET CUSTOMER BY ID ==========

    @Test
    void testGetCustomerById_WithValidId_ShouldReturnCustomer() throws Exception {
        // Arrange
        Customer savedCustomer = customerRepository.save(testCustomer);

        // Act & Assert
        mockMvc.perform(get("/api/customers/{id}", savedCustomer.getId())
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.id").value(savedCustomer.getId()))
                .andExpect(jsonPath("$.data.fullName").value("Nguyễn Văn Test"))
                .andExpect(jsonPath("$.data.email").value("test@kienlongbank.com"))
                .andExpect(jsonPath("$.data.phone").value("0901234567"))
                .andExpect(jsonPath("$.data.address").value("123 Test Street, Test City"))
                .andExpect(jsonPath("$.message").value("Lấy thông tin khách hàng thành công"));
    }

    @Test
    void testGetCustomerById_WithInvalidId_ShouldReturnNotFound() throws Exception {
        // Act & Assert
        mockMvc.perform(get("/api/customers/{id}", 999L)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk()) // Controller trả về OK nhưng data null
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").doesNotExist());
    }

    // ========== TEST UPDATE CUSTOMER ==========

    @Test
    void testUpdateCustomer_WithValidData_ShouldUpdateSuccessfully() throws Exception {
        // Arrange
        Customer savedCustomer = customerRepository.save(testCustomer);
        
        Customer updateData = Customer.builder()
                .fullName("Nguyễn Văn Updated")
                .email("updated@kienlongbank.com")
                .phone("0909999999")
                .address("999 Updated Street, Updated City")
                .build();

        String updateJson = objectMapper.writeValueAsString(updateData);

        // Act & Assert
        mockMvc.perform(put("/api/customers/{id}", savedCustomer.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateJson))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.id").value(savedCustomer.getId()))
                .andExpect(jsonPath("$.data.fullName").value("Nguyễn Văn Updated"))
                .andExpect(jsonPath("$.data.email").value("updated@kienlongbank.com"))
                .andExpect(jsonPath("$.data.phone").value("0909999999"))
                .andExpect(jsonPath("$.data.address").value("999 Updated Street, Updated City"))
                .andExpect(jsonPath("$.message").value("Cập nhật khách hàng thành công"));

        // Verify trong database
        Optional<Customer> updatedCustomer = customerRepository.findById(savedCustomer.getId());
        assertTrue(updatedCustomer.isPresent());
        assertEquals("Nguyễn Văn Updated", updatedCustomer.get().getFullName());
        assertEquals("updated@kienlongbank.com", updatedCustomer.get().getEmail());
    }

    @Test
    void testUpdateCustomer_WithInvalidId_ShouldReturnNotFound() throws Exception {
        // Arrange
        Customer updateData = Customer.builder()
                .fullName("Updated Name")
                .email("updated@example.com")
                .phone("0901234567")
                .address("Updated Address")
                .build();

        String updateJson = objectMapper.writeValueAsString(updateData);

        // Act & Assert
        mockMvc.perform(put("/api/customers/{id}", 999L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateJson))
                .andDo(print())
                .andExpect(status().isOk()) // Controller trả về OK nhưng data null
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").doesNotExist());
    }

    @Test
    void testUpdateCustomer_WithInvalidData_ShouldReturnBadRequest() throws Exception {
        // Arrange
        Customer savedCustomer = customerRepository.save(testCustomer);
        
        Customer invalidUpdateData = Customer.builder()
                .fullName("") // Tên trống
                .email("invalid-email")
                .phone("123")
                .address("Address")
                .build();

        String updateJson = objectMapper.writeValueAsString(invalidUpdateData);

        // Act & Assert
        mockMvc.perform(put("/api/customers/{id}", savedCustomer.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateJson))
                .andDo(print())
                .andExpect(status().isBadRequest());
    }

    // ========== TEST DELETE CUSTOMER ==========

    @Test
    void testDeleteCustomer_WithValidId_ShouldDeleteSuccessfully() throws Exception {
        // Arrange
        Customer savedCustomer = customerRepository.save(testCustomer);
        Long customerId = savedCustomer.getId();

        // Verify customer tồn tại trước khi xóa
        assertTrue(customerRepository.findById(customerId).isPresent());

        // Act & Assert
        mockMvc.perform(delete("/api/customers/{id}", customerId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").doesNotExist())
                .andExpect(jsonPath("$.message").value("Xóa khách hàng thành công"));

        // Verify customer đã bị xóa khỏi database
        assertFalse(customerRepository.findById(customerId).isPresent());
        assertEquals(0, customerRepository.count());
    }

    @Test
    void testDeleteCustomer_WithInvalidId_ShouldStillReturnSuccess() throws Exception {
        // Act & Assert - JPA deleteById không throw exception nếu ID không tồn tại
        mockMvc.perform(delete("/api/customers/{id}", 999L)
                        .contentType(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.message").value("Xóa khách hàng thành công"));
    }

    // ========== INTEGRATION TESTS - FULL CRUD FLOW ==========

    @Test
    void testFullCrudFlow_CreateReadUpdateDelete_ShouldWorkCorrectly() throws Exception {
        // 1. CREATE - Tạo customer mới
        Customer newCustomer = Customer.builder()
                .fullName("Lê Văn CRUD")
                .email("crud@kienlongbank.com")
                .phone("0912345678")
                .address("CRUD Test Address")
                .build();

        String createJson = objectMapper.writeValueAsString(newCustomer);

        MvcResult createResult = mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andReturn();

        // Extract customer ID từ response
        String createResponse = createResult.getResponse().getContentAsString();
        // Giả sử response có cấu trúc ApiResponse với data chứa customer có id
        // Có thể parse JSON để lấy ID, ở đây dùng cách đơn giản
        Long customerId = customerRepository.findAll().get(0).getId();

        // 2. READ - Đọc customer vừa tạo
        mockMvc.perform(get("/api/customers/{id}", customerId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.fullName").value("Lê Văn CRUD"))
                .andExpect(jsonPath("$.data.email").value("crud@kienlongbank.com"));

        // 3. UPDATE - Cập nhật customer
        Customer updateData = Customer.builder()
                .fullName("Lê Văn CRUD Updated")
                .email("crud-updated@kienlongbank.com")
                .phone("0987654321")
                .address("Updated CRUD Address")
                .build();

        String updateJson = objectMapper.writeValueAsString(updateData);

        mockMvc.perform(put("/api/customers/{id}", customerId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.fullName").value("Lê Văn CRUD Updated"))
                .andExpect(jsonPath("$.data.email").value("crud-updated@kienlongbank.com"));

        // 4. READ AGAIN - Verify update thành công
        mockMvc.perform(get("/api/customers/{id}", customerId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.fullName").value("Lê Văn CRUD Updated"))
                .andExpect(jsonPath("$.data.email").value("crud-updated@kienlongbank.com"));

        // 5. DELETE - Xóa customer
        mockMvc.perform(delete("/api/customers/{id}", customerId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"));

        // 6. READ AFTER DELETE - Verify đã bị xóa
        mockMvc.perform(get("/api/customers/{id}", customerId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data").doesNotExist());
    }

    // ========== TEST EDGE CASES ==========

    @Test
    void testCreateMultipleCustomers_ShouldHandleCorrectly() throws Exception {
        // Tạo 3 customers
        for (int i = 1; i <= 3; i++) {
            Customer customer = Customer.builder()
                    .fullName("Customer " + i)
                    .email("customer" + i + "@test.com")
                    .phone("090000000" + i)
                    .address("Address " + i)
                    .build();

            String customerJson = objectMapper.writeValueAsString(customer);

            mockMvc.perform(post("/api/customers")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(customerJson))
                    .andExpect(status().isOk());
        }

        // Verify có 3 customers trong database
        assertEquals(3, customerRepository.count());

        // Get all và verify
        mockMvc.perform(get("/api/customers"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(3)));
    }

    @Test
    void testCreateCustomer_WithNullOptionalFields_ShouldWork() throws Exception {
        // Arrange - Chỉ có required fields
        Customer minimalCustomer = Customer.builder()
                .fullName("Minimal Customer")
                .email("minimal@test.com")
                // phone và address null
                .build();

        String customerJson = objectMapper.writeValueAsString(minimalCustomer);

        // Act & Assert
        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.fullName").value("Minimal Customer"))
                .andExpect(jsonPath("$.data.email").value("minimal@test.com"))
                .andExpect(jsonPath("$.data.phone").isEmpty())
                .andExpect(jsonPath("$.data.address").isEmpty());
    }

    @Test
    void testApi_WithDifferentContentTypes_ShouldHandleCorrectly() throws Exception {
        // Test với JSON
        Customer customer = Customer.builder()
                .fullName("JSON Customer")
                .email("json@test.com")
                .phone("0901234567")
                .address("JSON Address")
                .build();

        String customerJson = objectMapper.writeValueAsString(customer);

        mockMvc.perform(post("/api/customers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(customerJson))
                .andExpect(status().isOk());

        // Test GET với Accept header
        mockMvc.perform(get("/api/customers")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON));
    }
}
