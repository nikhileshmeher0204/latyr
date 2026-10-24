package com.latyr.api.client;

public interface IdentityTokenVerifier {

    VerifiedIdentity verify(String token) throws Exception;

    enum IdentityProvider { GOOGLE, APPLE, UNSUPPORTED }

    record VerifiedIdentity(String uid, String email, String displayName, String photoUrl,
                            IdentityProvider provider) {}
}
