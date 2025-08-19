package com.kienlongbank.api_gateway.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.server.ServerWebExchange;

@Configuration
public class RequestLoggingFilterConfig {

    private static final Logger logger = LoggerFactory.getLogger(RequestLoggingFilterConfig.class);

    @Bean
    public GlobalFilter logFilter() {
        return (exchange, chain) -> {
            ServerWebExchange mutatedExchange = exchange.mutate().build();
            String method = mutatedExchange.getRequest().getMethod().name();
            String uri = mutatedExchange.getRequest().getURI().toString();
            
            logger.info("REQUEST DATA: {} {}", method, uri);
            
            return chain.filter(mutatedExchange);
        };
    }
}
