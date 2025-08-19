package com.kienlongbank.klbaccountmanagement.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "core.banking.api")
@Data
public class CoreBankingConfig {
    
    private String url;
}
