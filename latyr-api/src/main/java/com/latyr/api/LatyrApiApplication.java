package com.latyr.api;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@MapperScan("com.latyr.api.mapper")
public class LatyrApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(LatyrApiApplication.class, args);
	}

}
