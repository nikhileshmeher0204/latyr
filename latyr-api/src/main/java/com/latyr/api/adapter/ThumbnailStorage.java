package com.latyr.api.adapter;
import java.util.UUID;
public interface ThumbnailStorage { String uploadImageFromUrl(String sourceUrl, UUID captureId); }
