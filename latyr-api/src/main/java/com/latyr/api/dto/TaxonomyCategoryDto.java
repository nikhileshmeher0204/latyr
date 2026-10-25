package com.latyr.api.dto;

import java.util.List;

public record TaxonomyCategoryDto(
        String name,
        long count,
        List<TaxonomySubCategoryDto> subCategories
) {}
