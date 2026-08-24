package com.latyr.api;

import com.latyr.api.adapter.EphemeralMediaStreamer;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class EphemeralMediaStreamerTest {

    @Test
    @DisplayName("Ephemeral Stream: Null or empty URL returns empty byte array safely")
    void testStreamMedia_NullUrl() {
        EphemeralMediaStreamer streamer = new EphemeralMediaStreamer();
        byte[] bytes = streamer.streamMedia(null);
        assertNotNull(bytes);
        assertEquals(0, bytes.length);

        byte[] emptyBytes = streamer.streamMedia("");
        assertNotNull(emptyBytes);
        assertEquals(0, emptyBytes.length);
    }
}
