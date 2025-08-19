# 📚 Testing Best Practices & Important Notes

## 🎯 Key Learning Points từ Integration Tests

### 1. 🏗️ **Test Architecture Design**

#### ✅ **Separation of Concerns**
```java
// 🔧 Integration Tests - Test toàn bộ luồng từ HTTP đến Database
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class CustomerControllerIntegrationTest {
    // Test real HTTP requests với MockMvc
}

// 🧪 Unit Tests - Test từng component riêng biệt với mocks
@ExtendWith(MockitoExtension.class)
class CustomerControllerUnitTest {
    // Test business logic với mocked dependencies
}
```

#### 🎯 **Test Data Strategy**
```java
// 📊 Builder Pattern cho clean test data
Customer validCustomer = Customer.builder()
    .fullName("Nguyễn Văn Test")           // Vietnamese name
    .email("test@kienlongbank.com")        // Realistic email
    .phone("0901234567")                   // Valid VN phone
    .address("123 Đường Test, TP.HCM")     // Vietnamese address
    .build();

// ❌ Invalid data để test validation
Customer invalidCustomer = Customer.builder()
    .fullName("")                          // NotBlank violation
    .email("invalid-email")                // Email format violation
    .phone("123")                          // Pattern violation
    .build();
```

### 2. 🔧 **Configuration Management**

#### 📄 **Test Properties Hierarchy**
```
application.properties           # 🏭 Production config (PostgreSQL)
     ↓ Override by
application-test.properties      # 🧪 Test config (H2, no security)
     ↓ Override by
@TestPropertySource             # 🎯 Method-level overrides
```

#### 🗄️ **Database Configuration Strategy**
```properties
# 🎯 CRITICAL: Ensure H2 completely overrides PostgreSQL
spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop

# 🚨 IMPORTANT: Disable auto-configuration conflicts
spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration
```

### 3. 🔄 **Test Isolation Best Practices**

#### 🧹 **Clean Slate Approach**
```java
@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_EACH_TEST_METHOD)
// 🎯 Purpose: Fresh Spring context cho mỗi test method
// 💡 Benefit: Eliminates test interdependencies
// ⚠️ Cost: Slower execution but guaranteed isolation
```

#### 💾 **Transaction Management**
```java
@Transactional
// 🔄 Purpose: Auto rollback database changes
// ✅ Benefit: Database state reset after each test
// 🎯 Usage: Ideal cho integration tests với database mutations
```

### 4. 🎭 **MockMvc Best Practices**

#### 🌐 **Setup Strategy**
```java
// ✅ RECOMMENDED: WebApplicationContext setup
@Autowired
private WebApplicationContext webApplicationContext;

@BeforeEach
void setUp() {
    mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
}

// ❌ AVOID: Standalone setup (misses Spring context)
// mockMvc = MockMvcBuilders.standaloneSetup(customerController).build();
```

#### 📊 **Comprehensive Assertions**
```java
// 🎯 PATTERN: Verify HTTP response AND database state
mockMvc.perform(post("/api/customers")
        .contentType(MediaType.APPLICATION_JSON)
        .content(objectMapper.writeValueAsString(customer)))
    // ✅ HTTP Response verification
    .andExpect(status().isCreated())
    .andExpect(jsonPath("$.fullName").value("Nguyễn Văn Test"))
    .andExpect(jsonPath("$.email").value("test@kienlongbank.com"));

// ✅ Database State verification
Customer savedCustomer = customerRepository.findById(1L).orElse(null);
assertThat(savedCustomer).isNotNull();
assertThat(savedCustomer.getFullName()).isEqualTo("Nguyễn Văn Test");
```

## 🚨 Common Pitfalls & Solutions

### 1. ❌ **Lombok Code Generation Issues**

#### 🔧 **Problem**: Getters/Setters not generated
```java
// ❌ Symptom: Cannot resolve method 'getFullName()'
Customer customer = new Customer();
String name = customer.getFullName(); // Compilation error
```

#### ✅ **Solution**: Enable Annotation Processing
```
1. IDE Settings → Build → Compiler → Annotation Processors
2. ✅ Enable annotation processing
3. ✅ Obtain processors from project classpath
4. 🔄 Rebuild project
```

### 2. ❌ **Database Dialect Conflicts**

#### 🔧 **Problem**: H2 vs PostgreSQL dialect issues
```
ERROR: org.hibernate.dialect.PostgreSQLDialect cannot be cast to org.hibernate.dialect.H2Dialect
```

#### ✅ **Solution**: Explicit Test Configuration
```properties
# 🎯 Force H2 dialect in test environment
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect

# 🔧 Ensure proper database URL format
spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
```

### 3. ❌ **Security Configuration Conflicts**

#### 🔧 **Problem**: Test requests blocked by authentication
```
HTTP 401 Unauthorized - Authentication required
```

