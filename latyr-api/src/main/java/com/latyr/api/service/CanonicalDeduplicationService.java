package com.latyr.api.service;

import com.latyr.api.domain.enums.SourceType;
import com.latyr.api.domain.model.CanonicalSource;
import com.latyr.api.mapper.CanonicalSourceMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.HashMap;
import java.util.Optional;
import java.util.UUID;

@Service
public class CanonicalDeduplicationService {

    private static final Logger log = LoggerFactory.getLogger(CanonicalDeduplicationService.class);

    private final CanonicalSourceMapper canonicalSourceMapper;

    public CanonicalDeduplicationService(CanonicalSourceMapper canonicalSourceMapper) {
        this.canonicalSourceMapper = canonicalSourceMapper;
    }

    public Optional<CanonicalSource> findCachedSource(String canonicalHash) {
        Optional<CanonicalSource> sourceOpt = canonicalSourceMapper.findByCanonicalUrlHash(canonicalHash);
        if (sourceOpt.isEmpty()) {
            return Optional.empty();
        }

        CanonicalSource source = sourceOpt.get();
        // Successful core analysis is immutable and has no automatic expiry.
        if (!CaptureSuccessPolicy.isUsefulCache(source.getAiAnalysisCache())) {
            return Optional.empty();
        }

        log.info("Cache HIT for canonical hash: {}", canonicalHash);
        return Optional.of(source);
    }

    @Transactional
    public CanonicalSource getOrCreateCanonicalSource(String canonicalHash, SourceType sourceType, String originalUrl) {
        Optional<CanonicalSource> existing = canonicalSourceMapper.findByCanonicalUrlHash(canonicalHash);
        if (existing.isPresent()) {
            return existing.get();
        }

        CanonicalSource source = new CanonicalSource();
        source.setId(UUID.randomUUID());
        source.setCanonicalUrlHash(canonicalHash);
        source.setSourceType(sourceType);
        source.setOriginalUrl(originalUrl);
        source.setRawMetadata(new HashMap<>());
        source.setAiAnalysisCache(new HashMap<>());
        source.setCreatedAt(Instant.now());
        source.setUpdatedAt(Instant.now());

        int rows = canonicalSourceMapper.insert(source);
        if (rows == 0) {
            log.info("Concurrent insert collision for canonical hash {}. Re-fetching existing record.", canonicalHash);
            return canonicalSourceMapper.findByCanonicalUrlHash(canonicalHash)
                    .orElseThrow(() -> new IllegalStateException("Canonical source expected to exist for hash: " + canonicalHash));
        }
        log.info("Created new canonical source {} with hash {}", source.getId(), canonicalHash);
        return source;
    }
}
