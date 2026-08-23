package com.latyr.latyr_api.domain.repository;

import com.latyr.latyr_api.domain.entity.UserCollection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserCollectionRepository extends JpaRepository<UserCollection, UUID> {
    List<UserCollection> findByUserIdOrderByCreatedAtDesc(UUID userId);
    Optional<UserCollection> findByUserIdAndName(UUID userId, String name);
}
