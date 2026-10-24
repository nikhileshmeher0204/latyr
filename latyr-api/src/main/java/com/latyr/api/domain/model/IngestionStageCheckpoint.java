package com.latyr.api.domain.model;

import java.util.Map;
import java.util.UUID;

public class IngestionStageCheckpoint {
    private String status;
    private UUID leaseToken;
    private Map<String, Object> output;

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public UUID getLeaseToken() { return leaseToken; }
    public void setLeaseToken(UUID leaseToken) { this.leaseToken = leaseToken; }
    public Map<String, Object> getOutput() { return output; }
    public void setOutput(Map<String, Object> output) { this.output = output; }
}
