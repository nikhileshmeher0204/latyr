package com.latyr.api.controller;

import com.latyr.api.dto.UpdatePreferencesRequest;
import com.latyr.api.dto.UserProfileResponse;
import com.latyr.api.security.AuthenticatedUser;
import com.latyr.api.security.CurrentUser;
import com.latyr.api.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> getCurrentUserProfile(@CurrentUser AuthenticatedUser currentUser) {
        UserProfileResponse response = userService.getUserProfile(currentUser.getUserId());
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/preferences")
    public ResponseEntity<UserProfileResponse> updatePreferences(
            @CurrentUser AuthenticatedUser currentUser,
            @Valid @RequestBody UpdatePreferencesRequest request
    ) {
        UserProfileResponse response = userService.updatePreferences(currentUser.getUserId(), request);
        return ResponseEntity.ok(response);
    }
}
