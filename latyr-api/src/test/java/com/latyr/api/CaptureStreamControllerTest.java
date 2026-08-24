package com.latyr.api;

import com.latyr.api.controller.CaptureStreamController;
import com.latyr.api.security.AuthenticatedUser;
import com.latyr.api.security.CurrentUserArgumentResolver;
import com.latyr.api.service.SseNotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CaptureStreamControllerTest {

    private MockMvc mockMvc;
    private SseNotificationService sseNotificationService;
    private UUID testUserId;

    @BeforeEach
    void setUp() {
        sseNotificationService = mock(SseNotificationService.class);
        testUserId = UUID.randomUUID();

        HandlerMethodArgumentResolver customResolver = new CurrentUserArgumentResolver() {
            @Override
            public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,
                                          NativeWebRequest webRequest, WebDataBinderFactory binderFactory) {
                return new AuthenticatedUser(testUserId, "test-uid-123", "test@latyr.com", "Tester", null, com.latyr.api.domain.enums.PlanTier.FREE);
            }
        };

        mockMvc = MockMvcBuilders.standaloneSetup(new CaptureStreamController(sseNotificationService))
                .setCustomArgumentResolvers(customResolver)
                .build();
    }

    @Test
    @DisplayName("GET /api/v1/captures/stream should return SSE connection")
    void testSubscribeToStream() throws Exception {
        when(sseNotificationService.subscribe(eq(testUserId))).thenReturn(new SseEmitter());

        mockMvc.perform(get("/api/v1/captures/stream")
                        .accept(MediaType.TEXT_EVENT_STREAM_VALUE))
                .andExpect(status().isOk());

        verify(sseNotificationService, times(1)).subscribe(testUserId);
    }
}
