package com.latyr.api.domain.model;

import java.time.Instant;
import java.util.UUID;

public class Collection {

    private UUID id;
    private String code;
    private String name;
    private String category;
    private String defaultIcon;
    private String featureTriggers;
    private Instant createdAt = Instant.now();

    public Collection() {}

    public Collection(String code, String name, String category, String defaultIcon, String featureTriggers) {
        this.code = code;
        this.name = name;
        this.category = category;
        this.defaultIcon = defaultIcon;
        this.featureTriggers = featureTriggers;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getDefaultIcon() { return defaultIcon; }
    public void setDefaultIcon(String defaultIcon) { this.defaultIcon = defaultIcon; }

    public String getFeatureTriggers() { return featureTriggers; }
    public void setFeatureTriggers(String featureTriggers) { this.featureTriggers = featureTriggers; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
