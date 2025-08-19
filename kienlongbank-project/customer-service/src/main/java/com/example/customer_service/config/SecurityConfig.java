package com.example.customer_service.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

/**
 * Security Configuration for Customer Service
 * - Protects all endpoints with JWT authentication
 * - Connects to Keycloak for token validation
 * - Extracts roles from JWT token for authorization
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Public endpoints - không cần authentication
                .requestMatchers(
                    "/swagger-ui/**", 
                    "/swagger-ui.html",
                    "/v3/api-docs/**", 
                    "/api-docs/**",
                    "/actuator/health",
                    "/actuator/info"
                ).permitAll()
                
                // Admin endpoints - chỉ dành cho ADMIN role
                .requestMatchers("/api/admin/**").hasAuthority("ADMIN")
                
                // Customer endpoints - cần authentication, phân quyền theo business logic
                .requestMatchers("/api/customers/**").authenticated()
                
                // Tất cả requests khác đều cần authentication
                .anyRequest().authenticated()
            ).oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtAuthenticationConverter(jwtAuthenticationConverter())
                )
            );

        return http.build();
    }

    /**
     * Custom JWT Authentication Converter để extract roles từ Keycloak JWT token
     * Keycloak stores roles trong realm_access.roles claim
     */
    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        // Converter cho standard scopes
        JwtGrantedAuthoritiesConverter authoritiesConverter = new JwtGrantedAuthoritiesConverter();
        authoritiesConverter.setAuthorityPrefix(""); // Không thêm prefix cho scopes
        
        // Custom converter để handle cả scopes và realm roles
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            // Lấy authorities từ standard scopes
            Collection<GrantedAuthority> authorities = authoritiesConverter.convert(jwt);
            
            // Extract realm roles từ Keycloak JWT
            Collection<GrantedAuthority> realmRoles = extractRealmRoles(jwt.getClaims());
            
            // Combine cả scopes và realm roles
            return Stream.concat(authorities.stream(), realmRoles.stream()).toList();
        });
        
        return converter;
    }

    /**
     * Extract roles từ realm_access claim trong Keycloak JWT token
     */
    @SuppressWarnings("unchecked")
    private Collection<GrantedAuthority> extractRealmRoles(Map<String, Object> claims) {
        // Keycloak stores realm roles in realm_access.roles
        Map<String, Object> realmAccess = (Map<String, Object>) claims.get("realm_access");
        
        if (realmAccess == null) {
            return Collections.emptyList();
        }
        
        List<String> roles = (List<String>) realmAccess.get("roles");
        
        if (roles == null) {
            return Collections.emptyList();
        }
        
        // Convert roles to authorities (không thêm ROLE_ prefix vì Keycloak đã có)
        return roles.stream()
            .map(role -> (GrantedAuthority) new SimpleGrantedAuthority(role))
            .toList();
    }
}
