package com.latyr.api.mapper;

import com.latyr.api.domain.model.NotificationLog;
import org.apache.ibatis.annotations.*;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Mapper
public interface NotificationLogMapper {

    @Select("SELECT * FROM notification_logs WHERE id = #{id}")
    Optional<NotificationLog> findById(@Param("id") UUID id);

    @Select("SELECT * FROM notification_logs WHERE user_id = #{userId} ORDER BY sent_at DESC")
    List<NotificationLog> findByUserId(@Param("userId") UUID userId);

    @Select("SELECT * FROM notification_logs WHERE capture_id = #{captureId} ORDER BY sent_at DESC")
    List<NotificationLog> findByCaptureId(@Param("captureId") UUID captureId);

    @Select("SELECT COUNT(*) FROM notification_logs WHERE user_id = #{userId} AND sent_at >= #{since}")
    int countByUserIdAndSentAtAfter(@Param("userId") UUID userId, @Param("since") Instant since);

    @Insert("""
        INSERT INTO notification_logs (id, user_id, capture_id, notification_type, sent_copy, delivery_status, attempt_number, sent_at)
        VALUES (COALESCE(#{id}, gen_random_uuid()), #{userId}, #{captureId}, #{notificationType}, #{sentCopy}, #{deliveryStatus}, #{attemptNumber}, COALESCE(#{sentAt}, CURRENT_TIMESTAMP))
    """)
    int insert(NotificationLog log);
}
