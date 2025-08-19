package com.kienlongbank.klbaccountmanagement;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

import com.kienlongbank.common.dto.ApiResponse;

/**
 * Test để verify rằng ApiResponse migration thành công
 */
public class ApiResponseMigrationTest {

    @Test
    public void testApiResponseFromCommonApi() {
        // Test static factory method
        ApiResponse<String> successResponse = ApiResponse.success("test data", "Success message");
        
        assertTrue(successResponse.isSuccess());
        assertEquals("test data", successResponse.getData());
        assertEquals("Success message", successResponse.getMessage());
        assertNotNull(successResponse.getTimestamp());
        
        // Test error response
        ApiResponse<String> errorResponse = ApiResponse.error("Error message", "ERROR_CODE");
        
        assertFalse(errorResponse.isSuccess());
        assertEquals("Error message", errorResponse.getMessage());
        assertEquals("ERROR_CODE", errorResponse.getErrorCode());
        assertNotNull(errorResponse.getTimestamp());
    }
    
    @Test
    public void testConstructors() {
        // Test data constructor
        ApiResponse<String> dataResponse = new ApiResponse<>("test data");
        assertTrue(dataResponse.isSuccess());
        assertEquals("test data", dataResponse.getData());
        assertEquals("Success", dataResponse.getMessage());
        
        // Test data + message constructor  
        ApiResponse<String> dataMessageResponse = new ApiResponse<>("test data", "Custom message");
        assertTrue(dataMessageResponse.isSuccess());
        assertEquals("test data", dataMessageResponse.getData());
        assertEquals("Custom message", dataMessageResponse.getMessage());
    }
}
