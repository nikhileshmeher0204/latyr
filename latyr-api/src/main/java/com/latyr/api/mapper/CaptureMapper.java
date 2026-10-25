package com.latyr.api.mapper;

import com.latyr.api.config.typehandler.StringArrayTypeHandler;
import com.latyr.api.domain.enums.CaptureStatus;
import com.latyr.api.domain.enums.Intent;
import com.latyr.api.domain.model.Capture;
import org.apache.ibatis.annotations.*;

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
        @Result(property = "sourceType", column = "source_type"),
        @Result(property = "contentType", column = "content_type"),
        @Result(property = "status", column = "status"),
        @Result(property = "intent", column = "intent"),
        @Result(property = "category", column = "category"),
        @Result(property = "subCategory", column = "sub_category"),
        @Result(property = "tags", column = "tags", typeHandler = StringArrayTypeHandler.class),
        @Result(property = "title", column = "title"),
        @Result(property = "summary", column = "summary"),
        @Result(property = "originalCaption", column = "original_caption"),
        @Result(property = "thumbnailUrl", column = "thumbnail_url"),
        @Result(property = "audioTranscript", column = "audio_transcript"),
        @Result(property = "notificationCopies", column = "notification_copies", typeHandler = StringArrayTypeHandler.class),
        @Result(property = "resurfaceCount", column = "resurface_count"),
        @Result(property = "durationMs", column = "total_processing_duration_ms"),
        @Result(property = "scheduledResurfaceAt", column = "scheduled_resurface_at"),
        @Result(property = "lastResurfacedAt", column = "last_resurfaced_at"),
        @Result(property = "createdAt", column = "created_at"),
        @Result(property = "updatedAt", column = "updated_at")
    })
    Optional<Capture> findById(@Param("id") UUID id);

    @Select("SELECT * FROM captures WHERE id = #{id} AND user_id = #{userId}")
    @ResultMap("CaptureResult")
    Optional<Capture> findByIdAndUserId(@Param("id") UUID id, @Param("userId") UUID userId);

    @Select("""
        SELECT * FROM captures WHERE user_id = #{userId} AND canonical_source_id = #{canonicalSourceId}
        ORDER BY (status = 'COMPLETED') DESC, created_at DESC, id LIMIT 1
        """)
    @ResultMap("CaptureResult")
    Optional<Capture> findByUserIdAndCanonicalSourceId(@Param("userId") UUID userId, @Param("canonicalSourceId") UUID canonicalSourceId);

    @Select("SELECT * FROM captures WHERE user_id = #{userId} ORDER BY created_at DESC LIMIT #{limit} OFFSET #{offset}")
    @ResultMap("CaptureResult")
    List<Capture> findByUserId(@Param("userId") UUID userId, @Param("limit") int limit, @Param("offset") int offset);

    @Select("SELECT * FROM captures WHERE user_id = #{userId} AND status = #{status} ORDER BY created_at DESC LIMIT #{limit} OFFSET #{offset}")
    @ResultMap("CaptureResult")
    List<Capture> findByUserIdAndStatus(@Param("userId") UUID userId, @Param("status") CaptureStatus status, @Param("limit") int limit, @Param("offset") int offset);

    @Select("SELECT * FROM captures WHERE user_id = #{userId} AND category = #{category} ORDER BY created_at DESC LIMIT #{limit} OFFSET #{offset}")
    @ResultMap("CaptureResult")
    List<Capture> findByUserIdAndCategory(@Param("userId") UUID userId, @Param("category") String category, @Param("limit") int limit, @Param("offset") int offset);

    @Select("""
        SELECT * FROM captures 
        WHERE user_id = #{userId} 
          AND category = #{category}
          AND sub_category = #{subCategory}
        ORDER BY created_at DESC 
        LIMIT #{limit} OFFSET #{offset}
    """)
    @ResultMap("CaptureResult")
    List<Capture> findByUserIdAndCategoryAndSubCategory(
            @Param("userId") UUID userId,
            @Param("category") String category,
            @Param("subCategory") String subCategory,
            @Param("limit") int limit,
            @Param("offset") int offset
    );

    @Select("""
        SELECT COUNT(*) FROM captures 
        WHERE user_id = #{userId} 
          AND category = #{category}
          AND sub_category = #{subCategory}
    """)
    long countByUserIdAndCategoryAndSubCategory(
            @Param("userId") UUID userId,
            @Param("category") String category,
            @Param("subCategory") String subCategory
    );

    @Select("""
        SELECT 
            category,
            sub_category,
            COUNT(*) AS count
        FROM captures
        WHERE user_id = #{userId}
          AND category IS NOT NULL 
          AND category != ''
        GROUP BY category, sub_category
        ORDER BY category ASC, count DESC
    """)
    List<CategorySubCategoryCount> selectTaxonomyCountsByUserId(@Param("userId") UUID userId);

    @Select("""
        SELECT * FROM captures
        WHERE user_id = #{userId}
          AND status = 'COMPLETED'
          AND intent = #{intent}
          AND (last_resurfaced_at IS NULL OR last_resurfaced_at < (CURRENT_TIMESTAMP - INTERVAL '3 days'))
        ORDER BY resurface_count ASC, created_at DESC
        LIMIT #{limit}
    """)
    @ResultMap("CaptureResult")
    List<Capture> findResurfacingCandidatesByIntent(@Param("userId") UUID userId, @Param("intent") Intent intent, @Param("limit") int limit);

    @Select("""
        SELECT * FROM captures
        WHERE user_id = #{userId}
          AND status = 'COMPLETED'
          AND (last_resurfaced_at IS NULL OR last_resurfaced_at < (CURRENT_TIMESTAMP - INTERVAL '3 days'))
        ORDER BY resurface_count ASC, created_at DESC
        LIMIT #{limit}
    """)
    @ResultMap("CaptureResult")
    List<Capture> findGeneralResurfacingCandidates(@Param("userId") UUID userId, @Param("limit") int limit);

    @Select("SELECT COUNT(*) FROM captures WHERE user_id = #{userId}")
    long countByUserId(@Param("userId") UUID userId);

    @Select("SELECT COUNT(*) FROM captures WHERE user_id = #{userId} AND status = #{status}")
    long countByUserIdAndStatus(@Param("userId") UUID userId, @Param("status") CaptureStatus status);

    @Select("SELECT COUNT(*) FROM captures WHERE user_id = #{userId} AND category = #{category}")
    long countByUserIdAndCategory(@Param("userId") UUID userId, @Param("category") String category);

    @Insert("""
        INSERT INTO captures (
            id, user_id, canonical_source_id, source_type, content_type, status, intent, category, sub_category, tags,
            title, summary, original_caption, thumbnail_url, audio_transcript, notification_copies, resurface_count,
            total_processing_duration_ms, scheduled_resurface_at, last_resurfaced_at,
            created_at, updated_at
        )
        VALUES (
            COALESCE(#{id}, gen_random_uuid()),
            #{userId},
            #{canonicalSourceId},
            #{sourceType},
            #{contentType},
            #{status},
            #{intent},
            #{category},
            #{subCategory},
            #{tags, typeHandler=com.latyr.api.config.typehandler.StringArrayTypeHandler, jdbcType=ARRAY},
            #{title},
            #{summary},
            #{originalCaption},
            #{thumbnailUrl},
            #{audioTranscript},
            #{notificationCopies, typeHandler=com.latyr.api.config.typehandler.StringArrayTypeHandler, jdbcType=ARRAY},
            #{resurfaceCount},
            #{durationMs},
            #{scheduledResurfaceAt},
            #{lastResurfacedAt},
            COALESCE(#{createdAt}, CURRENT_TIMESTAMP),
            CURRENT_TIMESTAMP
        )
    """)
    int insert(Capture capture);

    @Update("""
        UPDATE captures
        SET status = #{status},
            source_type = #{sourceType},
            intent = #{intent},
            category = #{category},
            sub_category = #{subCategory},
            tags = #{tags, typeHandler=com.latyr.api.config.typehandler.StringArrayTypeHandler, jdbcType=ARRAY},
            title = #{title},
            summary = #{summary},
            original_caption = #{originalCaption},
            thumbnail_url = #{thumbnailUrl},
            audio_transcript = #{audioTranscript},
            notification_copies = #{notificationCopies, typeHandler=com.latyr.api.config.typehandler.StringArrayTypeHandler, jdbcType=ARRAY},
            resurface_count = #{resurfaceCount},
            total_processing_duration_ms = #{durationMs},
            scheduled_resurface_at = #{scheduledResurfaceAt},
            last_resurfaced_at = #{lastResurfacedAt},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = #{id}
    """)
    int update(Capture capture);

    @Update("""
        UPDATE captures
        SET thumbnail_url = #{thumbnailUrl},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = #{id}
    """)
    int updateThumbnailUrl(@Param("id") UUID id, @Param("thumbnailUrl") String thumbnailUrl);

    @Delete("DELETE FROM captures WHERE id = #{id}")
    int deleteById(@Param("id") UUID id);

    class CategorySubCategoryCount {
        private String category;
        private String subCategory;
        private long count;

        public String getCategory() { return category; }
        public void setCategory(String category) { this.category = category; }

        public String getSubCategory() { return subCategory; }
        public void setSubCategory(String subCategory) { this.subCategory = subCategory; }

        public long getCount() { return count; }
        public void setCount(long count) { this.count = count; }
    }
}
