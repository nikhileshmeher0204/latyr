package com.latyr.api.domain.repository;

import com.latyr.api.domain.entity.NotificationLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationLogRepository extends JpaRepository<NotificationLog, UUID> {
    List<NotificationLog> findByUserIdOrderBySentAtDesc(UUID userId);
    boolean existsByUserIdAndSentAtAfter(UUID userId, Instant after);
}
