package com.latyr.api.mapper;

import com.latyr.api.domain.model.CaptureQuotaReservation;
import org.apache.ibatis.annotations.*;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Mapper
public interface CaptureQuotaLedgerMapper {
    @Select("SELECT * FROM capture_quota_ledger WHERE user_id=#{userId} AND canonical_source_id=#{sourceId}")
    Optional<CaptureQuotaReservation> find(@Param("userId") UUID userId, @Param("sourceId") UUID sourceId);

    @Select("SELECT * FROM capture_quota_ledger WHERE capture_id=#{captureId}")
    Optional<CaptureQuotaReservation> findByCaptureId(@Param("captureId") UUID captureId);

    @Select("SELECT count(*) FROM capture_quota_ledger WHERE user_id=#{userId} AND state='RESERVED' AND NOT grandfathered")
    long countReservations(@Param("userId") UUID userId);

    @Insert("""
        INSERT INTO capture_quota_ledger(user_id, canonical_source_id, capture_id, state, quota_cycle_end)
        VALUES(#{userId}, #{sourceId}, #{captureId}, 'RESERVED', #{cycleEnd})
        ON CONFLICT(user_id,canonical_source_id) DO UPDATE
        SET capture_id=EXCLUDED.capture_id, state='RESERVED', grandfathered=FALSE,
            quota_cycle_end=EXCLUDED.quota_cycle_end, updated_at=CURRENT_TIMESTAMP
        WHERE capture_quota_ledger.state='RELEASED'
        """)
    int reserve(@Param("userId") UUID userId, @Param("sourceId") UUID sourceId,
                @Param("captureId") UUID captureId, @Param("cycleEnd") Instant cycleEnd);

    @Update("""
        UPDATE capture_quota_ledger SET capture_id=#{captureId}, updated_at=CURRENT_TIMESTAMP
        WHERE user_id=#{userId} AND canonical_source_id=#{sourceId} AND state='FINALIZED'
        """)
    int attachFinalized(@Param("userId") UUID userId, @Param("sourceId") UUID sourceId, @Param("captureId") UUID captureId);

    @Update("""
        UPDATE capture_quota_ledger SET state=#{state}, quota_cycle_end=#{cycleEnd}, updated_at=CURRENT_TIMESTAMP
        WHERE capture_id=#{captureId} AND state='RESERVED'
        """)
    int transition(@Param("captureId") UUID captureId, @Param("state") String state, @Param("cycleEnd") Instant cycleEnd);
}
