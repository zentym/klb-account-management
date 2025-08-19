package com.kienlongbank.klbaccountmanagement.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/**
 * Configuration cho HTTP clients
 */
@Configuration
public class HttpClientConfig {

    /**
     * RestTemplate bean (giữ lại cho backward compatibility)
     * Tuy nhiên, khuyến khích sử dụng Feign Client cho service-to-service communication
     */
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
