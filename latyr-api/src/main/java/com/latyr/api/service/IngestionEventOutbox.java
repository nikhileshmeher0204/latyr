package com.latyr.api.service;

import com.latyr.api.domain.model.IngestionOutboxEvent;
import com.latyr.api.mapper.IngestionOutboxMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class IngestionEventOutbox {
    private final IngestionOutboxMapper mapper;

    public IngestionEventOutbox(IngestionOutboxMapper mapper) { this.mapper = mapper; }

    @Transactional(propagation=Propagation.MANDATORY)
    public UUID append(UUID userId, String type, Map<String,Object> payload) {
        UUID id = UUID.randomUUID();
        Map<String,Object> body = new HashMap<>(payload);
        body.put("event_id", id.toString());
        IngestionOutboxEvent event = new IngestionOutboxEvent();
        event.setId(id);
        event.setUserId(userId);
        event.setEventType(type);
        event.setPayload(body);
        mapper.insert(event);
        return id;
    }
}
