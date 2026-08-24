package com.latyr.api.mapper;

import com.latyr.api.domain.model.UserCollection;
import org.apache.ibatis.annotations.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Mapper
public interface UserCollectionMapper {

    @Select("SELECT * FROM user_collections WHERE id = #{id}")
    Optional<UserCollection> findById(@Param("id") UUID id);

    @Select("SELECT * FROM user_collections WHERE user_id = #{userId} ORDER BY is_pinned DESC, name ASC")
    List<UserCollection> findByUserId(@Param("userId") UUID userId);

    @Select("SELECT * FROM user_collections WHERE user_id = #{userId} AND collection_id = #{collectionId}")
    Optional<UserCollection> findByUserIdAndCollectionId(@Param("userId") UUID userId, @Param("collectionId") UUID collectionId);

    @Insert("""
        INSERT INTO user_collections (id, user_id, collection_id, name, category, is_pinned, created_at, updated_at)
        VALUES (COALESCE(#{id}, gen_random_uuid()), #{userId}, #{collectionId}, #{name}, #{category}, #{isPinned}, COALESCE(#{createdAt}, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP)
    """)
    int insert(UserCollection userCollection);

    @Update("""
        UPDATE user_collections
        SET name = #{name},
            category = #{category},
            is_pinned = #{isPinned},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = #{id}
    """)
    int update(UserCollection userCollection);

    @Delete("DELETE FROM user_collections WHERE id = #{id}")
    int deleteById(@Param("id") UUID id);
}
