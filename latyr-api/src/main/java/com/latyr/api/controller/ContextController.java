package com.latyr.api.controller;

import com.latyr.api.integration.WeatherIntegrationClient;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/context")
public class ContextController {

    private final WeatherIntegrationClient weatherClient;

    public ContextController(WeatherIntegrationClient weatherClient) {
        this.weatherClient = weatherClient;
    }

    @GetMapping("/weather")
    public ResponseEntity<WeatherContextResponse> getWeatherContext(
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lon,
            HttpServletRequest request
    ) {
        WeatherIntegrationClient.LocationData location;
        if (lat != null && lon != null) {
            location = new WeatherIntegrationClient.LocationData(lat, lon, "Local Area");
        } else {
            // Fallback to IP
            String ip = getClientIp(request);
            location = weatherClient.getLocationFromIp(ip);
        }

        WeatherIntegrationClient.WeatherData weather = weatherClient.getWeather(location.lat(), location.lon());

        return ResponseEntity.ok(new WeatherContextResponse(
                location.city(),
                weather.temperature(),
                weather.condition()
        ));
    }

    private String getClientIp(HttpServletRequest request) {
        String xfHeader = request.getHeader("X-Forwarded-For");
        if (xfHeader == null || xfHeader.isEmpty()) {
            return request.getRemoteAddr();
        }
        return xfHeader.split(",")[0];
    }
    
    public record WeatherContextResponse(String city, double temperature, String condition) {}
}
