package com.latyr.api.mapper;

import com.latyr.api.config.typehandler.JsonbTypeHandler;
import com.latyr.api.domain.model.ExtractedEntity;
import org.apache.ibatis.annotations.*;
import org.apache.ibatis.type.JdbcType;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Mapper
public interface ExtractedEntityMapper {

    @Select("SELECT * FROM extracted_entities WHERE id = #{id}")
    @Results(id = "ExtractedEntityResult", value = {
        @Result(property = "id", column = "id"),
        @Result(property = "captureId", column = "capture_id"),
        @Result(property = "entityType", column = "entity_type"),
        @Result(property = "title", column = "title"),
        @Result(property = "description", column = "description"),
        @Result(property = "externalUrl", column = "external_url"),
        @Result(property = "actionCta", column = "action_cta"),
        @Result(property = "metadata", column = "metadata", typeHandler = JsonbTypeHandler.class),
        @Result(property = "enrichmentStatus", column = "enrichment_status"),
        @Result(property = "retryCount", column = "retry_count"),
        @Result(property = "nextRetryAt", column = "next_retry_at"),
        @Result(property = "enrichmentError", column = "enrichment_error"),
        @Result(property = "createdAt", column = "created_at")
    })
    Optional<ExtractedEntity> findById(@Param("id") UUID id);

    @Select("SELECT * FROM extracted_entities WHERE capture_id = #{captureId} ORDER BY created_at ASC")
    @ResultMap("ExtractedEntityResult")
    List<ExtractedEntity> findByCaptureId(@Param("captureId") UUID captureId);

    @Select("""
        SELECT * FROM extracted_entities
        WHERE enrichment_status = 'PENDING'
          AND next_retry_at <= CURRENT_TIMESTAMP
        ORDER BY created_at ASC
        LIMIT #{limit}
        FOR UPDATE SKIP LOCKED
    """)
    @ResultMap("ExtractedEntityResult")
    List<ExtractedEntity> fetchPendingForEnrichment(@Param("limit") int limit);

    @Insert("""
        INSERT INTO extracted_entities (
            id, capture_id, entity_type, title, description, external_url, action_cta, 
            metadata, enrichment_status, retry_count, next_retry_at, enrichment_error, created_at
        )
        VALUES (
            COALESCE(#{id}, gen_random_uuid()),
            #{captureId},
            #{entityType},
            #{title},
            #{description},
            #{externalUrl},
            #{actionCta},
            #{metadata, typeHandler=com.latyr.api.config.typehandler.JsonbTypeHandler, jdbcType=OTHER},
            COALESCE(#{enrichmentStatus}, 'PENDING'),
            COALESCE(#{retryCount}, 0),
            COALESCE(#{nextRetryAt}, CURRENT_TIMESTAMP),
            #{enrichmentError},
            COALESCE(#{createdAt}, CURRENT_TIMESTAMP)
        )
    """)
    int insert(ExtractedEntity entity);

    @Update("""
        UPDATE extracted_entities
        SET entity_type = #{entityType},
            title = #{title},
            description = #{description},
            external_url = #{externalUrl},
            action_cta = #{actionCta},
            metadata = #{metadata, typeHandler=com.latyr.api.config.typehandler.JsonbTypeHandler, jdbcType=OTHER},
            enrichment_status = #{enrichmentStatus},
            retry_count = #{retryCount},
            next_retry_at = #{nextRetryAt},
            enrichment_error = #{enrichmentError}
        WHERE id = #{id}
    """)
    int update(ExtractedEntity entity);

    @Delete("DELETE FROM extracted_entities WHERE id = #{id}")
    int deleteById(@Param("id") UUID id);

    @Delete("DELETE FROM extracted_entities WHERE capture_id = #{captureId}")
    int deleteByCaptureId(@Param("captureId") UUID captureId);
}
