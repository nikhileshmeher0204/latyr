package com.latyr.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.latyr.api.controller.CaptureController;
import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.enums.ContentType;
import com.latyr.api.domain.enums.PlanTier;
import com.latyr.api.dto.CaptureResponse;
import com.latyr.api.dto.CreateCaptureRequest;
import com.latyr.api.dto.PagedResponse;
import com.latyr.api.security.AuthenticatedUser;
import com.latyr.api.security.CurrentUserArgumentResolver;
import com.latyr.api.service.CaptureService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CaptureControllerTest {

    private MockMvc mockMvc;
    private CaptureService captureService;
    private ObjectMapper mapper;

    private final UUID testUserId = UUID.randomUUID();
    private final AuthenticatedUser mockUser = new AuthenticatedUser(
            testUserId,
            "firebase_uid_123",
            "test@latyr.com",
            "Test User",
            "https://avatar.url",
            PlanTier.FREE
    );

    @BeforeEach
    void setUp() {
        mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);

        captureService = Mockito.mock(CaptureService.class);
        CaptureController controller = new CaptureController(captureService);

        CurrentUserArgumentResolver resolver = new CurrentUserArgumentResolver() {
            @Override
            public Object resolveArgument(org.springframework.core.MethodParameter parameter,
                                          org.springframework.web.method.support.ModelAndViewContainer mavContainer,
                                          org.springframework.web.context.request.NativeWebRequest webRequest,
                                          org.springframework.web.bind.support.WebDataBinderFactory binderFactory) {
                return mockUser;
            }
        };

        MappingJackson2HttpMessageConverter converter = new MappingJackson2HttpMessageConverter(mapper);

        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setCustomArgumentResolvers(resolver)
                .setMessageConverters(converter)
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/captures on Cache Miss should return 202 Accepted")
    void testCreateUrlCapture_CacheMiss_Returns202() throws Exception {
        CreateCaptureRequest request = new CreateCaptureRequest("https://www.instagram.com/reel/C8xyz123/", ContentType.URL);
        CaptureResponse response = new CaptureResponse(
                UUID.randomUUID(),
                testUserId,
                UUID.randomUUID(),
                ContentType.URL,
                CaptureStatus.PENDING,
                null,
                null,
                null,
                0,
                Instant.now(),
                Instant.now(),
                "Capture queued for asynchronous AI analysis."
        );

        when(captureService.createUrlCapture(eq(testUserId), any(CreateCaptureRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/v1/captures")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(request)))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andExpect(jsonPath("$.content_type").value("URL"));
    }

    @Test
    @DisplayName("POST /api/v1/captures on Cache Hit should return 200 OK")
    void testCreateUrlCapture_CacheHit_Returns200() throws Exception {
        CreateCaptureRequest request = new CreateCaptureRequest("https://www.instagram.com/reel/C8xyz123/", ContentType.URL);
        CaptureResponse response = new CaptureResponse(
                UUID.randomUUID(),
                testUserId,
                UUID.randomUUID(),
                ContentType.URL,
                CaptureStatus.COMPLETED,
                com.latyr.api.domain.enums.Intent.WATCH,
                "Entertainment",
                "5 movies to watch",
                0,
                Instant.now(),
                Instant.now(),
                "Capture processed immediately from deduplication cache."
        );

        when(captureService.createUrlCapture(eq(testUserId), any(CreateCaptureRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/v1/captures")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.intent").value("WATCH"))
                .andExpect(jsonPath("$.category").value("Entertainment"));
    }

    @Test
    @DisplayName("GET /api/v1/captures should return paginated list")
    void testGetUserCaptures_Success() throws Exception {
        CaptureResponse captureItem = new CaptureResponse(
                UUID.randomUUID(),
                testUserId,
                UUID.randomUUID(),
                ContentType.URL,
                CaptureStatus.COMPLETED,
                com.latyr.api.domain.enums.Intent.WATCH,
                "Entertainment",
                "5 movies",
                0,
                Instant.now(),
                Instant.now(),
                null
        );

        PagedResponse<CaptureResponse> pagedResponse = PagedResponse.of(List.of(captureItem), 0, 20, 1);
        when(captureService.getUserCaptures(eq(testUserId), any(), any(), eq(0), eq(20)))
                .thenReturn(pagedResponse);

        mockMvc.perform(get("/api/v1/captures?page=0&size=20")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.items[0].status").value("COMPLETED"))
                .andExpect(jsonPath("$.pageable.total_elements").value(1))
                .andExpect(jsonPath("$.pageable.total_pages").value(1));
    }
}
