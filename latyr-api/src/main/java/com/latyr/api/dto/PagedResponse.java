package com.latyr.api.dto;

import java.util.List;

public record PagedResponse<T>(
        List<T> items,
        PageMetadata pageable
) {
    public record PageMetadata(
            int pageNumber,
            int pageSize,
            long totalElements,
            int totalPages
    ) {}

    public static <T> PagedResponse<T> of(List<T> items, int pageNumber, int pageSize, long totalElements) {
        int totalPages = (int) Math.ceil((double) totalElements / (pageSize > 0 ? pageSize : 1));
        return new PagedResponse<>(items, new PageMetadata(pageNumber, pageSize, totalElements, totalPages));
    }
}
