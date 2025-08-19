# Unit Test Documentation cho TransactionService

## Tổng quan

File `TransactionServiceTest.java` chứa 11 test cases để kiểm thử đầy đủ chức năng của phương thức `performTransfer` trong `TransactionService`.

## Cấu trúc Test

### Test Setup (`@BeforeEach`)
- Tạo mock data cho `fromAccount`, `toAccount`, và `mockTransaction`
- Cấu hình giá trị `coreBankingApiUrl` sử dụng `ReflectionTestUtils`
- Thiết lập các mock objects cho repository và external services

### Test Cases

#### 1. `testPerformTransfer_Success()`
**Mục đích**: Kiểm thử kịch bản chuyển tiền thành công
- **Given**: Hai tài khoản hợp lệ với số dư đủ, Core Banking API trả về OK
- **When**: Gọi `performTransfer(1L, 100.0, 2L)`
- **Then**: 
  - Transaction được tạo với status "COMPLETED"
  - Số dư tài khoản được cập nhật đúng
  - RabbitMQ message được gửi

#### 2. `testPerformTransfer_FromAccountNotFound()`
**Mục đích**: Kiểm thử trường hợp tài khoản nguồn không tồn tại
- **Expected**: `RuntimeException` với message "Tài khoản nguồn không tồn tại!"

#### 3. `testPerformTransfer_ToAccountNotFound()`
**Mục đích**: Kiểm thử trường hợp tài khoản đích không tồn tại
- **Expected**: `RuntimeException` với message "Tài khoản đích không tồn tại!"

#### 4. `testPerformTransfer_InsufficientBalance()`
**Mục đích**: Kiểm thử trường hợp số dư không đủ
- **Given**: Chuyển 1500.0 khi chỉ có 1000.0 trong tài khoản
- **Expected**: `RuntimeException` với message "Số dư không đủ để thực hiện giao dịch!"

#### 5. `testPerformTransfer_CoreBankingRejects()`
**Mục đích**: Kiểm thử trường hợp Core Banking từ chối giao dịch
- **Given**: Core Banking API trả về BAD_REQUEST
- **Expected**: `RuntimeException` với message "Giao dịch bị Core Banking từ chối."
- **Verify**: Không có thay đổi số dư tài khoản

#### 6. `testPerformTransfer_ZeroAmount()`
**Mục đích**: Kiểm thử trường hợp chuyển số tiền 0
- **Verify**: Số dư tài khoản không thay đổi

#### 7. `testPerformTransfer_NegativeAmount()`
**Mục đích**: Kiểm thử trường hợp chuyển số tiền âm
- **Verify**: Số dư thay đổi theo logic (âm có nghĩa là rút tiền từ người nhận)

#### 8. `testPerformTransfer_SameAccount()`
**Mục đích**: Kiểm thử trường hợp chuyển tiền cho chính tài khoản của mình
- **Verify**: Số dư cuối cùng không đổi (trừ rồi cộng lại)

#### 9. `testPerformTransfer_LargeAmount()`
**Mục đích**: Kiểm thử với số tiền lớn (gần hết số dư)
- **Given**: Chuyển 999.99 từ tài khoản có 1000.0
- **Verify**: Số dư còn lại 0.01

#### 10. `testPerformTransfer_VerifyTransactionFields()`
**Mục đích**: Kiểm thử chi tiết các field của Transaction object
- **Verify**: Tất cả các field được set đúng giá trị

#### 11. `testPerformTransfer_VerifyRabbitMQMessage()`
**Mục đích**: Kiểm thử nội dung message gửi đến RabbitMQ
- **Verify**: Message có đúng format và nội dung

## Công nghệ sử dụng

### Testing Framework
- **JUnit 5**: Framework testing chính
- **Mockito**: Mock objects và verify interactions
- **@ExtendWith(MockitoExtension.class)**: Tích hợp Mockito với JUnit 5

### Annotations quan trọng
- `@Mock`: Tạo mock objects
- `@InjectMocks`: Inject mock objects vào class under test
- `@BeforeEach`: Setup trước mỗi test
- `@Test`: Đánh dấu test methods

### Mockito Features sử dụng
- `when().thenReturn()`: Stub method calls
- `verify()`: Verify method interactions
- `argThat()`: Custom argument matchers
- `eq()`: Exact argument matching
- `any()`: Any argument matching
- `times()`: Verify number of invocations
- `never()`: Verify method never called

## Cách chạy Test

### Chạy tất cả tests trong class
```bash
mvn test -Dtest=TransactionServiceTest
```

### Chạy một test method cụ thể
```bash
mvn test -Dtest=TransactionServiceTest#testPerformTransfer_Success
```

### Chạy tất cả unit tests
```bash
mvn test
```

## Coverage

Test coverage bao gồm:
- ✅ Happy path scenarios
- ✅ Error handling scenarios
- ✅ Edge cases (zero amount, negative amount, same account)
- ✅ External service integration (Core Banking API, RabbitMQ)
- ✅ Data validation and business rules
- ✅ Database interactions verification

## Kết quả mong đợi

Khi chạy test thành công, bạn sẽ thấy:
```
[INFO] Tests run: 11, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

## Best Practices được áp dụng

1. **AAA Pattern**: Arrange, Act, Assert trong mỗi test
2. **Descriptive Test Names**: Tên test mô tả rõ ràng kịch bản
3. **Independent Tests**: Mỗi test độc lập, không phụ thuộc vào nhau
4. **Mock External Dependencies**: Mock tất cả external services
5. **Verify Behavior**: Kiểm tra cả return value và side effects
6. **Edge Case Testing**: Test các trường hợp biên
7. **Error Scenario Testing**: Test error handling

## Lưu ý

- Test sử dụng `ReflectionTestUtils` để set private field `coreBankingApiUrl`
- Mock data được tạo với Builder pattern từ Lombok
- Test verify cả positive và negative scenarios
- Test đảm bảo transactional integrity (rollback khi có lỗi)
