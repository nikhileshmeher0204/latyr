package com.latyr.api.dto;

import java.util.List;

public record TaxonomyResponse(
        List<TaxonomyCategoryDto> categories
) {}
