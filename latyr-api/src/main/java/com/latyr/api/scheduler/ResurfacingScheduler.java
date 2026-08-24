package com.latyr.api.scheduler;

import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.model.Capture;
import com.latyr.api.domain.model.NotificationLog;
import com.latyr.api.domain.model.User;
import com.latyr.api.mapper.CaptureMapper;
import com.latyr.api.mapper.NotificationLogMapper;
import com.latyr.api.mapper.UserMapper;
import com.latyr.api.service.FcmService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.*;
import java.util.List;
import java.util.Map;

@Component
public class ResurfacingScheduler {

    private static final Logger log = LoggerFactory.getLogger(ResurfacingScheduler.class);

    private final UserMapper userMapper;
    private final CaptureMapper captureMapper;
    private final NotificationLogMapper notificationLogMapper;
    private final FcmService fcmService;

    @Value("${resurfacing.scheduler.enabled:true}")
    private boolean schedulerEnabled;

    public ResurfacingScheduler(
            UserMapper userMapper,
            CaptureMapper captureMapper,
            NotificationLogMapper notificationLogMapper,
            FcmService fcmService) {
        this.userMapper = userMapper;
        this.captureMapper = captureMapper;
        this.notificationLogMapper = notificationLogMapper;
        this.fcmService = fcmService;
    }

    /**
     * Runs hourly batch job at minute 0.
     */
    @Scheduled(cron = "0 0 * * * *")
    public void runHourlyResurfacing() {
        if (!schedulerEnabled) {
            log.debug("Resurfacing scheduler is disabled in configuration.");
            return;
        }
        processHourlyResurfacing(Instant.now());
    }

    public int processHourlyResurfacing(Instant now) {
        List<User> users = userMapper.findAllUsersWithFcmToken();
        log.info("Running timezone-aware resurfacing check for {} registered user(s) with FCM token", users.size());

        int sentCount = 0;

        for (User user : users) {
            try {
                if (processUserResurfacing(user, now)) {
                    sentCount++;
                }
            } catch (Exception e) {
                log.warn("Error processing resurfacing for user {}: {}", user.getId(), e.getMessage());
            }
        }

        log.info("Hourly resurfacing check completed. Sent {} notification(s).", sentCount);
        return sentCount;
    }

    public boolean processUserResurfacing(User user, Instant now) {
        ZoneId zoneId;
        try {
            zoneId = ZoneId.of(user.getTimezone() != null ? user.getTimezone() : "UTC");
        } catch (Exception e) {
            zoneId = ZoneOffset.UTC;
        }

        ZonedDateTime localTime = now.atZone(zoneId);
        int hour = localTime.getHour();
        DayOfWeek day = localTime.getDayOfWeek();

        // 1. Do Not Disturb Window: Skip late night & early morning (10 PM - 9 AM local)
        if (hour < 9 || hour >= 22) {
            return false;
        }

        // 2. Frequency Capping: Strict Max 1 Notification/Day per user
        Instant startOfDay = localTime.toLocalDate().atStartOfDay(zoneId).toInstant();
        int sentToday = notificationLogMapper.countByUserIdAndSentAtAfter(user.getId(), startOfDay);
        if (sentToday >= 1) {
            log.debug("Skipping user {}: already received {} notification(s) today.", user.getId(), sentToday);
            return false;
        }

        // 3. Timezone Window Matching
        Intent targetIntent = null;
        if (day == DayOfWeek.FRIDAY && hour >= 19 && hour <= 21) {
            // Friday Night Watchlist Window
            targetIntent = Intent.WATCH;
        } else if ((day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY) && hour >= 11 && hour <= 13) {
            // Weekend Cooking & Recipe Window
            targetIntent = Intent.COOK;
        } else if (hour >= 20 && hour <= 21) {
            // General Evening Recall Window
            targetIntent = null;
        } else {
            // Outside of active targeted windows
            return false;
        }

        // 4. Select Candidate Capture
        List<Capture> candidates;
        if (targetIntent != null) {
            candidates = captureMapper.findResurfacingCandidatesByIntent(user.getId(), targetIntent, 1);
            if (candidates.isEmpty()) {
                candidates = captureMapper.findGeneralResurfacingCandidates(user.getId(), 1);
            }
        } else {
            candidates = captureMapper.findGeneralResurfacingCandidates(user.getId(), 1);
        }

        if (candidates == null || candidates.isEmpty()) {
            return false;
        }

        Capture capture = candidates.get(0);

        // 5. Select Notification Copy
        String body;
        if (capture.getNotificationCopies() != null && !capture.getNotificationCopies().isEmpty()) {
            body = capture.getNotificationCopies().get(0);
        } else if (capture.getCategory() != null) {
            body = "Revisit what you saved in " + capture.getCategory() + "!";
        } else {
            body = "Check out what you saved earlier on Latyr.";
        }

        String title = "Latyr Recall";

        // 6. Dispatch FCM Push Alert
        boolean delivered = fcmService.sendRichResurfacingNotification(
                user.getFcmToken(),
                title,
                body,
                capture.getId(),
                Map.of("capture_id", capture.getId().toString())
        );

        // 7. Audit & Update State
        NotificationLog nLog = new NotificationLog();
        nLog.setUserId(user.getId());
        nLog.setCaptureId(capture.getId());
        nLog.setNotificationType(targetIntent != null ? targetIntent.name() : "GENERAL");
        nLog.setSentCopy(body);
        nLog.setDeliveryStatus(delivered ? "DELIVERED" : "FAILED");
        nLog.setSentAt(now);
        notificationLogMapper.insert(nLog);

        capture.setLastResurfacedAt(now);
        capture.setResurfaceCount(capture.getResurfaceCount() + 1);
        captureMapper.update(capture);

        log.info("Dispatched resurfacing notification for capture {} to user {} (intent: {})", capture.getId(), user.getId(), targetIntent);
        return delivered;
    }
}
