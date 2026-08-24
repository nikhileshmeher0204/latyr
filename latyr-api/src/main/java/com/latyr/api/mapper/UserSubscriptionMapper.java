package com.latyr.api.mapper;

import com.latyr.api.domain.model.UserSubscription;
import org.apache.ibatis.annotations.*;

import java.util.Optional;
import java.util.UUID;

@Mapper
public interface UserSubscriptionMapper {

    @Select("SELECT * FROM user_subscriptions WHERE id = #{id}")
    Optional<UserSubscription> findById(@Param("id") UUID id);

    @Select("SELECT * FROM user_subscriptions WHERE user_id = #{userId}")
    Optional<UserSubscription> findByUserId(@Param("userId") UUID userId);

    @Insert("""
        INSERT INTO user_subscriptions (id, user_id, plan_tier, monthly_capture_count, quota_limit, quota_reset_at, expires_at, created_at, updated_at)
        VALUES (COALESCE(#{id}, gen_random_uuid()), #{userId}, #{planTier}, #{monthlyCaptureCount}, #{quotaLimit}, #{quotaResetAt}, #{expiresAt}, COALESCE(#{createdAt}, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP)
    """)
    int insert(UserSubscription subscription);

    @Update("""
        UPDATE user_subscriptions
        SET plan_tier = #{planTier},
            monthly_capture_count = #{monthlyCaptureCount},
            quota_limit = #{quotaLimit},
            quota_reset_at = #{quotaResetAt},
            expires_at = #{expiresAt},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = #{id}
    """)
    int update(UserSubscription subscription);

    @Update("""
        UPDATE user_subscriptions
        SET monthly_capture_count = monthly_capture_count + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = #{userId} AND monthly_capture_count < quota_limit
    """)
    int incrementMonthlyCaptureCountIfWithinQuota(@Param("userId") UUID userId);

    @Delete("DELETE FROM user_subscriptions WHERE user_id = #{userId}")
    int deleteByUserId(@Param("userId") UUID userId);
}
