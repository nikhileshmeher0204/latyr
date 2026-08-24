package com.latyr.api.mapper;

import com.latyr.api.domain.model.UserSubscriptionHistory;
import org.apache.ibatis.annotations.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Mapper
public interface UserSubscriptionHistoryMapper {

    @Select("SELECT * FROM user_subscription_history WHERE id = #{id}")
    Optional<UserSubscriptionHistory> findById(@Param("id") UUID id);

    @Select("SELECT * FROM user_subscription_history WHERE user_id = #{userId} ORDER BY event_timestamp DESC")
    List<UserSubscriptionHistory> findByUserId(@Param("userId") UUID userId);

    @Insert("""
        INSERT INTO user_subscription_history (id, user_id, from_tier, to_tier, event_type, amount_paid, currency, provider_transaction_id, event_timestamp)
        VALUES (COALESCE(#{id}, gen_random_uuid()), #{userId}, #{fromTier}, #{toTier}, #{eventType}, #{amountPaid}, #{currency}, #{providerTransactionId}, COALESCE(#{eventTimestamp}, CURRENT_TIMESTAMP))
    """)
    int insert(UserSubscriptionHistory history);
}
