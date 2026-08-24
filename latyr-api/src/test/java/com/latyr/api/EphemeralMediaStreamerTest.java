package com.latyr.api;

import com.latyr.api.adapter.EphemeralMediaStreamer;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

class EphemeralMediaStreamerTest {

    @Test
    @DisplayName("Ephemeral Stream: Empty or mock URL returns valid non-null in-memory byte buffer")
    void testStreamMedia_Mock() {
        EphemeralMediaStreamer streamer = new EphemeralMediaStreamer();
        ReflectionTestUtils.setField(streamer, "mockEnabled", true);

        byte[] bytes = streamer.streamMedia("https://mock-cdn.latyr.internal/audio.mp3");

        assertNotNull(bytes);
        assertTrue(bytes.length > 0);
        assertTrue(bytes.length < 15 * 1024 * 1024); // Well below 15MB limit
    }

    @Test
    @DisplayName("Ephemeral Stream: Null or empty URL returns empty byte array safely")
    void testStreamMedia_NullUrl() {
        EphemeralMediaStreamer streamer = new EphemeralMediaStreamer();
        byte[] bytes = streamer.streamMedia(null);
        assertNotNull(bytes);
        assertEquals(0, bytes.length);
    }
}
