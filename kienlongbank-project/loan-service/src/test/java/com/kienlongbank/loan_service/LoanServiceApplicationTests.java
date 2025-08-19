package com.kienlongbank.loan_service;

import com.kienlongbank.loan_service.entity.Loan;
import com.kienlongbank.loan_service.repository.LoanRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureWebMvc
class LoanServiceApplicationTests {

	@Autowired
	private MockMvc mockMvc;

	@MockBean
	private LoanRepository loanRepository;

	@Test
	void contextLoads() {
	}

	@Test
	@WithMockUser(roles = "customer")
	void testHealthEndpoint() throws Exception {
		mockMvc.perform(get("/api/loans/public/health"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.status").value("UP"))
			.andExpect(jsonPath("$.service").value("loan-service"));
	}

	@Test
	@WithMockUser(roles = "admin")
	void testGetLoanById() throws Exception {
		// Arrange
		Loan loan = new Loan();
		loan.setId(1L);
		loan.setCustomerId(1L);
		loan.setAmount(10000000.0);
		loan.setInterestRate(8.5);
		loan.setTerm(12);
		loan.setStatus(Loan.LoanStatus.PENDING);
		loan.setApplicationDate(LocalDateTime.now());

		when(loanRepository.findById(1L)).thenReturn(Optional.of(loan));

		// Act & Assert
		mockMvc.perform(get("/api/loans/1"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.id").value(1))
			.andExpect(jsonPath("$.customerId").value(1))
			.andExpect(jsonPath("$.amount").value(10000000.0))
			.andExpect(jsonPath("$.status").value("PENDING"));
	}

	@Test
	void testGetLoanById_Unauthorized() throws Exception {
		mockMvc.perform(get("/api/loans/1"))
			.andExpect(status().isUnauthorized());
	}
}
