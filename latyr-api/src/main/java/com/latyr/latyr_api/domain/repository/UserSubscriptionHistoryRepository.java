package com.latyr.latyr_api.domain.repository;

import com.latyr.latyr_api.domain.entity.UserSubscriptionHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface UserSubscriptionHistoryRepository extends JpaRepository<UserSubscriptionHistory, UUID> {
    List<UserSubscriptionHistory> findByUserIdOrderByEventTimestampDesc(UUID userId);
}
