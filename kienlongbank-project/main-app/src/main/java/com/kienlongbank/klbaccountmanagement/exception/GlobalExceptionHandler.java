package com.kienlongbank.klbaccountmanagement.exception;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import com.kienlongbank.common.dto.ApiResponse;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;

@ControllerAdvice
public class GlobalExceptionHandler {

    // Xử lý validation errors cho @Valid annotation
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleValidationExceptions(
            MethodArgumentNotValidException ex) {
        
        Map<String, String> fieldErrors = new HashMap<>();
        
        // Lấy tất cả field errors
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            fieldErrors.put(fieldName, errorMessage);
        });
        
        ApiResponse<Map<String, String>> response = ApiResponse.error("Dữ liệu đầu vào không hợp lệ");
        response.setData(fieldErrors);
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    // Xử lý constraint violation exceptions
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleConstraintViolationException(
            ConstraintViolationException ex) {
        
        Map<String, String> violations = new HashMap<>();
        
        for (ConstraintViolation<?> violation : ex.getConstraintViolations()) {
            String fieldName = violation.getPropertyPath().toString();
            String message = violation.getMessage();
            violations.put(fieldName, message);
        }
        
        ApiResponse<Map<String, String>> response = ApiResponse.error("Vi phạm ràng buộc dữ liệu");
        response.setData(violations);
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleUnsupportedMediaType(
            HttpMediaTypeNotSupportedException ex) {
        
        Map<String, String> errorDetails = new HashMap<>();
        errorDetails.put("supportedTypes", ex.getSupportedMediaTypes().toString());
        errorDetails.put("receivedType", ex.getContentType() != null ? ex.getContentType().toString() : "unknown");
        
        ApiResponse<Map<String, String>> response = ApiResponse.error("Loại dữ liệu không được hỗ trợ. Vui lòng sử dụng Content-Type: application/json");
        response.setData(errorDetails);
        
        return ResponseEntity.status(HttpStatus.UNSUPPORTED_MEDIA_TYPE).body(response);
    }
}
