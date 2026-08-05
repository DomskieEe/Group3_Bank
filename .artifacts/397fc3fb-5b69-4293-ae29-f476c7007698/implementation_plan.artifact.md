# Implementation Plan - Proper QR Scanner & Integrated Navigation

The goal is to implement a professional QR scanner experience, integrate it into the transfer workflow, and make it easily accessible via a new navigation entry (as requested by the user, "next to transfer funds, cards, etc.").

## User Review Required

> [!IMPORTANT]
> **Navigation Change**: I will add "Scan" to the bottom navigation bar. To keep it clean, I will rearrange the tabs to: **Home**, **Transfer**, **Scan (Center)**, **Cards**, and **More**. The "Accounts" screen will be moved to the "More" menu or accessible via the Home screen's balance card to avoid crowding (keeping to 5 items which is the standard).

## Proposed Changes

### 1. QR Scanner & Receive QR

#### [NEW] [my_qr_screen.dart](file:///C:/Users/AFY83764/Documents/Mobile_Local/qr/Group3_Bank/lib/screen/my_qr_screen.dart)
- Displays the user's Savings account number as a QR code.
- Includes a "Copy Account Number" button.

#### [MODIFY] [qr_scanner_screen.dart](file:///C:/Users/AFY83764/Documents/Mobile_Local/qr/Group3_Bank/lib/screen/qr_scanner_screen.dart)
- **UI Enhancements**: Add a professional scanning overlay with a "laser" line animation.
- **Permissions**: Ensure it handles camera permissions gracefully (via `mobile_scanner`).
- **Logic**: When a code is detected, it will validate if it looks like an account number and then navigate to the Transfer screen with that number pre-filled.

### 2. Transfer Integration

#### [MODIFY] [transfer_screen.dart](file:///C:/Users/AFY83764/Documents/Mobile_Local/qr/Group3_Bank/lib/screen/transfer_screen.dart)
- Update the constructor to accept an optional `initialRecipient` account number.
- Add a "Scan QR" icon button inside the recipient text field for quick access if they are already on this screen.

### 3. Navigation & Dashboard

#### [MODIFY] [main_shell.dart](file:///C:/Users/AFY83764/Documents/Mobile_Local/qr/Group3_Bank/lib/screen/main_shell.dart)
- **Bottom Navigation**: Update items to `[Home, Transfer, Scan, Cards, More]`.
- Special Handling: The "Scan" tab will launch the `QrScannerScreen`.

#### [MODIFY] [dashboard_screen.dart](file:///C:/Users/AFY83764/Documents/Mobile_Local/qr/Group3_Bank/lib/screen/dashboard_screen.dart)
- Add "Quick Actions" row: **Scan**, **My QR**, **Send Money**, **Bills**.
- Make the balance card tappable to navigate to the **Accounts** screen (since it's being moved from the main tabs).

## Verification Plan

### Manual Verification
1. **QR Scanning**:
   - Navigate to "Scan" tab.
   - Scan a valid account number QR.
   - Verify it redirects to "Transfer" with the account number pre-filled.
2. **Personal QR**:
   - Open "My QR" from Dashboard or More menu.
   - Verify it shows the correct account number.
3. **Navigation**:
   - Check that all 5 bottom tabs work as expected.
   - Verify "Accounts" is accessible from Dashboard.
4. **Transfer Flow**:
   - Complete a transfer using a scanned account number.
