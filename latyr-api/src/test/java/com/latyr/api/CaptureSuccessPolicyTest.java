package com.latyr.api;
import com.latyr.api.adapter.AIProvider.*;
import com.latyr.api.domain.enums.*;
import com.latyr.api.service.*;
import org.junit.jupiter.api.Test;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

class CaptureSuccessPolicyTest {
    @Test void freshAndCachedPredicatesAgreeWithoutSummaryOrSpecializedEntity() {
        var result = new AIAnalysisResult(null,null,null,Intent.LEARN,null,null,null,List.of(),
            List.of(new AIEntity(EntityType.IDEA,"How to preserve herbs","Store stems in water",null,ActionCTA.REMEMBER,Map.of())));
        assertTrue(CaptureSuccessPolicy.isUseful(result));
        assertTrue(CaptureSuccessPolicy.isUsefulCache(CaptureAnalysisCodec.encode(result)));
        assertEquals(result,CaptureAnalysisCodec.decode(CaptureAnalysisCodec.encode(result)));
    }
    @Test void summaryAndPlaceholderOnlyNeverQualify() {
        var result = new AIAnalysisResult("Summary","Summary",null,Intent.EXPLORE,null,null,null,List.of(),List.of());
        assertFalse(CaptureSuccessPolicy.isUseful(result));
        assertFalse(CaptureSuccessPolicy.isUsefulCache(CaptureAnalysisCodec.encode(result)));
        assertFalse(CaptureSuccessPolicy.isUsefulCache(Map.of("intent","EXPLORE","entities",List.of(
            Map.of("title","Saved Item","entity_type","IDEA","action_cta","EXPLORE")))));
    }
    @Test void malformedCacheAndUnknownVersionCannotBeTreatedAsSuccess() {
        assertFalse(CaptureSuccessPolicy.isUsefulCache(Map.of("intent","WATCH","entities",List.of(Map.of("title",17)))));
        assertThrows(IllegalArgumentException.class, () -> CaptureAnalysisCodec.decode(Map.of("schema_version",2)));
    }
}
