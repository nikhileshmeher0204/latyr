package com.latyr.api;

import com.latyr.api.domain.model.CanonicalSource;
import com.latyr.api.mapper.CanonicalSourceMapper;
import com.latyr.api.service.CanonicalDeduplicationService;
import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class CanonicalDeduplicationServiceTest {
    @Test
    void successfulSourceAnalysisRemainsReusableAfterThirtyDays() {
        CanonicalSourceMapper mapper = mock(CanonicalSourceMapper.class);
        CanonicalSource source = new CanonicalSource();
        source.setId(UUID.randomUUID());
        source.setUpdatedAt(Instant.now().minus(365, ChronoUnit.DAYS));
        source.setAiAnalysisCache(Map.of("intent", "WATCH", "entities",
                List.of(Map.of("title", "Dark", "entity_type", "TV_SHOW", "action_cta", "WATCH"))));
        when(mapper.findByCanonicalUrlHash("hash")).thenReturn(Optional.of(source));
        assertEquals(Optional.of(source), new CanonicalDeduplicationService(mapper).findCachedSource("hash"));
        verify(mapper, never()).update(any());
    }

    @Test
    void summaryOnlyCacheDoesNotBecomeSuccessfulSharedAnalysis() {
        CanonicalSourceMapper mapper = mock(CanonicalSourceMapper.class);
        CanonicalSource source = new CanonicalSource();
        source.setAiAnalysisCache(Map.of("summary", "Summary alone", "intent", "REMEMBER"));
        when(mapper.findByCanonicalUrlHash("hash")).thenReturn(Optional.of(source));
        assertTrue(new CanonicalDeduplicationService(mapper).findCachedSource("hash").isEmpty());
    }
}
