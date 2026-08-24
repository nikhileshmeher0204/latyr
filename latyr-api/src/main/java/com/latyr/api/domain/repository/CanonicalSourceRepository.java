package com.latyr.api.domain.repository;

import com.latyr.api.domain.entity.CanonicalSource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CanonicalSourceRepository extends JpaRepository<CanonicalSource, UUID> {
    Optional<CanonicalSource> findByCanonicalUrlHash(String canonicalUrlHash);
    boolean existsByCanonicalUrlHash(String canonicalUrlHash);
}
