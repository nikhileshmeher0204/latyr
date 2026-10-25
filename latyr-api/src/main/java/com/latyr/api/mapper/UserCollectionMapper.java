package com.latyr.api.mapper;

import com.latyr.api.config.typehandler.StringArrayTypeHandler;
import com.latyr.api.domain.model.UserCollection;
import org.apache.ibatis.annotations.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Mapper
public interface UserCollectionMapper {

    @Select("SELECT * FROM user_collections WHERE id = #{id}")
    Optional<UserCollection> findById(@Param("id") UUID id);

    @Select("SELECT * FROM user_collections WHERE id = #{id} AND user_id = #{userId}")
    Optional<UserCollection> findByIdAndUserId(@Param("id") UUID id, @Param("userId") UUID userId);

    @Select("SELECT * FROM user_collections WHERE user_id = #{userId} ORDER BY is_pinned DESC, name ASC")
    List<UserCollection> findByUserId(@Param("userId") UUID userId);

    @Select("SELECT * FROM user_collections WHERE user_id = #{userId} AND collection_id = #{collectionId}")
    Optional<UserCollection> findByUserIdAndCollectionId(@Param("userId") UUID userId, @Param("collectionId") UUID collectionId);

    @Select("""
        SELECT 
            uc.id,
            uc.user_id,
            uc.collection_id,
            uc.name,
            uc.category,
            uc.description,
            COALESCE(uc.icon, 'folder_fill') AS icon,
            COALESCE(uc.color_hex, '#28543A') AS color_hex,
            uc.is_pinned,
            uc.created_at,
            uc.updated_at,
            COUNT(uce.entity_id)::int AS item_count,
            COALESCE(
                (ARRAY_AGG(
                    COALESCE(
                        ee.metadata ->> 'poster_url',
                        ee.metadata ->> 'owner_avatar_url',
                        ee.metadata ->> 'thumbnail_url',
                        ee.metadata ->> 'image_url',
                        c.thumbnail_url
                    )
                    ORDER BY uce.item_order ASC, uce.added_at DESC
                ) FILTER (WHERE ee.id IS NOT NULL AND COALESCE(ee.metadata ->> 'poster_url', ee.metadata ->> 'owner_avatar_url', ee.metadata ->> 'thumbnail_url', ee.metadata ->> 'image_url', c.thumbnail_url) IS NOT NULL))[1:3],
                '{}'::text[]
            ) AS preview_artwork_urls
        FROM user_collections uc
        LEFT JOIN user_collection_entities uce ON uc.id = uce.user_collection_id
        LEFT JOIN extracted_entities ee ON uce.entity_id = ee.id
        LEFT JOIN captures c ON ee.capture_id = c.id
        WHERE uc.user_id = #{userId}
        GROUP BY uc.id
        ORDER BY uc.is_pinned DESC, uc.updated_at DESC, uc.created_at DESC
    """)
    @Results(id = "UserCollectionSummaryResult", value = {
        @Result(property = "id", column = "id"),
        @Result(property = "userId", column = "user_id"),
        @Result(property = "collectionId", column = "collection_id"),
        @Result(property = "name", column = "name"),
        @Result(property = "category", column = "category"),
        @Result(property = "description", column = "description"),
        @Result(property = "icon", column = "icon"),
        @Result(property = "colorHex", column = "color_hex"),
        @Result(property = "isPinned", column = "is_pinned"),
        @Result(property = "createdAt", column = "created_at"),
        @Result(property = "updatedAt", column = "updated_at"),
        @Result(property = "itemCount", column = "item_count"),
        @Result(property = "previewArtworkUrls", column = "preview_artwork_urls", typeHandler = StringArrayTypeHandler.class)
    })
    List<UserCollection> findSummariesByUserId(@Param("userId") UUID userId);

