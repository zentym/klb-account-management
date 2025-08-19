package com.kienlongbank.klbaccountmanagement.service;

import org.apache.dubbo.config.annotation.DubboReference;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.kienlongbank.common.api.CustomerApi;
import com.kienlongbank.common.dto.CustomerDTO;

/**
 * Service để gọi customer-service thông qua Dubbo RPC
 */
@Service
public class CustomerServiceClient {
    
    private static final Logger log = LoggerFactory.getLogger(CustomerServiceClient.class);

    @DubboReference
    private CustomerApi customerApi;

    /**
     * Kiểm tra xem customer có tồn tại không
     * @param customerId ID của customer
     * @return true nếu customer tồn tại, false nếu không
     */
    public boolean customerExists(Long customerId) {
        try {
            CustomerDTO customer = getCustomerById(customerId);
            return customer != null;
        } catch (Exception e) {
            log.error("Error checking customer existence for ID {}: {}", customerId, e.getMessage());
            return false;
        }
    }

    /**
     * Lấy thông tin customer theo ID thông qua Dubbo RPC
     * @param customerId ID của customer
     * @return CustomerDTO hoặc null nếu không tìm thấy
     */
    public CustomerDTO getCustomerById(Long customerId) {
        try {
            if (customerId == null) {
                log.warn("Customer ID is null");
                return null;
            }
            
            log.debug("Calling customer-service via Dubbo for customer ID: {}", customerId);
            CustomerDTO customer = customerApi.findCustomerById(customerId);
            
            if (customer != null) {
                log.debug("Found customer with ID {}: {}", customerId, customer.getFullName());
            } else {
                log.debug("Customer not found with ID: {}", customerId);
            }
            
            return customer;
        } catch (Exception e) {
            log.error("Error fetching customer with ID {}: {}", customerId, e.getMessage());
            return null;
        }
    }
}
