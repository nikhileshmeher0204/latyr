package com.latyr.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.latyr.api.controller.UserController;
import com.latyr.api.domain.enums.Language;
import com.latyr.api.domain.enums.PlanTier;
import com.latyr.api.dto.UpdatePreferencesRequest;
import com.latyr.api.dto.UserProfileResponse;
import com.latyr.api.security.AuthenticatedUser;
import com.latyr.api.security.CurrentUserArgumentResolver;
import com.latyr.api.service.UserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Instant;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class UserControllerTest {

    private MockMvc mockMvc;
    private UserService userService;
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

        userService = Mockito.mock(UserService.class);
        UserController userController = new UserController(userService);

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

        mockMvc = MockMvcBuilders.standaloneSetup(userController)
                .setCustomArgumentResolvers(resolver)
                .setMessageConverters(converter)
                .build();
    }

    @Test
    @DisplayName("GET /api/v1/users/me should return current user profile and quota")
    void testGetCurrentUserProfile_Success() throws Exception {
        UserProfileResponse response = UserProfileResponse.of(
                testUserId,
                "test@latyr.com",
                "Test User",
                "https://avatar.url",
                "Asia/Kolkata",
                Language.ENGLISH,
                PlanTier.FREE,
                5,
                30,
                Instant.now().plusSeconds(86400),
                Instant.now()
        );

        when(userService.getUserProfile(testUserId)).thenReturn(response);

        mockMvc.perform(get("/api/v1/users/me")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("test@latyr.com"))
                .andExpect(jsonPath("$.display_name").value("Test User"))
                .andExpect(jsonPath("$.plan_tier").value("FREE"))
                .andExpect(jsonPath("$.monthly_capture_count").value(5))
                .andExpect(jsonPath("$.quota_limit").value(30))
                .andExpect(jsonPath("$.remaining_quota").value(25));
    }

    @Test
    @DisplayName("PATCH /api/v1/users/preferences should update and return profile")
    void testUpdatePreferences_Success() throws Exception {
        UpdatePreferencesRequest request = new UpdatePreferencesRequest("America/New_York", Language.HINGLISH, "fcm_token_123");

        UserProfileResponse response = UserProfileResponse.of(
                testUserId,
                "test@latyr.com",
                "Test User",
                "https://avatar.url",
                "America/New_York",
                Language.HINGLISH,
                PlanTier.FREE,
                5,
                30,
                Instant.now().plusSeconds(86400),
                Instant.now()
        );

        when(userService.updatePreferences(eq(testUserId), any(UpdatePreferencesRequest.class))).thenReturn(response);

        mockMvc.perform(patch("/api/v1/users/preferences")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.timezone").value("America/New_York"))
                .andExpect(jsonPath("$.language").value("HINGLISH"));
    }
}
