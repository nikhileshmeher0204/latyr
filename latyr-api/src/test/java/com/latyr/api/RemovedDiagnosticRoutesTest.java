package com.latyr.api;

import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.ClassPathScanningCandidateComponentProvider;
import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.core.type.filter.AnnotationTypeFilter;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertFalse;

class RemovedDiagnosticRoutesTest {

    @Test
    void authAndDirectAiDiagnosticRoutesAreNotRegisteredByAnyController() throws Exception {
        Set<String> removedPrefixes = Set.of("/api/v1/auth", "/api/v1/ai");
        var scanner = new ClassPathScanningCandidateComponentProvider(false);
        scanner.addIncludeFilter(new AnnotationTypeFilter(Controller.class));

        for (var candidate : scanner.findCandidateComponents("com.latyr.api.controller")) {
            Class<?> controller = Class.forName(candidate.getBeanClassName());
            RequestMapping root = AnnotatedElementUtils.findMergedAnnotation(controller, RequestMapping.class);
            for (var method : controller.getDeclaredMethods()) {
                RequestMapping mapping = AnnotatedElementUtils.findMergedAnnotation(method, RequestMapping.class);
                if (mapping == null) {
                    continue;
                }
                for (String prefix : paths(root)) {
                    for (String path : paths(mapping)) {
                        String route = (prefix + "/" + path).replaceAll("/+", "/");
                        assertFalse(removedPrefixes.stream()
                                        .anyMatch(removed -> route.equals(removed) || route.startsWith(removed + "/")),
                                () -> "Removed diagnostic route is exposed by " + method + ": " + route);
                    }
                }
            }
        }
    }

    private static String[] paths(RequestMapping mapping) {
        return mapping == null || mapping.path().length == 0 ? new String[]{""} : mapping.path();
    }
}
