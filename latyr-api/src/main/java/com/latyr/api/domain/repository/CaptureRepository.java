package com.latyr.api.domain.repository;

import com.latyr.api.domain.entity.Capture;
import com.latyr.api.domain.enums.CaptureStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CaptureRepository extends JpaRepository<Capture, UUID> {
    Page<Capture> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);
    Page<Capture> findByUserIdAndStatusOrderByCreatedAtDesc(UUID userId, CaptureStatus status, Pageable pageable);
    Page<Capture> findByUserIdAndCategoryOrderByCreatedAtDesc(UUID userId, String category, Pageable pageable);
    Optional<Capture> findByIdAndUserId(UUID id, UUID userId);
}
