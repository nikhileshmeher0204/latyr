package com.latyr.api;

import com.latyr.api.service.TaxonomyNormalizer;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class TaxonomyNormalizerTest {

    @Test
    @DisplayName("Entertainment sub-categories normalize to TV Series, Documentaries, or Movies")
    void testEntertainmentNormalization() {
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Entertainment", "Psychological Thriller Movies"))
                .isEqualTo("Movies");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Entertainment", "Netflix Series"))
                .isEqualTo("TV Series");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Entertainment", "Docuseries"))
                .isEqualTo("TV Series");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Entertainment", "Crime Documentary"))
                .isEqualTo("Documentaries");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Entertainment", "Sci-Fi, Mystery, Time Travel"))
                .isEqualTo("Movies");
    }

    @Test
    @DisplayName("Tech sub-categories normalize to AI Tools, Developer Tools, Cybersecurity, Cloud Architecture, Data & Analytics")
    void testTechNormalization() {
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Tech", "AI Agents & LLM Tools"))
                .isEqualTo("AI Tools");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Tech", "GitHub Open Source Repos"))
                .isEqualTo("Developer Tools");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Tech", "Cybersecurity Tools & Audit"))
                .isEqualTo("Cybersecurity");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Tech", "Cloud DevOps Infrastructure"))
                .isEqualTo("Cloud Architecture");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Tech", "Python Data Analytics"))
                .isEqualTo("Data & Analytics");
    }

    @Test
    @DisplayName("Learning sub-categories normalize to Career & Interviews, Certifications, Business Strategy")
    void testLearningNormalization() {
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Learning", "Job Interview Tips"))
                .isEqualTo("Career & Interviews");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Learning", "AWS Certifications"))
                .isEqualTo("Certifications");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Learning", "Entrepreneurship & Marketing Strategy"))
                .isEqualTo("Business Strategy");
    }

    @Test
    @DisplayName("Food sub-categories normalize to Recipes")
    void testFoodNormalization() {
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Food", "Shawarma Recipe"))
                .isEqualTo("Recipes");
        assertThat(TaxonomyNormalizer.normalizeSubCategory("Food", "Italian Pasta Dish"))
                .isEqualTo("Recipes");
    }

    @Test
    @DisplayName("Tag extraction extracts multi-label keywords from raw sub-category string and provided tags")
    void testTagExtraction() {
        List<String> tags = TaxonomyNormalizer.extractTags(
                "Entertainment",
                "Psychological Thriller, Crime, Mystery",
                List.of("Leonardo DiCaprio")
        );
        assertThat(tags).contains("Leonardo DiCaprio", "Psychological Thriller", "Crime", "Mystery");
    }
}
