package com.latyr.api.mapper;

import com.latyr.api.domain.model.User;
import org.apache.ibatis.annotations.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Mapper
public interface UserMapper {

    @Select("SELECT * FROM users WHERE id = #{id}")
    Optional<User> findById(@Param("id") UUID id);

    @Select("SELECT * FROM users WHERE firebase_uid = #{firebaseUid}")
    Optional<User> findByFirebaseUid(@Param("firebaseUid") String firebaseUid);

    @Select("SELECT * FROM users WHERE email = #{email}")
    Optional<User> findByEmail(@Param("email") String email);

    @Select("SELECT * FROM users WHERE fcm_token IS NOT NULL AND fcm_token != ''")
    List<User> findAllUsersWithFcmToken();

    @Select("SELECT EXISTS(SELECT 1 FROM users WHERE firebase_uid = #{firebaseUid})")
    boolean existsByFirebaseUid(@Param("firebaseUid") String firebaseUid);

    @Insert("""
        INSERT INTO users (id, firebase_uid, email, display_name, photo_url, fcm_token, timezone, language, created_at, updated_at)
        VALUES (COALESCE(#{id}, gen_random_uuid()), #{firebaseUid}, #{email}, #{displayName}, #{photoUrl}, #{fcmToken}, #{timezone}, #{language}, COALESCE(#{createdAt}, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP)
    """)
    @Options(useGeneratedKeys = false)
    int insert(User user);

    @Update("""
        UPDATE users
        SET display_name = #{displayName},
            photo_url = #{photoUrl},
            fcm_token = #{fcmToken},
            timezone = #{timezone},
            language = #{language},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = #{id}
    """)
    int update(User user);

    @Delete("DELETE FROM users WHERE id = #{id}")
    int deleteById(@Param("id") UUID id);
}
