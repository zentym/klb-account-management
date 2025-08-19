package com.kienlongbank.common.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Generic API Response wrapper for consistent response format across services
 * 
 * @param <T> the type of data being returned
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class ApiResponse<T> implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    private boolean success;
    private String message;
    private T data;
    private String errorCode;
    private LocalDateTime timestamp;
    
    // Default constructor
    public ApiResponse() {
        this.timestamp = LocalDateTime.now();
    }
    
    // Constructor for success response
    public ApiResponse(T data) {
        this();
        this.success = true;
        this.data = data;
        this.message = "Success";
    }
    
    // Constructor for success response with custom message
    public ApiResponse(T data, String message) {
        this();
        this.success = true;
        this.data = data;
        this.message = message;
    }
    
    // Constructor for error response
    public ApiResponse(String message, String errorCode) {
        this();
        this.success = false;
        this.message = message;
        this.errorCode = errorCode;
    }
    
    // Static factory methods for common responses
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(data);
    }
    
    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(data, message);
    }
    
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(message, null);
    }
    
    public static <T> ApiResponse<T> error(String message, String errorCode) {
        return new ApiResponse<>(message, errorCode);
    }
    
    // Getters and Setters
    public boolean isSuccess() {
        return success;
    }
    
    public void setSuccess(boolean success) {
        this.success = success;
    }
    
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
    
    public T getData() {
        return data;
    }
    
    public void setData(T data) {
        this.data = data;
    }
    
    public String getErrorCode() {
        return errorCode;
    }
    
    public void setErrorCode(String errorCode) {
        this.errorCode = errorCode;
    }
    
    public LocalDateTime getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
    
    @Override
    public String toString() {
        return "ApiResponse{" +
                "success=" + success +
                ", message='" + message + '\'' +
                ", data=" + data +
                ", errorCode='" + errorCode + '\'' +
                ", timestamp=" + timestamp +
                '}';
    }
}