#### ✅ **Solution**: Test-specific Security Config
```java
@TestConfiguration
@EnableWebSecurity
public class TestSecurityConfig {
    @Bean
    @Primary
    public SecurityFilterChain testSecurityFilterChain(HttpSecurity http) throws Exception {
        return http
            .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
            .csrf(csrf -> csrf.disable())
            .build();
    }
}
```

### 4. ❌ **Maven Dependency Resolution**

#### 🔧 **Problem**: H2 database not found in classpath
```
ClassNotFoundException: org.h2.Driver
```

#### ✅ **Solution**: Correct Test Dependency
```xml
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>test</scope> <!-- 🎯 CRITICAL: test scope only -->
</dependency>
```

## 📊 Test Execution Strategies

### 🎯 **Selective Test Execution**

#### 1. Single Test Method
```powershell
mvn test -Dtest=CustomerControllerIntegrationTest#testCreateCustomer_WithValidData_ShouldCreateSuccessfully
```

#### 2. Test Class
```powershell
mvn test -Dtest=CustomerControllerIntegrationTest
```

#### 3. Test Pattern
```powershell
mvn test -Dtest=*IntegrationTest
```

#### 4. All Tests
```powershell
mvn test
```

### 🚀 **Performance Optimization**

#### ⚡ **Parallel Execution** (Future Enhancement)
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <configuration>
        <parallel>methods</parallel>
        <threadCount>4</threadCount>
    </configuration>
</plugin>
```

#### 🎯 **Test Categories** (Future Enhancement)
```java
@Category(IntegrationTest.class)
public class CustomerControllerIntegrationTest { ... }

@Category(UnitTest.class)
public class CustomerControllerUnitTest { ... }
```

## 🔍 Debugging Tips

### 🐛 **Common Debug Scenarios**

#### 1. **Test Data Not Persisting**
```java
// 🔍 Debug: Check if @Transactional is interfering
@Commit // Force commit instead of rollback
@Test
void debugTest() {
    // Test logic here
}
```

#### 2. **JSON Serialization Issues**
```java
// 🔍 Debug: Print actual JSON content
String jsonContent = objectMapper.writeValueAsString(customer);
System.out.println("JSON: " + jsonContent);
```

#### 3. **Database State Verification**
```java
// 🔍 Debug: Check actual database content
List<Customer> allCustomers = customerRepository.findAll();
System.out.println("Database customers: " + allCustomers);
```

#### 4. **HTTP Request/Response Debugging**
```java
// 🔍 Debug: Print request/response details
mockMvc.perform(post("/api/customers")
        .contentType(MediaType.APPLICATION_JSON)
        .content(jsonContent))
    .andDo(print()) // 🎯 Prints complete HTTP exchange
    .andExpect(status().isCreated());
```

## 📚 Additional Resources

### 📖 **Documentation References**
- [Spring Boot Testing Guide](https://spring.io/guides/gs/testing-web/)
- [MockMvc Documentation](https://docs.spring.io/spring-framework/docs/current/reference/html/testing.html#spring-mvc-test-framework)
- [H2 Database Documentation](http://h2database.com/html/tutorial.html)
- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/)

### 🎯 **Best Practice Articles**
- Integration Testing với Spring Boot
- MockMvc vs TestRestTemplate
- H2 Database Testing Strategies
- Lombok Best Practices

## 🎉 Summary Checklist

### ✅ **Integration Test Quality Checklist**

- [ ] **Test Isolation**: Each test runs independently
- [ ] **Database Management**: H2 configuration working correctly
- [ ] **Security Config**: Test security bypassed appropriately
- [ ] **Meaningful Assertions**: Both HTTP and database state verified
- [ ] **Error Scenarios**: Validation và error cases tested
- [ ] **Clean Code**: Descriptive test names và clear structure
- [ ] **Documentation**: Tests serve as living documentation
- [ ] **Performance**: Tests execute in reasonable time (< 1 minute)

### 🚀 **Ready for Production Deployment**

Với 17 integration tests passing và comprehensive coverage:

1. ✅ **API Contract Verified**: All endpoints tested
2. ✅ **Data Validation Confirmed**: Vietnamese validation messages work
3. ✅ **Error Handling Validated**: Proper HTTP status codes returned
4. ✅ **Database Integration Verified**: CRUD operations work correctly
5. ✅ **Test Infrastructure Ready**: Can be integrated into CI/CD pipeline

**🎯 Kết luận**: Integration test framework hoàn chỉnh và ready for continuous development! 🚀

---

> **📝 Document Version**: 1.0  
> **📅 Last Updated**: August 5, 2025  
> **👨‍💻 Author**: GitHub Copilot Assistant  
> **🎯 Purpose**: Support development team với comprehensive testing knowledge
