package com.latyr.api.mapper;

import com.latyr.api.domain.model.CaptureCollection;
import org.apache.ibatis.annotations.*;

import java.util.List;
import java.util.UUID;

@Mapper
public interface CaptureCollectionMapper {

    @Select("SELECT * FROM capture_collections WHERE capture_id = #{captureId}")
    List<CaptureCollection> findByCaptureId(@Param("captureId") UUID captureId);

    @Select("SELECT * FROM capture_collections WHERE user_collection_id = #{userCollectionId}")
    List<CaptureCollection> findByUserCollectionId(@Param("userCollectionId") UUID userCollectionId);

    @Select("SELECT EXISTS(SELECT 1 FROM capture_collections WHERE capture_id = #{captureId} AND user_collection_id = #{userCollectionId})")
    boolean exists(@Param("captureId") UUID captureId, @Param("userCollectionId") UUID userCollectionId);

    @Insert("""
        INSERT INTO capture_collections (capture_id, user_collection_id, added_at)
        VALUES (#{captureId}, #{userCollectionId}, COALESCE(#{addedAt}, CURRENT_TIMESTAMP))
        ON CONFLICT DO NOTHING
    """)
    int insert(CaptureCollection captureCollection);

    @Delete("DELETE FROM capture_collections WHERE capture_id = #{captureId} AND user_collection_id = #{userCollectionId}")
    int delete(@Param("captureId") UUID captureId, @Param("userCollectionId") UUID userCollectionId);

    @Delete("DELETE FROM capture_collections WHERE capture_id = #{captureId}")
    int deleteByCaptureId(@Param("captureId") UUID captureId);
}
