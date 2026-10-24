package com.latyr.api.mapper;

import com.latyr.api.config.typehandler.JsonbTypeHandler;
import com.latyr.api.domain.model.IngestionJob;
import com.latyr.api.domain.model.IngestionStageCheckpoint;
import org.apache.ibatis.annotations.*;

import java.util.Map;
import java.util.Optional;

@Mapper
public interface IngestionStageMapper {
    @Select("SELECT status, lease_token, output FROM ingestion_stage_checkpoints WHERE canonical_source_id = #{job.canonicalSourceId} AND stage = #{stage}")
    @Results({@Result(property="status",column="status"), @Result(property="leaseToken",column="lease_token"),
        @Result(property="output",column="output",typeHandler=JsonbTypeHandler.class)})
    Optional<IngestionStageCheckpoint> find(@Param("job") IngestionJob job, @Param("stage") String stage);

    @Insert("""
        INSERT INTO ingestion_stage_checkpoints(canonical_source_id,stage,status,job_id,lease_token)
        VALUES(#{job.canonicalSourceId},#{stage},'RUNNING',#{job.id},#{job.leaseToken})
        ON CONFLICT(canonical_source_id,stage) DO UPDATE SET status='RUNNING',job_id=EXCLUDED.job_id,
          lease_token=EXCLUDED.lease_token,output=NULL,error_code=NULL,started_at=clock_timestamp(),completed_at=NULL
        WHERE ingestion_stage_checkpoints.status <> 'COMPLETED' OR EXCLUDED.stage = 'MEDIA'
        """)
    int start(@Param("job") IngestionJob job, @Param("stage") String stage);

    @Insert("""
        INSERT INTO ingestion_stage_attempts(canonical_source_id,job_id,lease_token,stage,status)
        VALUES(#{job.canonicalSourceId},#{job.id},#{job.leaseToken},#{stage},'RUNNING')
        """)
    int startAttempt(@Param("job") IngestionJob job, @Param("stage") String stage);

    @Update("""
        UPDATE ingestion_stage_checkpoints SET status=#{status},
          output=#{output,typeHandler=com.latyr.api.config.typehandler.JsonbTypeHandler,jdbcType=OTHER},
          error_code=#{errorCode},completed_at=clock_timestamp()
        WHERE canonical_source_id=#{job.canonicalSourceId} AND stage=#{stage}
          AND lease_token=#{job.leaseToken} AND status='RUNNING'
        """)
    int end(@Param("job") IngestionJob job, @Param("stage") String stage, @Param("status") String status,
        @Param("output") Map<String,Object> output, @Param("errorCode") String errorCode);

    @Update("""
        UPDATE ingestion_stage_attempts SET status=#{status},error_code=#{errorCode},completed_at=clock_timestamp()
        WHERE job_id=#{job.id} AND lease_token=#{job.leaseToken} AND stage=#{stage} AND status='RUNNING'
        """)
    int endAttempt(@Param("job") IngestionJob job, @Param("stage") String stage,
        @Param("status") String status, @Param("errorCode") String errorCode);

    @Update("""
        UPDATE ingestion_stage_attempts SET status=CASE WHEN stage='ANALYSIS' THEN 'AMBIGUOUS' ELSE 'EXPIRED' END,
          error_code='LEASE_EXPIRED',completed_at=clock_timestamp()
        WHERE canonical_source_id=#{canonicalSourceId} AND status='RUNNING'
        """)
    int expireAttempts(IngestionJob job);

    @Update("""
        UPDATE ingestion_stage_checkpoints SET status=CASE WHEN stage='ANALYSIS' THEN 'AMBIGUOUS' ELSE 'FAILED' END,
          error_code='LEASE_EXPIRED',completed_at=clock_timestamp()
        WHERE canonical_source_id=#{canonicalSourceId} AND status='RUNNING'
        """)
    int expireCheckpoints(IngestionJob job);
}
