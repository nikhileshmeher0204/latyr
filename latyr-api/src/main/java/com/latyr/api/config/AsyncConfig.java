package com.latyr.api.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;

@Configuration
@EnableAsync
@EnableScheduling
public class AsyncConfig {

    @Bean(name = "virtualThreadExecutor", destroyMethod = "close")
    public ExecutorService virtualThreadExecutor() {
        return Executors.newVirtualThreadPerTaskExecutor();
    }

    @Bean(name = "ingestionLeaseHeartbeat", destroyMethod = "shutdownNow")
    public ScheduledExecutorService ingestionLeaseHeartbeat() {
        return Executors.newSingleThreadScheduledExecutor(
                Thread.ofPlatform().daemon().name("ingestion-lease-heartbeat").factory());
    }
}
