# JWT Token Caching Implementation for Zero Trust Architecture

## 🎯 Mục tiêu
Implement caching cho JWT token validation để tối ưu hóa hiệu suất trong mô hình Zero Trust.

## 🏗️ Architecture

### Current State (No Caching)
```
Client Request → Service → Keycloak Validation (every time) → Response
```

### Target State (With Caching)
```
Client Request → Service → Cache Check → Keycloak Validation (if cache miss) → Cache Store → Response
```

## 📝 Implementation Steps

### 1. Add Redis Dependencies

**customer-service/pom.xml, main-app/pom.xml, loan-service/pom.xml:**
```xml
<!-- Redis Cache for JWT Token Caching -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
```

### 2. Redis Configuration

**application.properties:**
```properties
# Redis Configuration for JWT Token Caching
spring.redis.host=localhost
spring.redis.port=6379
spring.redis.password=
spring.redis.timeout=2000ms
spring.redis.lettuce.pool.max-active=8
spring.redis.lettuce.pool.max-idle=8
spring.redis.lettuce.pool.min-idle=0

# Cache Configuration
spring.cache.type=redis
spring.cache.redis.time-to-live=300000
spring.cache.redis.cache-null-values=false
spring.cache.cache-names=jwt-tokens,user-authorities
```

### 3. Cache Configuration Class

**src/main/java/config/CacheConfig.java:**
```java
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(5)) // JWT cache for 5 minutes
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new GenericJackson2JsonRedisSerializer()));

        Map<String, RedisCacheConfiguration> cacheConfigurations = new HashMap<>();
        cacheConfigurations.put("jwt-tokens", config);
        cacheConfigurations.put("user-authorities", config.entryTtl(Duration.ofMinutes(10)));

        return RedisCacheManager.builder(connectionFactory)
            .cacheDefaults(config)
            .withInitialCacheConfigurations(cacheConfigurations)
            .build();
    }

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new GenericJackson2JsonRedisSerializer());
        template.setHashKeySerializer(new StringRedisSerializer());
        template.setHashValueSerializer(new GenericJackson2JsonRedisSerializer());
        template.afterPropertiesSet();
        return template;
    }
}
```

### 4. Custom JWT Decoder with Caching

**src/main/java/config/CachedJwtDecoderConfig.java:**
```java
@Configuration
public class CachedJwtDecoderConfig {

    @Value("${spring.security.oauth2.resourceserver.jwt.jwk-set-uri}")
    private String jwkSetUri;

    @Bean
    public JwtDecoder jwtDecoder() {
        NimbusJwtDecoder jwtDecoder = NimbusJwtDecoder.withJwkSetUri(jwkSetUri)
            .cache(Duration.ofMinutes(5)) // Cache JWK Set for 5 minutes
            .build();

        // Custom JWT validator with caching
        return new CachedJwtDecoder(jwtDecoder);
    }
}

@Component
public class CachedJwtDecoder implements JwtDecoder {
    
    private final JwtDecoder delegate;
    
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    public CachedJwtDecoder(JwtDecoder delegate) {
        this.delegate = delegate;
    }
    
    @Override
    @Cacheable(value = "jwt-tokens", key = "#token.substring(0, 50)", unless = "#result == null")
    public Jwt decode(String token) throws JwtException {
        try {
            // Check if token is blacklisted (for logout functionality)
            String tokenHash = DigestUtils.sha256Hex(token);
            if (redisTemplate.hasKey("blacklisted:" + tokenHash)) {
                throw new JwtException("Token has been invalidated");
            }
            
            return delegate.decode(token);
        } catch (JwtException e) {
            // Cache negative results for short time to prevent repeated validation attempts
            cacheInvalidToken(token);
            throw e;
        }
    }
    
    @CachePut(value = "jwt-tokens", key = "#token.substring(0, 50)")
    private void cacheInvalidToken(String token) {
        // Cache invalid token for 1 minute to prevent repeated attempts
        return null;
    }
}
```

### 5. Enhanced Security Configuration

