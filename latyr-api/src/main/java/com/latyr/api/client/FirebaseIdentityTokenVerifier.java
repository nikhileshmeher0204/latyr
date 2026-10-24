package com.latyr.api.client;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class FirebaseIdentityTokenVerifier implements IdentityTokenVerifier {

    @Override
    public VerifiedIdentity verify(String token) throws Exception {
        if (FirebaseApp.getApps().isEmpty()) {
            throw new IllegalStateException("Firebase token verification is unavailable");
        }
        FirebaseToken verified = FirebaseAuth.getInstance().verifyIdToken(token);
        Object firebaseClaim = verified.getClaims().get("firebase");
        Object signInProvider = firebaseClaim instanceof Map<?, ?> firebase
                ? firebase.get("sign_in_provider") : null;
        IdentityProvider provider = switch (signInProvider instanceof String value ? value : "") {
            case "google.com" -> IdentityProvider.GOOGLE;
            case "apple.com" -> IdentityProvider.APPLE;
            default -> IdentityProvider.UNSUPPORTED;
        };
        return new VerifiedIdentity(verified.getUid(), verified.getEmail(),
                verified.getName(), verified.getPicture(), provider);
    }
}
