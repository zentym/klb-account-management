package com.kienlongbank.loan_service.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoanApplicationRequest {
    
    @NotNull(message = "Customer ID không được để trống")
    private Long customerId;
    
    @NotNull(message = "Số tiền vay không được để trống")
    @DecimalMin(value = "1000000.0", message = "Số tiền vay tối thiểu là 1,000,000 VNĐ")
    @DecimalMax(value = "1000000000.0", message = "Số tiền vay tối đa là 1,000,000,000 VNĐ")
    private Double amount;
    
    @NotNull(message = "Lãi suất không được để trống")
    @DecimalMin(value = "0.1", message = "Lãi suất tối thiểu là 0.1%")
    @DecimalMax(value = "30.0", message = "Lãi suất tối đa là 30%")
    private Double interestRate;
    
    @NotNull(message = "Kỳ hạn không được để trống")
    @Min(value = 1, message = "Kỳ hạn tối thiểu là 1 tháng")
    @Max(value = 360, message = "Kỳ hạn tối đa là 360 tháng")
    private Integer term;
    
    private String purpose; // Mục đích vay
    
    private String collateral; // Tài sản thế chấp
}
