package com.example.customer_service.exception;

import com.kienlongbank.common.dto.ApiResponse;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingPathVariableException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

/**
 * 🚨 Global Exception Handler for Customer Service
 * 
 * 🎯 Purpose: Centralized exception handling for consistent error responses
 * 🔧 Features: Validation errors, security exceptions, business logic exceptions
 * 📝 Response Format: Consistent ApiResponse format for all errors
 * 📊 Logging: Comprehensive logging for monitoring and debugging
 * 
 * @author GitHub Copilot
 * @version 1.1
 * @since August 2025
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    // ===== BUSINESS LOGIC EXCEPTIONS =====

    @ExceptionHandler(CustomerNotFoundException.class)
    public ResponseEntity<ApiResponse<Object>> handleCustomerNotFoundException(
            CustomerNotFoundException ex, WebRequest request) {
        
        log.warn("Customer not found: {} - URI: {}", ex.getMessage(), request.getDescription(false));
        
        ApiResponse<Object> response = ApiResponse.error(ex.getMessage());
        return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
    }

    /**
     * 🔧 Handle authentication and JWT-related runtime exceptions
     */
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<Object>> handleRuntimeException(
            RuntimeException ex, WebRequest request) {
        
        if (ex.getMessage() != null && ex.getMessage().contains("Invalid")) {
            log.warn("Authentication error: {} - URI: {}", ex.getMessage(), request.getDescription(false));
            ApiResponse<Object> response = ApiResponse.error(ex.getMessage());
            return new ResponseEntity<>(response, HttpStatus.UNAUTHORIZED);
        }
        
        log.error("Runtime exception: {} - URI: {}", ex.getMessage(), request.getDescription(false), ex);
        
        ApiResponse<Object> response = ApiResponse.error("Đã xảy ra lỗi hệ thống");
        return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    // ===== VALIDATION EXCEPTIONS =====

    /**
     * 📝 Handle validation errors for @Valid annotation
     * Triggered when request body validation fails
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleValidationExceptions(
            MethodArgumentNotValidException ex, WebRequest request) {
        
        Map<String, String> fieldErrors = new HashMap<>();
        
        // Lấy tất cả field errors
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            fieldErrors.put(fieldName, errorMessage);
        });
        
        log.warn("Validation failed for request: {} - Errors: {}", 
                 request.getDescription(false), fieldErrors);
        
        ApiResponse<Map<String, String>> response = ApiResponse.error("Dữ liệu đầu vào không hợp lệ");
        response.setData(fieldErrors);
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * 🔒 Handle constraint violation exceptions
     * Triggered when entity-level validations fail
     */
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleConstraintViolationException(
            ConstraintViolationException ex, WebRequest request) {
        
        Map<String, String> violations = new HashMap<>();
        
        for (ConstraintViolation<?> violation : ex.getConstraintViolations()) {
            String fieldName = violation.getPropertyPath().toString();
            String message = violation.getMessage();
            violations.put(fieldName, message);
        }
        
        log.warn("Constraint violation: {} - URI: {}", violations, request.getDescription(false));
        
        ApiResponse<Map<String, String>> response = ApiResponse.error("Vi phạm ràng buộc dữ liệu");
        response.setData(violations);
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    // ===== HTTP/REQUEST EXCEPTIONS =====

    /**
     * 📄 Handle unsupported media type (e.g., sending XML instead of JSON)
     */
    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleUnsupportedMediaType(
            HttpMediaTypeNotSupportedException ex, WebRequest request) {
        
        Map<String, String> errorDetails = new HashMap<>();
        errorDetails.put("supportedTypes", ex.getSupportedMediaTypes().toString());
        errorDetails.put("receivedType", ex.getContentType() != null ? ex.getContentType().toString() : "unknown");
        
        log.warn("Unsupported media type: {} - Supported: {} - URI: {}", 
                 ex.getContentType(), ex.getSupportedMediaTypes(), request.getDescription(false));
        
        ApiResponse<Map<String, String>> response = ApiResponse.error("Loại dữ liệu không được hỗ trợ. Vui lòng sử dụng Content-Type: application/json");
        response.setData(errorDetails);
        
        return ResponseEntity.status(HttpStatus.UNSUPPORTED_MEDIA_TYPE).body(response);
    }

    /**
     * 🌐 Handle unsupported HTTP methods
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleMethodNotAllowed(
            HttpRequestMethodNotSupportedException ex, WebRequest request) {
        
        Map<String, String> errorDetails = new HashMap<>();
        errorDetails.put("method", ex.getMethod());
        errorDetails.put("supportedMethods", String.join(", ", ex.getSupportedMethods()));
        
        log.warn("Method not allowed: {} - Supported: {} - URI: {}", 
                 ex.getMethod(), String.join(", ", ex.getSupportedMethods()), request.getDescription(false));
        
        ApiResponse<Map<String, String>> response = ApiResponse.error(
            "Phương thức HTTP không được hỗ trợ: " + ex.getMethod());
        response.setData(errorDetails);
        
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(response);
    }

    /**
     * 📝 Handle malformed JSON in request body
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Object>> handleHttpMessageNotReadable(
            HttpMessageNotReadableException ex, WebRequest request) {
        
        log.warn("Malformed JSON request: {} - URI: {}", ex.getMostSpecificCause().getMessage(), request.getDescription(false));
        
        ApiResponse<Object> response = ApiResponse.error("Dữ liệu JSON không hợp lệ. Vui lòng kiểm tra định dạng dữ liệu");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * 🔢 Handle type conversion errors (e.g., string to Long)
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleTypeMismatch(
            MethodArgumentTypeMismatchException ex, WebRequest request) {
        
        Map<String, String> errorDetails = new HashMap<>();
        errorDetails.put("parameter", ex.getName());
        errorDetails.put("expectedType", ex.getRequiredType() != null ? ex.getRequiredType().getSimpleName() : "unknown");
        errorDetails.put("actualValue", ex.getValue() != null ? ex.getValue().toString() : "null");
        
        log.warn("Type mismatch for parameter '{}': expected {} but received '{}' - URI: {}", 
                 ex.getName(), ex.getRequiredType(), ex.getValue(), request.getDescription(false));
        
        ApiResponse<Map<String, String>> response = ApiResponse.error(
            "Kiểu dữ liệu không đúng cho tham số: " + ex.getName());
        response.setData(errorDetails);
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * 📍 Handle missing path variables
     */
    @ExceptionHandler(MissingPathVariableException.class)
    public ResponseEntity<ApiResponse<Object>> handleMissingPathVariable(
            MissingPathVariableException ex, WebRequest request) {
        
        log.warn("Missing path variable '{}' - URI: {}", ex.getVariableName(), request.getDescription(false));
        
        ApiResponse<Object> response = ApiResponse.error("Thiếu tham số đường dẫn: " + ex.getVariableName());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * ❓ Handle missing request parameters
     */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiResponse<Object>> handleMissingRequestParameter(
            MissingServletRequestParameterException ex, WebRequest request) {
        
        log.warn("Missing request parameter '{}' of type '{}' - URI: {}", 
                 ex.getParameterName(), ex.getParameterType(), request.getDescription(false));
        
        ApiResponse<Object> response = ApiResponse.error("Thiếu tham số bắt buộc: " + ex.getParameterName());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    // ===== SECURITY EXCEPTIONS =====

    /**
     * 🔐 Handle authentication failures
     */
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiResponse<Object>> handleAuthenticationException(
            AuthenticationException ex, WebRequest request) {
        
        log.warn("Authentication failed: {} - URI: {}", ex.getMessage(), request.getDescription(false));
        
        ApiResponse<Object> response = ApiResponse.error("Xác thực thất bại. Vui lòng kiểm tra JWT token");
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
    }

    /**
     * 🚫 Handle access denied (user authenticated but lacks permissions)
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Object>> handleAccessDeniedException(
            AccessDeniedException ex, WebRequest request) {
        
        log.warn("Access denied: {} - URI: {}", ex.getMessage(), request.getDescription(false));
        
        ApiResponse<Object> response = ApiResponse.error("Bạn không có quyền truy cập tài nguyên này");
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
    }

    /**
     * 🔑 Handle bad credentials (invalid username/password)
     */
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ApiResponse<Object>> handleBadCredentialsException(
            BadCredentialsException ex, WebRequest request) {
        
        log.warn("Bad credentials: {} - URI: {}", ex.getMessage(), request.getDescription(false));
        
        ApiResponse<Object> response = ApiResponse.error("Thông tin xác thực không đúng");
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
    }

    // ===== DATABASE EXCEPTIONS =====

    /**
     * 🗃️ Handle SQL database errors
     */
    @ExceptionHandler(SQLException.class)
    public ResponseEntity<ApiResponse<Object>> handleSQLException(SQLException ex, WebRequest request) {
        
        String message = "Lỗi cơ sở dữ liệu";
        String logMessage = String.format("SQL Exception - State: %s, Code: %d, Message: %s", 
                                        ex.getSQLState(), ex.getErrorCode(), ex.getMessage());
        
        // Handle specific SQL error codes
        if (ex.getSQLState() != null && ex.getSQLState().length() >= 2) {
            switch (ex.getSQLState().substring(0, 2)) {
                case "23" -> { // Integrity constraint violation
                    if (ex.getMessage().toLowerCase().contains("duplicate") || 
                        ex.getMessage().toLowerCase().contains("unique")) {
                        message = "Dữ liệu đã tồn tại. Email có thể đã được sử dụng";
                    } else {
                        message = "Vi phạm ràng buộc dữ liệu";
                    }
                }
                case "42" -> message = "Lỗi truy vấn cơ sở dữ liệu"; // Syntax error or access rule violation
                case "08" -> message = "Lỗi kết nối cơ sở dữ liệu"; // Connection exception
            }
        }
        
        log.error("{} - URI: {}", logMessage, request.getDescription(false));
        
        ApiResponse<Object> response = ApiResponse.error(message);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }

    // ===== GENERIC EXCEPTIONS =====

    /**
     * 🚫 Handle 404 - No handler found
     */
    @ExceptionHandler(NoHandlerFoundException.class)
    public ResponseEntity<ApiResponse<Object>> handleNoHandlerFound(
            NoHandlerFoundException ex, WebRequest request) {
        
        log.warn("No handler found: {} {} - URI: {}", ex.getHttpMethod(), ex.getRequestURL(), request.getDescription(false));
        
        ApiResponse<Object> response = ApiResponse.error(
            "Endpoint không tồn tại: " + ex.getHttpMethod() + " " + ex.getRequestURL());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    /**
     * ⚠️ Handle all other unexpected exceptions
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Object>> handleGenericException(Exception ex, WebRequest request) {
        
        // Log full exception details for debugging
        log.error("Unexpected exception occurred - URI: {} - Exception: {}", 
                  request.getDescription(false), ex.getMessage(), ex);
        
        ApiResponse<Object> response = ApiResponse.error("Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau");
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}