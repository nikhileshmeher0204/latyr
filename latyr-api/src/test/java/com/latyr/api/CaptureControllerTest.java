package com.latyr.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.latyr.api.controller.CaptureController;
import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.enums.ContentType;
import com.latyr.api.dto.CaptureResponse;
import com.latyr.api.dto.CreateCaptureRequest;
import com.latyr.api.dto.PagedResponse;
import com.latyr.api.security.AuthenticatedUser;
import com.latyr.api.service.CaptureService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

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

@ExtendWith(MockitoExtension.class)
class CaptureControllerTest {

    private MockMvc mockMvc;

    @Mock
    private CaptureService captureService;

    private final ObjectMapper mapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .setPropertyNamingStrategy(com.fasterxml.jackson.databind.PropertyNamingStrategies.SNAKE_CASE);
    private final UUID testUserId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        CaptureController controller = new CaptureController(captureService);

        HandlerMethodArgumentResolver resolver = new HandlerMethodArgumentResolver() {
            @Override
            public boolean supportsParameter(MethodParameter parameter) {
                return parameter.hasParameterAnnotation(com.latyr.api.security.CurrentUser.class) 
                        || parameter.getParameterType().equals(AuthenticatedUser.class);
            }

            @Override
            public Object resolveArgument(MethodParameter parameter,
                                          ModelAndViewContainer mavContainer,
                                          NativeWebRequest webRequest,
                                          WebDataBinderFactory binderFactory) {
                return new AuthenticatedUser(testUserId, "test-uid", "test@latyr.com");
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
                "Sci-Fi TV Shows",
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
                .andExpect(jsonPath("$.category").value("Entertainment"))
                .andExpect(jsonPath("$.sub_category").value("Sci-Fi TV Shows"));
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
                "Sci-Fi TV Shows",
                "5 movies",
                0,
                Instant.now(),
                Instant.now(),
                null
        );

        PagedResponse<CaptureResponse> pagedResponse = PagedResponse.of(List.of(captureItem), 0, 20, 1);
        when(captureService.getUserCaptures(eq(testUserId), any(), any(), eq(0), eq(20)))
                .thenReturn(pagedResponse);

        mockMvc.perform(get("/api/v1/captures")
                        .param("page", "0")
                        .param("size", "20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].status").value("COMPLETED"))
                .andExpect(jsonPath("$.items[0].category").value("Entertainment"))
                .andExpect(jsonPath("$.items[0].sub_category").value("Sci-Fi TV Shows"))
                .andExpect(jsonPath("$.pageable.total_elements").value(1));
    }
}
