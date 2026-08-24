package com.latyr.api.mapper;

import com.latyr.api.config.typehandler.StringArrayTypeHandler;
import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.model.Capture;
import org.apache.ibatis.annotations.*;
import org.apache.ibatis.type.JdbcType;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Mapper
public interface CaptureMapper {

    @Select("SELECT * FROM captures WHERE id = #{id}")
    @Results(id = "CaptureResult", value = {
        @Result(property = "id", column = "id"),
        @Result(property = "userId", column = "user_id"),
        @Result(property = "canonicalSourceId", column = "canonical_source_id"),
        @Result(property = "contentType", column = "content_type"),
        @Result(property = "status", column = "status"),
        @Result(property = "intent", column = "intent"),
        @Result(property = "category", column = "category"),
        @Result(property = "originalCaption", column = "original_caption"),
        @Result(property = "audioTranscript", column = "audio_transcript"),
        @Result(property = "notificationCopies", column = "notification_copies", typeHandler = StringArrayTypeHandler.class),
        @Result(property = "resurfaceCount", column = "resurface_count"),
        @Result(property = "durationMs", column = "duration_ms"),
        @Result(property = "videoDurationSec", column = "video_duration_sec"),
        @Result(property = "createdAt", column = "created_at"),
        @Result(property = "updatedAt", column = "updated_at")
    })
    Optional<Capture> findById(@Param("id") UUID id);

    @Select("SELECT * FROM captures WHERE id = #{id} AND user_id = #{userId}")
    @ResultMap("CaptureResult")
    Optional<Capture> findByIdAndUserId(@Param("id") UUID id, @Param("userId") UUID userId);

    @Select("SELECT * FROM captures WHERE user_id = #{userId} ORDER BY created_at DESC LIMIT #{limit} OFFSET #{offset}")
    @ResultMap("CaptureResult")
    List<Capture> findByUserId(@Param("userId") UUID userId, @Param("limit") int limit, @Param("offset") int offset);

    @Select("SELECT * FROM captures WHERE user_id = #{userId} AND status = #{status} ORDER BY created_at DESC LIMIT #{limit} OFFSET #{offset}")
    @ResultMap("CaptureResult")
    List<Capture> findByUserIdAndStatus(@Param("userId") UUID userId, @Param("status") CaptureStatus status, @Param("limit") int limit, @Param("offset") int offset);

    @Select("SELECT * FROM captures WHERE user_id = #{userId} AND category = #{category} ORDER BY created_at DESC LIMIT #{limit} OFFSET #{offset}")
    @ResultMap("CaptureResult")
    List<Capture> findByUserIdAndCategory(@Param("userId") UUID userId, @Param("category") String category, @Param("limit") int limit, @Param("offset") int offset);

    @Select("SELECT COUNT(*) FROM captures WHERE user_id = #{userId}")
    long countByUserId(@Param("userId") UUID userId);

    @Select("SELECT COUNT(*) FROM captures WHERE user_id = #{userId} AND status = #{status}")
    long countByUserIdAndStatus(@Param("userId") UUID userId, @Param("status") CaptureStatus status);

    @Select("SELECT COUNT(*) FROM captures WHERE user_id = #{userId} AND category = #{category}")
    long countByUserIdAndCategory(@Param("userId") UUID userId, @Param("category") String category);

    @Insert("""
        INSERT INTO captures (
            id, user_id, canonical_source_id, content_type, status, intent, category,
            original_caption, audio_transcript, notification_copies, resurface_count,
            duration_ms, video_duration_sec, created_at, updated_at
        )
        VALUES (
            COALESCE(#{id}, gen_random_uuid()),
            #{userId},
            #{canonicalSourceId},
            #{contentType},
            #{status},
            #{intent},
            #{category},
            #{originalCaption},
            #{audioTranscript},
            #{notificationCopies, typeHandler=com.latyr.api.config.typehandler.StringArrayTypeHandler, jdbcType=ARRAY},
            #{resurfaceCount},
            #{durationMs},
            #{videoDurationSec},
            COALESCE(#{createdAt}, CURRENT_TIMESTAMP),
            CURRENT_TIMESTAMP
        )
    """)
    int insert(Capture capture);

    @Update("""
        UPDATE captures
        SET status = #{status},
            intent = #{intent},
            category = #{category},
            original_caption = #{originalCaption},
            audio_transcript = #{audioTranscript},
            notification_copies = #{notificationCopies, typeHandler=com.latyr.api.config.typehandler.StringArrayTypeHandler, jdbcType=ARRAY},
            resurface_count = #{resurfaceCount},
            duration_ms = #{durationMs},
            video_duration_sec = #{videoDurationSec},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = #{id}
    """)
    int update(Capture capture);

    @Delete("DELETE FROM captures WHERE id = #{id}")
    int deleteById(@Param("id") UUID id);
}
