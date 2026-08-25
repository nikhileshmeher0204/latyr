package com.latyr.api.controller;

import com.latyr.api.adapter.AIProvider;
import com.latyr.api.adapter.EphemeralMediaStreamer;
import com.latyr.api.adapter.ScraperProvider;
import com.latyr.api.domain.enums.Language;
import com.latyr.api.dto.AnalyzeRawRequest;
import com.latyr.api.dto.AnalyzeUrlRequest;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/ai")
public class AIController {

    private static final Logger log = LoggerFactory.getLogger(AIController.class);

    private final AIProvider aiProvider;
    private final ScraperProvider scraperProvider;
    private final EphemeralMediaStreamer mediaStreamer;

    public AIController(AIProvider aiProvider, ScraperProvider scraperProvider, EphemeralMediaStreamer mediaStreamer) {
        this.aiProvider = aiProvider;
        this.scraperProvider = scraperProvider;
        this.mediaStreamer = mediaStreamer;
    }

    @PostMapping("/analyze-url")
    public ResponseEntity<Map<String, Object>> analyzeUrl(@Valid @RequestBody AnalyzeUrlRequest request) {
        log.info("Direct AI API Call: Analyzing URL {}", request.url());

        var scraped = scraperProvider.extractMedia(request.url());
        byte[] mediaBytes = mediaStreamer.streamMedia(scraped.audioUrl());

        Language language = request.language() != null ? request.language() : Language.ENGLISH;
        var aiResult = aiProvider.analyzeMedia(mediaBytes, "audio/mp4", scraped.caption(), language);

        return ResponseEntity.ok(Map.of(
                "scraped_media", scraped,
                "ai_analysis", aiResult
        ));
    }

    @PostMapping(value = "/analyze-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<AIProvider.AIAnalysisResult> analyzeImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "language", defaultValue = "ENGLISH") Language language
    ) throws IOException {
        log.info("Direct AI API Call: Analyzing uploaded image ({} bytes, type: {})", file.getSize(), file.getContentType());

        byte[] imageBytes = file.getBytes();
        String contentType = file.getContentType() != null ? file.getContentType() : "image/png";

        var aiResult = aiProvider.analyzeImage(imageBytes, contentType, language);
        return ResponseEntity.ok(aiResult);
    }

    @PostMapping(value = "/analyze-media", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<AIProvider.AIAnalysisResult> analyzeMedia(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "caption", required = false) String caption,
            @RequestParam(value = "language", defaultValue = "ENGLISH") Language language
    ) throws IOException {
        log.info("Direct AI API Call: Analyzing uploaded audio/video ({} bytes, type: {})", file.getSize(), file.getContentType());

        byte[] mediaBytes = file.getBytes();
        String contentType = file.getContentType() != null ? file.getContentType() : "audio/mp3";

        var aiResult = aiProvider.analyzeMedia(mediaBytes, contentType, caption, language);
        return ResponseEntity.ok(aiResult);
    }

    @PostMapping("/analyze-text")
    public ResponseEntity<AIProvider.AIAnalysisResult> analyzeText(@Valid @RequestBody AnalyzeRawRequest request) {
        log.info("Direct AI API Call: Analyzing raw text/caption");

        Language language = request.language() != null ? request.language() : Language.ENGLISH;
        var aiResult = aiProvider.analyzeMedia(new byte[0], "audio/mp3", request.caption(), language);
        return ResponseEntity.ok(aiResult);
    }
}
