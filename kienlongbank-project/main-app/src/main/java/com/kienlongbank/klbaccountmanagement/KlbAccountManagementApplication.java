package com.kienlongbank.klbaccountmanagement;

import org.apache.dubbo.config.spring.context.annotation.EnableDubbo;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@EnableDubbo
public class KlbAccountManagementApplication {

	public static void main(String[] args) {
		SpringApplication.run(KlbAccountManagementApplication.class, args);
	}

}