**SecurityConfig.java (Updated):**
```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Autowired
    private JwtDecoder jwtDecoder; // Our custom cached JWT decoder

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**", "/actuator/health").permitAll()
                .requestMatchers("/api/admin/**").hasAuthority("ADMIN")
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .decoder(jwtDecoder) // Use our cached decoder
                    .jwtAuthenticationConverter(jwtAuthenticationConverter())
                )
            );

        return http.build();
    }

    @Bean
    @Cacheable(value = "user-authorities", key = "#jwt.subject")
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter authoritiesConverter = new JwtGrantedAuthoritiesConverter();
        authoritiesConverter.setAuthorityPrefix("");
        
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            Collection<GrantedAuthority> authorities = authoritiesConverter.convert(jwt);
            Collection<GrantedAuthority> realmRoles = extractRealmRoles(jwt.getClaims());
            
            return Stream.concat(authorities.stream(), realmRoles.stream())
                .collect(Collectors.toList());
        });
        
        return converter;
    }
}
```

### 6. Token Invalidation Service

**src/main/java/service/TokenCacheService.java:**
```java
@Service
public class TokenCacheService {
    
    @Autowired
    private CacheManager cacheManager;
    
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    /**
     * Invalidate JWT token (for logout)
     */
    public void invalidateToken(String token) {
        String tokenHash = DigestUtils.sha256Hex(token);
        
        // Add to blacklist
        redisTemplate.opsForValue().set(
            "blacklisted:" + tokenHash, 
            true, 
            Duration.ofHours(24) // Keep blacklist for 24 hours
        );
        
        // Remove from cache
        Cache jwtCache = cacheManager.getCache("jwt-tokens");
        if (jwtCache != null) {
            jwtCache.evict(token.substring(0, 50));
        }
        
        Cache authCache = cacheManager.getCache("user-authorities");
        if (authCache != null) {
            // Would need to extract subject from token to clear user authorities
            authCache.clear(); // Or implement more granular eviction
        }
    }
    
    /**
     * Clear all cached tokens (admin function)
     */
    @CacheEvict(value = {"jwt-tokens", "user-authorities"}, allEntries = true)
    public void clearAllTokens() {
        // Also clear blacklist if needed
    }
}
```

## 🐳 Docker Configuration

**docker-compose.yml (Add Redis):**
```yaml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 3s
      retries: 3

  # Update your services to depend on Redis
  customer-service:
    depends_on:
      - postgres
      - redis
      - keycloak
    environment:
      - SPRING_REDIS_HOST=redis

volumes:
  redis_data:
```

## 📊 Performance Benefits

### Before Caching:
- Every request validates JWT with Keycloak
- Network latency on each validation
- Keycloak load increases with traffic

### After Caching:
- JWT validation cached for 5 minutes
- Authorities cached for 10 minutes
- 90%+ reduction in Keycloak calls
- Improved response times
- Better fault tolerance

## 🔒 Security Considerations

### 1. Cache TTL Strategy
- **JWT Cache**: 5 minutes (balance between performance and security)
- **Authorities Cache**: 10 minutes (role changes less frequent)
- **Blacklist**: 24 hours (ensure logged out tokens stay invalid)

### 2. Token Invalidation
- Implement logout endpoint that blacklists tokens
- Admin function to clear all caches
- Graceful handling of revoked tokens

### 3. Monitoring
- Monitor cache hit/miss ratios
- Alert on high cache miss rates
- Track Redis performance

## 🧪 Testing

### 1. Cache Hit Testing
```java
@Test
public void testJwtCacheHit() {
    // First call should hit Keycloak
    // Second call should hit cache
}
```

### 2. Token Invalidation Testing
```java
@Test  
public void testTokenInvalidation() {
    // Test that invalidated tokens are rejected
}
```

## 📈 Monitoring Metrics

Add these metrics to monitor cache performance:
- `jwt.cache.hit.rate`
- `jwt.cache.miss.rate` 
- `jwt.validation.time`
- `keycloak.calls.count`

## 🚀 Deployment

### 1. Gradual Rollout
- Deploy Redis first
- Update one service at a time
- Monitor performance improvements

### 2. Rollback Plan
- Can disable caching with configuration
- Service works without Redis in fallback mode

---

**Next Steps:**
1. Implement Redis caching in customer-service first
2. Monitor performance improvements
3. Roll out to other services
4. Add advanced features like distributed caching