    @Select("""
        SELECT 
            uc.id,
            uc.user_id,
            uc.collection_id,
            uc.name,
            uc.category,
            uc.description,
            COALESCE(uc.icon, 'folder_fill') AS icon,
            COALESCE(uc.color_hex, '#28543A') AS color_hex,
            uc.is_pinned,
            uc.created_at,
            uc.updated_at,
            COUNT(uce.entity_id)::int AS item_count,
            COALESCE(
                (ARRAY_AGG(
                    COALESCE(
                        ee.metadata ->> 'poster_url',
                        ee.metadata ->> 'owner_avatar_url',
                        ee.metadata ->> 'thumbnail_url',
                        ee.metadata ->> 'image_url',
                        c.thumbnail_url
                    )
                    ORDER BY uce.item_order ASC, uce.added_at DESC
                ) FILTER (WHERE ee.id IS NOT NULL AND COALESCE(ee.metadata ->> 'poster_url', ee.metadata ->> 'owner_avatar_url', ee.metadata ->> 'thumbnail_url', ee.metadata ->> 'image_url', c.thumbnail_url) IS NOT NULL))[1:3],
                '{}'::text[]
            ) AS preview_artwork_urls
        FROM user_collections uc
        LEFT JOIN user_collection_entities uce ON uc.id = uce.user_collection_id
        LEFT JOIN extracted_entities ee ON uce.entity_id = ee.id
        LEFT JOIN captures c ON ee.capture_id = c.id
        WHERE uc.id = #{id} AND uc.user_id = #{userId}
        GROUP BY uc.id
    """)
    @ResultMap("UserCollectionSummaryResult")
    Optional<UserCollection> findSummaryByIdAndUserId(@Param("id") UUID id, @Param("userId") UUID userId);

    @Insert("""
        INSERT INTO user_collections (
            id, user_id, collection_id, name, category, description, icon, color_hex, is_pinned, created_at, updated_at
        )
        VALUES (
            COALESCE(#{id}, gen_random_uuid()),
            #{userId},
            #{collectionId},
            #{name},
            #{category},
            #{description},
            COALESCE(#{icon}, 'folder_fill'),
            COALESCE(#{colorHex}, '#28543A'),
            #{isPinned},
            COALESCE(#{createdAt}, CURRENT_TIMESTAMP),
            CURRENT_TIMESTAMP
        )
    """)
    int insert(UserCollection userCollection);

    @Update("""
        UPDATE user_collections
        SET name = #{name},
            category = #{category},
            description = #{description},
            icon = COALESCE(#{icon}, icon),
            color_hex = COALESCE(#{colorHex}, color_hex),
            is_pinned = #{isPinned},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = #{id}
    """)
    int update(UserCollection userCollection);

    @Delete("DELETE FROM user_collections WHERE id = #{id}")
    int deleteById(@Param("id") UUID id);

    @Delete("DELETE FROM user_collections WHERE id = #{id} AND user_id = #{userId}")
    int deleteByIdAndUserId(@Param("id") UUID id, @Param("userId") UUID userId);

    @Insert("""
        INSERT INTO user_collection_entities (user_collection_id, entity_id, item_order, added_at)
        VALUES (#{userCollectionId}, #{entityId}, #{itemOrder}, CURRENT_TIMESTAMP)
        ON CONFLICT (user_collection_id, entity_id) DO NOTHING
    """)
    int insertEntityAssociation(
            @Param("userCollectionId") UUID userCollectionId,
            @Param("entityId") UUID entityId,
            @Param("itemOrder") int itemOrder
    );

    @Delete("""
        DELETE FROM user_collection_entities
        WHERE user_collection_id = #{userCollectionId} AND entity_id = #{entityId}
    """)
    int deleteEntityAssociation(
            @Param("userCollectionId") UUID userCollectionId,
            @Param("entityId") UUID entityId
    );

    @Select("""
        SELECT uce.user_collection_id 
        FROM user_collection_entities uce
        JOIN user_collections uc ON uce.user_collection_id = uc.id
        WHERE uc.user_id = #{userId} AND uce.entity_id = #{entityId}
    """)
    List<UUID> findCollectionIdsForEntity(@Param("userId") UUID userId, @Param("entityId") UUID entityId);

    @Select("""
        SELECT COALESCE(MAX(item_order) + 1, 0)
        FROM user_collection_entities
        WHERE user_collection_id = #{userCollectionId}
    """)
    int getNextItemOrder(@Param("userCollectionId") UUID userCollectionId);

    @Select("SELECT COUNT(*) FROM user_collection_entities WHERE user_collection_id = #{userCollectionId}")
    int countEntitiesByCollectionId(@Param("userCollectionId") UUID userCollectionId);
}
