package com.latyr.api.mapper;

import com.latyr.api.config.typehandler.JsonbTypeHandler;
import com.latyr.api.domain.model.IngestionOutboxEvent;
import org.apache.ibatis.annotations.*;

import java.util.Optional;

@Mapper
public interface IngestionOutboxMapper {
    @Insert("""
        INSERT INTO ingestion_event_outbox(id,user_id,event_type,payload)
        VALUES(#{id},#{userId},#{eventType},#{payload,typeHandler=com.latyr.api.config.typehandler.JsonbTypeHandler,jdbcType=OTHER})
        """)
    int insert(IngestionOutboxEvent event);

    @Select(value="""
        UPDATE ingestion_event_outbox SET status=CASE WHEN attempt_count>=10 THEN 'FAILED' ELSE 'DELIVERING' END,lease_token=gen_random_uuid(),
          lease_expires_at=clock_timestamp()+INTERVAL '30 seconds',attempt_count=attempt_count+1
        WHERE id=(SELECT id FROM ingestion_event_outbox
          WHERE (status='PENDING' AND next_attempt_at<=clock_timestamp())
            OR (status='DELIVERING' AND lease_expires_at<=clock_timestamp())
          ORDER BY created_at,id LIMIT 1 FOR UPDATE SKIP LOCKED)
        RETURNING *
        """, affectData=true)
    @Options(flushCache=Options.FlushCachePolicy.TRUE, useCache=false)
    @Results({@Result(property="id",column="id"),@Result(property="userId",column="user_id"),
        @Result(property="eventType",column="event_type"),@Result(property="leaseToken",column="lease_token"),
        @Result(property="attemptCount",column="attempt_count"),
        @Result(property="payload",column="payload",typeHandler=JsonbTypeHandler.class)})
    Optional<IngestionOutboxEvent> claim();

    @Update("""
        UPDATE ingestion_event_outbox SET status='DELIVERED',delivered_at=clock_timestamp(),
          lease_token=NULL,lease_expires_at=NULL
        WHERE id=#{id} AND lease_token=#{leaseToken} AND status='DELIVERING' AND lease_expires_at>clock_timestamp()
        """)
    int delivered(IngestionOutboxEvent event);

    @Update("""
        UPDATE ingestion_event_outbox SET status=CASE WHEN attempt_count>=10 THEN 'FAILED' ELSE 'PENDING' END,
          next_attempt_at=clock_timestamp()+make_interval(secs=>LEAST(300,5*attempt_count)),
          lease_token=NULL,lease_expires_at=NULL
        WHERE id=#{id} AND lease_token=#{leaseToken} AND status='DELIVERING' AND lease_expires_at>clock_timestamp()
        """)
    int retry(IngestionOutboxEvent event);
}
