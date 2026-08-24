package com.latyr.api;

import com.latyr.api.domain.enums.ContentType;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.model.Capture;
import com.latyr.api.domain.model.User;
import com.latyr.api.mapper.CaptureMapper;
import com.latyr.api.mapper.NotificationLogMapper;
import com.latyr.api.mapper.UserMapper;
import com.latyr.api.scheduler.ResurfacingScheduler;
import com.latyr.api.service.FcmService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.*;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class ResurfacingSchedulerTest {

    private UserMapper userMapper;
    private CaptureMapper captureMapper;
    private NotificationLogMapper notificationLogMapper;
    private FcmService fcmService;

    private ResurfacingScheduler scheduler;

    @BeforeEach
    void setUp() {
        userMapper = mock(UserMapper.class);
        captureMapper = mock(CaptureMapper.class);
        notificationLogMapper = mock(NotificationLogMapper.class);
        fcmService = mock(FcmService.class);

        scheduler = new ResurfacingScheduler(
                userMapper,
                captureMapper,
                notificationLogMapper,
                fcmService
        );
    }

    @Test
    @DisplayName("Friday Night Watchlist: Should trigger resurfacing notification for WATCH intent")
    void testResurfacing_FridayNightWindow() {
        UUID userId = UUID.randomUUID();
        User user = new User();
        user.setId(userId);
        user.setTimezone("Asia/Kolkata");
        user.setFcmToken("fcm-token-123");

        // Friday 8:00 PM IST (14:30 UTC)
        ZonedDateTime fridayNight = ZonedDateTime.of(2026, 8, 28, 20, 0, 0, 0, ZoneId.of("Asia/Kolkata"));
        Instant now = fridayNight.toInstant();

        when(userMapper.findAllUsersWithFcmToken()).thenReturn(List.of(user));
        when(notificationLogMapper.countByUserIdAndSentAtAfter(eq(userId), any())).thenReturn(0);

        Capture movieCapture = new Capture();
        movieCapture.setId(UUID.randomUUID());
        movieCapture.setUserId(userId);
        movieCapture.setIntent(Intent.WATCH);
        movieCapture.setCategory("Entertainment");
        movieCapture.setNotificationCopies(List.of("Ready to unwind? Watch Dark tonight!"));

        when(captureMapper.findResurfacingCandidatesByIntent(eq(userId), eq(Intent.WATCH), eq(1)))
                .thenReturn(List.of(movieCapture));
        when(fcmService.sendRichResurfacingNotification(anyString(), anyString(), anyString(), any(), any()))
                .thenReturn(true);

        int sent = scheduler.processHourlyResurfacing(now);

        assertEquals(1, sent);
        verify(fcmService, times(1)).sendRichResurfacingNotification(
                eq("fcm-token-123"),
                eq("Latyr Recall"),
                eq("Ready to unwind? Watch Dark tonight!"),
                eq(movieCapture.getId()),
                any()
        );
        verify(notificationLogMapper, times(1)).insert(any());
        verify(captureMapper, times(1)).update(eq(movieCapture));
    }

    @Test
    @DisplayName("Frequency Capping: Should skip user who already received a notification today")
    void testResurfacing_FrequencyCapped() {
        UUID userId = UUID.randomUUID();
        User user = new User();
        user.setId(userId);
        user.setTimezone("Asia/Kolkata");
        user.setFcmToken("fcm-token-123");

        ZonedDateTime fridayNight = ZonedDateTime.of(2026, 8, 28, 20, 0, 0, 0, ZoneId.of("Asia/Kolkata"));
        Instant now = fridayNight.toInstant();

        when(userMapper.findAllUsersWithFcmToken()).thenReturn(List.of(user));
        // Already sent 1 notification today
        when(notificationLogMapper.countByUserIdAndSentAtAfter(eq(userId), any())).thenReturn(1);

        int sent = scheduler.processHourlyResurfacing(now);

        assertEquals(0, sent);
        verify(fcmService, never()).sendRichResurfacingNotification(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Do Not Disturb: Should skip user when local time is late night (e.g. 2:00 AM)")
    void testResurfacing_DoNotDisturbWindow() {
        UUID userId = UUID.randomUUID();
        User user = new User();
        user.setId(userId);
        user.setTimezone("America/New_York");
        user.setFcmToken("fcm-token-123");

        // 2:00 AM in New York
        ZonedDateTime lateNight = ZonedDateTime.of(2026, 8, 28, 2, 0, 0, 0, ZoneId.of("America/New_York"));
        Instant now = lateNight.toInstant();

        when(userMapper.findAllUsersWithFcmToken()).thenReturn(List.of(user));

        int sent = scheduler.processHourlyResurfacing(now);

        assertEquals(0, sent);
        verify(fcmService, never()).sendRichResurfacingNotification(any(), any(), any(), any(), any());
    }
}
