// // Keycloak Proxy Controller cho API Gateway
// // File: api-gateway/src/main/java/com/kienlongbank/gateway/controller/AuthProxyController.java

// package com.kienlongbank.gateway.controller;

// import java.util.Map;

// import org.springframework.beans.factory.annotation.Value;
// import org.springframework.http.HttpEntity;
// import org.springframework.http.HttpHeaders;
// import org.springframework.http.HttpStatus;
// import org.springframework.http.MediaType;
// import org.springframework.http.ResponseEntity;
// import org.springframework.web.bind.annotation.CrossOrigin;
// import org.springframework.web.bind.annotation.GetMapping;
// import org.springframework.web.bind.annotation.PostMapping;
// import org.springframework.web.bind.annotation.RequestBody;
// import org.springframework.web.bind.annotation.RequestMapping;
// import org.springframework.web.bind.annotation.RestController;
// import org.springframework.web.client.HttpClientErrorException;
// import org.springframework.web.client.RestTemplate;

// @RestController
// @RequestMapping("/api/auth")
// @CrossOrigin(origins = {"http://localhost:3000", "http://localhost:8000"})
// public class AuthProxyController {

//     @Value("${keycloak.auth-server-url:http://keycloak:8080}")
//     private String keycloakUrl;
    
//     @Value("${keycloak.realm:Kienlongbank}")
//     private String realm;

//     private final RestTemplate restTemplate = new RestTemplate();

//     /**
//      * Proxy endpoint for Keycloak token requests
//      * Solves CORS issues by acting as a server-side proxy
//      */
//     @PostMapping("/keycloak/token")
//     public ResponseEntity<?> getKeycloakToken(@RequestBody Map<String, String> loginRequest) {
//         try {
//             // Build Keycloak token URL
//             String tokenUrl = keycloakUrl + "/realms/" + realm + "/protocol/openid-connect/token";
            
//             // Prepare headers
//             HttpHeaders headers = new HttpHeaders();
//             headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            
//             // Build form data - support both phoneNumber and username for backward compatibility
//             StringBuilder formData = new StringBuilder();
//             formData.append("grant_type=").append(loginRequest.getOrDefault("grant_type", "password"));
//             formData.append("&client_id=").append(loginRequest.getOrDefault("client_id", "klb-frontend"));
            
//             // Check if phoneNumber is provided, otherwise use username
//             String usernameField = loginRequest.getOrDefault("phoneNumber", 
//                                   loginRequest.get("username"));
//             formData.append("&username=").append(usernameField);
//             formData.append("&password=").append(loginRequest.get("password"));
            
//             HttpEntity<String> request = new HttpEntity<>(formData.toString(), headers);
            
//             // Forward request to Keycloak
//             ResponseEntity<Map> response = restTemplate.postForEntity(tokenUrl, request, Map.class);
            
//             // Return the response from Keycloak
//             return ResponseEntity.ok(response.getBody());
            
//         } catch (HttpClientErrorException e) {
//             // Handle Keycloak errors (401, 400, etc.)
//             return ResponseEntity.status(e.getStatusCode()).body(Map.of(
//                 "error", "authentication_failed",
//                 "error_description", "Invalid credentials or client configuration"
//             ));
//         } catch (Exception e) {
//             // Handle other errors
//             return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
//                 "error", "server_error", 
//                 "error_description", "Unable to connect to authentication server"
//             ));
//         }
//     }

//     /**
//      * Proxy endpoint for token refresh
//      */
//     @PostMapping("/keycloak/refresh")
//     public ResponseEntity<?> refreshKeycloakToken(@RequestBody Map<String, String> refreshRequest) {
//         try {
//             String tokenUrl = keycloakUrl + "/realms/" + realm + "/protocol/openid-connect/token";
            
//             HttpHeaders headers = new HttpHeaders();
//             headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            
//             StringBuilder formData = new StringBuilder();
//             formData.append("grant_type=refresh_token");
//             formData.append("&client_id=").append(refreshRequest.getOrDefault("client_id", "klb-frontend"));
//             formData.append("&refresh_token=").append(refreshRequest.get("refresh_token"));
            
//             HttpEntity<String> request = new HttpEntity<>(formData.toString(), headers);
//             ResponseEntity<Map> response = restTemplate.postForEntity(tokenUrl, request, Map.class);
            
//             return ResponseEntity.ok(response.getBody());
            
//         } catch (HttpClientErrorException e) {
//             return ResponseEntity.status(e.getStatusCode()).body(Map.of(
//                 "error", "invalid_grant",
//                 "error_description", "Refresh token is invalid or expired"
//             ));
//         } catch (Exception e) {
//             return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
//                 "error", "server_error",
//                 "error_description", "Unable to refresh token"
//             ));
//         }
//     }

//     /**
//      * Proxy endpoint for logout
//      */
//     @PostMapping("/keycloak/logout")  
//     public ResponseEntity<?> logoutKeycloak(@RequestBody Map<String, String> logoutRequest) {
//         try {
//             String logoutUrl = keycloakUrl + "/realms/" + realm + "/protocol/openid-connect/logout";
            
//             HttpHeaders headers = new HttpHeaders();
//             headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            
//             StringBuilder formData = new StringBuilder();
//             formData.append("client_id=").append(logoutRequest.getOrDefault("client_id", "klb-frontend"));
//             if (logoutRequest.containsKey("refresh_token")) {
//                 formData.append("&refresh_token=").append(logoutRequest.get("refresh_token"));
//             }
            
//             HttpEntity<String> request = new HttpEntity<>(formData.toString(), headers);
//             restTemplate.postForEntity(logoutUrl, request, String.class);
            
//             return ResponseEntity.ok(Map.of("status", "success", "message", "Logged out successfully"));
            
//         } catch (Exception e) {
//             return ResponseEntity.ok(Map.of("status", "success", "message", "Logout completed locally"));
//         }
//     }

//     /**
//      * Health check endpoint
//      */
//     @GetMapping("/health")
//     public ResponseEntity<Map<String, String>> healthCheck() {
//         return ResponseEntity.ok(Map.of(
//             "status", "UP",
//             "keycloak", keycloakUrl,
//             "realm", realm,
//             "message", "Auth proxy is working"
//         ));
//     }
// }
