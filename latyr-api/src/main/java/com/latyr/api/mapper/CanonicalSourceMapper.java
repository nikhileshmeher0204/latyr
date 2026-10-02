package com.latyr.api.mapper;

import com.latyr.api.config.typehandler.JsonbTypeHandler;
import com.latyr.api.domain.model.CanonicalSource;
import org.apache.ibatis.annotations.*;
import org.apache.ibatis.type.JdbcType;

import java.util.Optional;
import java.util.UUID;

@Mapper
public interface CanonicalSourceMapper {

    @Select("SELECT * FROM canonical_sources WHERE id = #{id}")
    @Results(id = "CanonicalSourceResult", value = {
        @Result(property = "id", column = "id"),
        @Result(property = "canonicalUrlHash", column = "canonical_url_hash"),
        @Result(property = "sourceType", column = "source_type"),
        @Result(property = "originalUrl", column = "original_url"),
        @Result(property = "thumbnailUrl", column = "thumbnail_url"),
        @Result(property = "rawMetadata", column = "raw_metadata", typeHandler = JsonbTypeHandler.class),
        @Result(property = "aiAnalysisCache", column = "ai_analysis_cache", typeHandler = JsonbTypeHandler.class),
        @Result(property = "createdAt", column = "created_at"),
        @Result(property = "updatedAt", column = "updated_at")
    })
    Optional<CanonicalSource> findById(@Param("id") UUID id);

    @Select("SELECT * FROM canonical_sources WHERE canonical_url_hash = #{canonicalUrlHash}")
    @ResultMap("CanonicalSourceResult")
    Optional<CanonicalSource> findByCanonicalUrlHash(@Param("canonicalUrlHash") String canonicalUrlHash);

    @Select("SELECT EXISTS(SELECT 1 FROM canonical_sources WHERE canonical_url_hash = #{canonicalUrlHash})")
    boolean existsByCanonicalUrlHash(@Param("canonicalUrlHash") String canonicalUrlHash);

    @Insert("""
        INSERT INTO canonical_sources (id, canonical_url_hash, source_type, original_url, thumbnail_url, raw_metadata, ai_analysis_cache, created_at, updated_at)
        VALUES (
            COALESCE(#{id}, gen_random_uuid()),
            #{canonicalUrlHash},
            #{sourceType},
            #{originalUrl},
            #{thumbnailUrl},
            #{rawMetadata, typeHandler=com.latyr.api.config.typehandler.JsonbTypeHandler, jdbcType=OTHER},
            #{aiAnalysisCache, typeHandler=com.latyr.api.config.typehandler.JsonbTypeHandler, jdbcType=OTHER},
            COALESCE(#{createdAt}, CURRENT_TIMESTAMP),
            CURRENT_TIMESTAMP
        )
    """)
    int insert(CanonicalSource source);

    @Update("""
        UPDATE canonical_sources
        SET thumbnail_url = #{thumbnailUrl},
            raw_metadata = #{rawMetadata, typeHandler=com.latyr.api.config.typehandler.JsonbTypeHandler, jdbcType=OTHER},
            ai_analysis_cache = #{aiAnalysisCache, typeHandler=com.latyr.api.config.typehandler.JsonbTypeHandler, jdbcType=OTHER},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = #{id}
    """)
    int update(CanonicalSource source);

    @Delete("DELETE FROM canonical_sources WHERE id = #{id}")
    int deleteById(@Param("id") UUID id);
}
