package com.latyr.api.domain.repository;

import com.latyr.api.domain.entity.CaptureCollection;
import com.latyr.api.domain.entity.CaptureCollectionId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CaptureCollectionRepository extends JpaRepository<CaptureCollection, CaptureCollectionId> {
    List<CaptureCollection> findByCaptureId(UUID captureId);
    List<CaptureCollection> findByUserCollectionId(UUID userCollectionId);
    void deleteByCaptureIdAndUserCollectionId(UUID captureId, UUID userCollectionId);
}
