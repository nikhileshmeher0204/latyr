package com.latyr.api.adapter;

import java.util.List;

public interface EntityEnrichmentProvider {

    List<AIProvider.AIEntity> enrichEntities(List<AIProvider.AIEntity> entities);
}
