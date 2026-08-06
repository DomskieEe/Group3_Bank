# Implementation Plan - Fix QR Scanner UI

The user reports a "white box" obstructing the QR scanner view. This is likely caused by the `ColorFiltered` overlay not rendering correctly or being too intrusive. I will remove the dimmed background and the white cutout container, leaving only the essential scanning frame and animation.

## User Review Required

> [!IMPORTANT]
> **Overlay Simplification**: I am removing the darkened background around the scan area. You will now see the full camera feed with only the red corners and the scanning laser line as guides. This should eliminate the "white box" issue.

## Proposed Changes

### 1. QR Scanner UI Refinement

#### [MODIFY] [qr_scanner_screen.dart](file:///C:/Users/AFY83764/Documents/Mobile_Local/qr/Group3_Bank/lib/screen/qr_scanner_screen.dart)
- **Remove `ColorFiltered` Overlay**: Delete the stack that creates the dimmed background and the central "hole" (the source of the white box).
- **Update `_buildOverlay`**: Only return the `Scan Frame` containing the corners and the animated laser line.
- **Remove Shadowing Class**: Delete the custom `HapticFeedback` class at the bottom to avoid conflicts with the official Flutter API.
- **Clean up Imports**: Ensure `HapticFeedback` is used from `package:flutter/services.dart`.

## Verification Plan

### Manual Verification
1. Open the QR Scanner.
2. Verify that the camera feed is fully visible without any darkened areas or white boxes.
3. Confirm that the red corners and scanning line are still present as guides.
4. Verify that scanning an account number still redirects to the Transfer screen.
