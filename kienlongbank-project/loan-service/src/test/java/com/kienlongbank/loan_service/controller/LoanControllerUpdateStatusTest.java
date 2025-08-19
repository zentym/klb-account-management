package com.kienlongbank.loan_service.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kienlongbank.loan_service.dto.UpdateLoanStatusRequest;
import com.kienlongbank.loan_service.entity.Loan;
import com.kienlongbank.loan_service.service.LoanService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(LoanController.class)
public class LoanControllerUpdateStatusTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private LoanService loanService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @WithMockUser(authorities = {"ROLE_admin"})
    public void testUpdateLoanStatus_Approved_Success() throws Exception {
        // Arrange
        Long loanId = 1L;
        Loan mockLoan = new Loan();
        mockLoan.setId(loanId);
        mockLoan.setCustomerId(123L);
        mockLoan.setAmount(50000000.0);
        mockLoan.setInterestRate(8.5);
        mockLoan.setTerm(24);
        mockLoan.setStatus(Loan.LoanStatus.APPROVED);
        mockLoan.setApplicationDate(LocalDateTime.now());
        mockLoan.setApprovalDate(LocalDateTime.now());
        mockLoan.setApprovedBy("admin");

        UpdateLoanStatusRequest request = new UpdateLoanStatusRequest();
        request.setStatus("APPROVED");

        when(loanService.updateLoanStatus(eq(loanId), eq("APPROVED"), isNull()))
                .thenReturn(mockLoan);

        // Act & Assert
        mockMvc.perform(post("/api/loans/{loanId}/status", loanId)
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(loanId))
                .andExpect(jsonPath("$.status").value("APPROVED"))
                .andExpect(jsonPath("$.approvedBy").value("admin"));
    }

    @Test
    @WithMockUser(authorities = {"ROLE_admin"})
    public void testUpdateLoanStatus_Rejected_WithReason_Success() throws Exception {
        // Arrange
        Long loanId = 2L;
        String rejectReason = "Thu nhập không đủ điều kiện";
        
        Loan mockLoan = new Loan();
        mockLoan.setId(loanId);
        mockLoan.setCustomerId(124L);
        mockLoan.setAmount(100000000.0);
        mockLoan.setStatus(Loan.LoanStatus.REJECTED);
        mockLoan.setRejectReason(rejectReason);
        mockLoan.setApprovedBy("admin");

        UpdateLoanStatusRequest request = new UpdateLoanStatusRequest();
        request.setStatus("REJECTED");
        request.setReason(rejectReason);

        when(loanService.updateLoanStatus(eq(loanId), eq("REJECTED"), eq(rejectReason)))
                .thenReturn(mockLoan);

        // Act & Assert
        mockMvc.perform(post("/api/loans/{loanId}/status", loanId)
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(loanId))
                .andExpect(jsonPath("$.status").value("REJECTED"))
                .andExpect(jsonPath("$.rejectReason").value(rejectReason));
    }

    @Test
    @WithMockUser(authorities = {"ROLE_customer"})
    public void testUpdateLoanStatus_AccessDenied_ForNonAdmin() throws Exception {
        // Arrange
        Long loanId = 1L;
        UpdateLoanStatusRequest request = new UpdateLoanStatusRequest();
        request.setStatus("APPROVED");

        // Act & Assert
        mockMvc.perform(post("/api/loans/{loanId}/status", loanId)
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = {"ROLE_admin"})
    public void testUpdateLoanStatus_BadRequest_InvalidStatus() throws Exception {
        // Arrange
        Long loanId = 1L;
        UpdateLoanStatusRequest request = new UpdateLoanStatusRequest();
        request.setStatus("INVALID_STATUS");

        when(loanService.updateLoanStatus(eq(loanId), eq("INVALID_STATUS"), isNull()))
                .thenThrow(new RuntimeException("Trạng thái không hợp lệ: INVALID_STATUS"));

        // Act & Assert
        mockMvc.perform(post("/api/loans/{loanId}/status", loanId)
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Trạng thái không hợp lệ: INVALID_STATUS"));
    }

    @Test
    @WithMockUser(authorities = {"ROLE_admin"})
    public void testUpdateLoanStatus_BadRequest_EmptyStatus() throws Exception {
        // Arrange
        Long loanId = 1L;
        UpdateLoanStatusRequest request = new UpdateLoanStatusRequest();
        request.setStatus(""); // Empty status

        // Act & Assert
        mockMvc.perform(post("/api/loans/{loanId}/status", loanId)
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(authorities = {"ROLE_admin"})
    public void testUpdateLoanStatus_NotFound_LoanDoesNotExist() throws Exception {
        // Arrange
        Long loanId = 999L;
        UpdateLoanStatusRequest request = new UpdateLoanStatusRequest();
        request.setStatus("APPROVED");

        when(loanService.updateLoanStatus(eq(loanId), eq("APPROVED"), isNull()))
                .thenThrow(new RuntimeException("Không tìm thấy khoản vay"));

        // Act & Assert
        mockMvc.perform(post("/api/loans/{loanId}/status", loanId)
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Không tìm thấy khoản vay"));
    }
}
