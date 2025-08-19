package com.kienlongbank.loan_service.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateLoanStatusRequest {
    
    @NotBlank(message = "Trạng thái không được để trống")
    private String status;
    
    private String reason; // Lý do từ chối (tùy chọn)
}
