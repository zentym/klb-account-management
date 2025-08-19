package com.kienlongbank.api_gateway.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

@Configuration
@EnableWebFluxSecurity // Dùng @EnableWebFluxSecurity cho Gateway
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        http
            .csrf(ServerHttpSecurity.CsrfSpec::disable)
            .authorizeExchange(exchange -> exchange
                .pathMatchers("/actuator/health", "/api/health").permitAll()
                .anyExchange().authenticated()
            )
            .oauth2ResourceServer(spec -> spec.jwt(Customizer.withDefaults())); // Kích hoạt xác thực JWT

            return http.build();
    }
}
