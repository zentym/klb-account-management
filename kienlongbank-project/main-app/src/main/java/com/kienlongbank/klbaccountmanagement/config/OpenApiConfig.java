package com.kienlongbank.klbaccountmanagement.config;

import java.util.List;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI klbAccountManagementOpenAPI() {
        Server devServer = new Server();
        devServer.setUrl("http://localhost:8080");
        devServer.setDescription("Development server");

        Contact contact = new Contact();
        contact.setEmail("admin@kienlongbank.com");
        contact.setName("KLB Development Team");

        License mitLicense = new License()
                .name("MIT License")
                .url("https://choosealicense.com/licenses/mit/");

        Info info = new Info()
                .title("KLB Account Management API")
                .version("1.0.0")
                .contact(contact)
                .description("API documentation for KLB Account Management System. " +
                           "This API provides endpoints for managing customers, accounts, and transactions. " +
                           "\n\n**Getting Started:**\n" +
                           "1. Create customers using the Customer Management endpoints\n" +
                           "2. Create accounts for customers using Account Management endpoints\n" +
                           "3. Perform transactions between accounts using Transaction endpoints\n\n" +
                           "**Note:** This system uses DTOs to prevent circular references in JSON responses.")
                .license(mitLicense);

        return new OpenAPI()
                .info(info)
                .servers(List.of(devServer));
    }
}
