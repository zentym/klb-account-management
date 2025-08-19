package com.kienlongbank.common.constants;

/**
 * Common constants used across different services
 */
public final class CustomerConstants {
    
    private CustomerConstants() {
        // Utility class - no instantiation
    }
    
    // Customer Status Constants
    public static final class Status {
        public static final String ACTIVE = "ACTIVE";
        public static final String INACTIVE = "INACTIVE";
        public static final String BLOCKED = "BLOCKED";
        public static final String PENDING = "PENDING";
    }
    
    // Customer Type Constants
    public static final class Type {
        public static final String INDIVIDUAL = "INDIVIDUAL";
        public static final String CORPORATE = "CORPORATE";
    }
    
    // Error Codes
    public static final class ErrorCode {
        public static final String CUSTOMER_NOT_FOUND = "CUSTOMER_NOT_FOUND";
        public static final String CUSTOMER_ALREADY_EXISTS = "CUSTOMER_ALREADY_EXISTS";
        public static final String INVALID_CUSTOMER_DATA = "INVALID_CUSTOMER_DATA";
        public static final String CUSTOMER_BLOCKED = "CUSTOMER_BLOCKED";
        public static final String EMAIL_ALREADY_EXISTS = "EMAIL_ALREADY_EXISTS";
        public static final String ID_NUMBER_ALREADY_EXISTS = "ID_NUMBER_ALREADY_EXISTS";
    }
    
    // Validation Constants
    public static final class Validation {
        public static final int MIN_FULL_NAME_LENGTH = 2;
        public static final int MAX_FULL_NAME_LENGTH = 100;
        public static final int MAX_EMAIL_LENGTH = 255;
        public static final int MAX_PHONE_LENGTH = 15;
        public static final int MAX_ADDRESS_LENGTH = 255;
        public static final int MAX_ID_NUMBER_LENGTH = 20;
    }
    
    // API Endpoints (for documentation purposes)
    public static final class Endpoints {
        public static final String BASE_PATH = "/api/customers";
        public static final String BY_ID = "/api/customers/{id}";
        public static final String BY_EMAIL = "/api/customers/email/{email}";
        public static final String BY_ID_NUMBER = "/api/customers/id-number/{idNumber}";
        public static final String BY_STATUS = "/api/customers/status/{status}";
        public static final String BY_TYPE = "/api/customers/type/{type}";
        public static final String SEARCH = "/api/customers/search";
    }
}
