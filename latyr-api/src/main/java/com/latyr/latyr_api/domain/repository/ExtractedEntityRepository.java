package com.latyr.latyr_api.domain.repository;

import com.latyr.latyr_api.domain.entity.ExtractedEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ExtractedEntityRepository extends JpaRepository<ExtractedEntity, UUID> {
    List<ExtractedEntity> findByCaptureId(UUID captureId);
    Optional<ExtractedEntity> findByIdAndCaptureUserId(UUID id, UUID userId);
}
