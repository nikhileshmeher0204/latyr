package com.latyr.api.integration;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Service
public class WeatherIntegrationClient {

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Cacheable(value = "weatherCache", key = "#lat + '_' + #lon")
    public WeatherData getWeather(double lat, double lon) {
        try {
            // Open-Meteo Current Weather API
            String url = String.format("https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current_weather=true", lat, lon);
            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);
            
            if (root.has("current_weather")) {
                JsonNode current = root.get("current_weather");
                double temp = current.get("temperature").asDouble();
                int weatherCode = current.get("weathercode").asInt();
                return new WeatherData(temp, mapWeatherCode(weatherCode));
            }
        } catch (Exception e) {
            // fallback
        }
        return new WeatherData(0.0, "Unknown");
    }
    
    // IP based location using ip-api.com
    public LocationData getLocationFromIp(String ip) {
        try {
            // If local or loopback, fallback to a default (e.g. New York or San Francisco)
            if (ip == null || ip.equals("127.0.0.1") || ip.equals("0:0:0:0:0:0:0:1") || ip.startsWith("192.168.")) {
                return new LocationData(37.7749, -122.4194, "San Francisco");
            }
            String url = "http://ip-api.com/json/" + ip;
            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);
            if ("success".equals(root.get("status").asText())) {
                return new LocationData(
                    root.get("lat").asDouble(),
                    root.get("lon").asDouble(),
                    root.get("city").asText()
                );
            }
        } catch (Exception e) {
            // fallback
        }
        return new LocationData(37.7749, -122.4194, "San Francisco"); // Default to SF
    }

    private String mapWeatherCode(int code) {
        return switch (code) {
            case 0 -> "Clear Sky";
            case 1, 2, 3 -> "Partly Cloudy";
            case 45, 48 -> "Fog";
            case 51, 53, 55 -> "Drizzle";
            case 61, 63, 65 -> "Rain";
            case 71, 73, 75 -> "Snow";
            case 95, 96, 99 -> "Thunderstorm";
            default -> "Partly Cloudy";
        };
    }

    public record WeatherData(double temperature, String condition) {}
    public record LocationData(double lat, double lon, String city) {}
}
