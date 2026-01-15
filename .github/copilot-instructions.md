---
description: AI rules derived by SpecStory from the project AI interaction history
applyTo: "*"
---

# In The Biz AI – Copilot Instructions

**Knowledge cutoff:** June 2024  
**Current date:** January 12, 2026

---

## 🚨 CRITICAL: TIME FORMAT - NEVER USE MILITARY TIME 🚨

**ALWAYS use 12-hour AM/PM format. NEVER use 24-hour military time.**

### ❌ WRONG (Military/24-hour time):
```
17:00:00
09:30:00
21:00
```

### ✅ CORRECT (12-hour AM/PM):
```
5:00 PM
9:30 AM
9:00 PM
```

**This applies to:**
- ALL screens in the application
- ALL time displays (shift times, event times, etc.)
- ALL time pickers and inputs
- ALL formatted time strings

**How to convert:**
```dart
String formatTime(String? time) {
  if (time == null || time.isEmpty) return '';
  try {
    final parts = time.split(':');
    if (parts.isEmpty) return time;
    int hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? parts[1] : '00';
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    else if (hour > 12) hour -= 12;
    return '$hour:$minute $period';
  } catch (e) {
    return time;
  }
}
```

---

## 🚨 CRITICAL: HOW TO CHECK FOR ERRORS - READ THIS FIRST 🚨

**NEVER check errors for a specific file. ALWAYS check the FULL WORKSPACE.**

### ❌ WRONG WAY (misses warnings, shows "No errors found" when there ARE problems):
```
get_errors with filePaths: ["path/to/file.dart"]
```

### ✅ CORRECT WAY (shows ALL errors AND warnings):
```
get_errors with NO filePaths parameter (omit it entirely)
```

**Why this matters:**
- Checking a specific file only returns ERRORS, not WARNINGS
- Checking full workspace returns BOTH errors AND warnings
- Unused variables, missing imports, and other issues are WARNINGS
- You MUST see warnings to properly fix code

**After EVERY edit, run get_errors with NO filePaths to check the full workspace.**

---

## 🚨 CRITICAL WEB DEPLOYMENT RULE 🚨

**DEPLOYMENT TARGET: Vercel (main branch) - NOT GitHub Pages**

**⚠️ BEFORE DEPLOYING - MANDATORY CHECKLIST:**
1. ✅ Update `pubspec.yaml` line 4 (version: X.X.X+N)
2. ✅ Update `lib/main.dart` line 22 (appVersion) - **NEVER SKIP THIS!**
3. ✅ Use `&` NOT `&amp;` in terminal commands
4. ✅ Run `get_errors` with NO filePaths to check full workspace

**NO MORE CACHE-BUSTING NEEDED:**
- Service workers have been completely removed (`--pwa-strategy=none`)
- Vercel serves all files with `Cache-Control: no-cache` headers
- Users will ALWAYS get the latest version on refresh (no hard refresh needed)

### Step-by-Step Deployment Process:

**Step 0: BUMP VERSION (REQUIRED FOR EVERY DEPLOYMENT):**
- `pubspec.yaml` line 4: Increment build number → `version: 1.2.1+19` becomes `version: 1.2.1+20`
- `lib/main.dart` line 22: `const String appVersion = '1.2.1+20';` **← MANDATORY!**
- **WHY:** Version tracking for debugging and user support

**Step 1: Build with NO service worker:**
```cmd
cd "c:\Users\Brandon 2021\Desktop\In The Biz AI"
flutter build web --release --pwa-strategy=none
```

**Step 2: Copy built files to root (for legacy compatibility):**
```cmd
Copy-Item -Path "build\web\main.dart.js" -Destination "main.dart.js" -Force
```

**Step 3: Commit and push to MAIN (not gh-pages):**
```cmd
git add .
git commit -m "Deploy: [your message]"
git push origin main
```

**OR use this single command (AFTER bumping both versions - pubspec.yaml AND lib/main.dart):**
```cmd
cd "c:\Users\Brandon 2021\Desktop\In The Biz AI" ; flutter build web --release --pwa-strategy=none ; Copy-Item -Path "build\web\main.dart.js" -Destination "main.dart.js" -Force ; git add . ; git commit -m "Deploy: [your message]" ; git push origin main
```

**⚠️ CRITICAL: Use `;` for command chaining in PowerShell, NOT `&` or `&amp;`**
### WHY THIS IS CRITICAL:
- Editing `lib/main.dart` does NOT update the website
- The website serves `main.dart.js` from the ROOT, not from `lib/`
- `flutter build web --release --pwa-strategy=none` compiles Dart → JavaScript (NO service worker)
- The built `main.dart.js` must be copied to the ROOT directory
- Vercel watches the **main** branch and deploys in ~6 seconds
- **NO SERVICE WORKERS:** We use `--pwa-strategy=none` to prevent aggressive caching
- **NO CACHE:** Vercel serves all files with `Cache-Control: no-cache` headers

### DO NOT:
- ❌ Use `&amp;` in terminal commands (HTML entity breaks commands)
- ❌ Use `&` for command chaining in PowerShell (causes errors)
- ✅ **USE `;` (semicolon) for command chaining in PowerShell**
- ❌ Just edit `lib/main.dart` and stop
- ❌ Say "the code is updated" without deploying
- ❌ Forget to copy `main.dart.js` to root
- ❌ Push to gh-pages (that's the OLD way)
- ❌ Skip updating lib/main.dart version (MANDATORY for version tracking!)
- ❌ Wait for the user to ask - DEPLOY IMMEDIATELY after code changes
- ❌ Create bat files for deployment - use manual commands only
- ❌ Start deploying without user permission
- ❌ Update index.html version (no longer needed - service workers removed)

### ALWAYS:
- ✅ Build AND deploy in the SAME action
- ✅ Update version in BOTH FILES: pubspec.yaml AND lib/main.dart (NOT index.html)
- ✅ Use `;` for command chaining in PowerShell (NOT `&` or `&amp;`)
- ✅ Use `--pwa-strategy=none` flag when building (NO service workers)
- ✅ Push to **main** branch (Vercel deploys from main)
- ✅ Verify deployment by checking console for correct version number
- ✅ Deployment completes in ~6 seconds on Vercel
- ✅ Users get latest version on regular refresh (no hard refresh needed)
- ✅ ASK USER before deploying - never deploy automatically
- ✅ Verify deployment by checking console for correct version number
- ✅ Deployment completes in ~6 seconds on Vercel
- ✅ Use MANUAL commands, never bat files
- ✅ ASK USER before deploying - never deploy automatically
- ✅ Cache-busting is handled automatically by index.html script

### IMPORTANT: GitHub/Vercel Account Ownership
- The GitHub repo MUST be owned by the same account that Vercel is authenticated as
- Currently: Repo owned by **Offerman1**, Vercel authenticated as **Offerman1**
- If deployments stop working, check that repo ownership and Vercel authentication match

### 🚨 CACHE-BUSTING SOLUTION FOR WEB DEPLOYMENT 🚨

**PROBLEM:** Users see old version after deployment until hard refresh (Ctrl+Shift+R)
**CAUSE:** Service worker aggressively caches old `main.dart.js` files
**SOLUTION:** Automatic cache-busting script in `index.html`

**How it works:**
- `index.html` contains JavaScript that checks app version in localStorage
- If version mismatch detected, unregisters service worker and forces reload
- Version automatically updates during deployment (matches pubspec.yaml)
- Users get new version immediately without manual cache clearing

**When deploying, the cache-busting handles:**
- ✅ Forces browser to fetch new `main.dart.js`
- ✅ Unregisters old service workers
- ✅ Updates version tracking in localStorage
- ✅ Works automatically - no user action required

**DO NOT:**
- ❌ Modify the cache-busting script in index.html
- ❌ Remove the version checking code
- ❌ Create separate cache-clearing mechanisms

---

## 📑 Table of Contents
1. [Documentation Rule](#documentation-rule)
2. [Device Setup & Commands](#device-setup--commands)
3. [Theme System Rules](#theme-system-rules)
4. [Website Metadata](#website-metadata)
5. [Security Rules](#security-rules)
6. [AI Vision UI Design](#ai-vision-ui-design)
7. [Terminal & Shell Rules](#terminal--shell-rules)
8. [Web Deployment](#web-deployment)
9. [Supabase Migrations](#supabase-migrations)
10. [Google Play & RevenueCat](#google-play--revenueCat)
11. [Android Build & Troubleshooting](#android-build--troubleshooting)
12. [Copilot Instructions File](#copilot-instructions-file)
13. [Deprecated/Legacy Instructions](#deprecatedlegacy-instructions)
14. [Admin Panel Enhancements](#admin-panel-enhancements)
15. [Calendar Import Issues](#calendar-import-issues)

---

## 📝 Documentation Rule

**CRITICAL:**
- Do **NOT** add implementation details, feature summaries, or "how things work" documentation here.
- This file is for workflow, device, deployment, and critical rules **only**.
- See project docs for feature/implementation details.

---

## 📱 Device Setup & Commands

**Quick Reference Table:**

| Device         | ID              | IP           | Run Command Example                                 |
|---------------|-----------------|--------------|-----------------------------------------------------|
| Seeker Phone  | SM02G4061996968 | 10.0.0.65    | `flutter run -d SM02G4061996968`                   |
| Tablet        | R92X3069WGW     | 10.0.0.50    | `flutter run -d R92X3069WGW`                       |
| SN339D Phone  | (see batch)     | 10.0.0.98    | `flutter run -d 10.0.0.98:5555`                    |

**Wireless Debugging:**
- Use `connect-wifi.bat` to connect all devices over Wi-Fi.
- See batch file section for details.

---

## 🎨 Theme System Rules

**NEVER use hardcoded colors. ALWAYS use AppTheme.**

**Key Points:**
- Use `AppTheme` for all colors (see list in original instructions).
- Hero cards: always use `AppTheme.heroCardBackground`.
- Use `AppTheme.adaptiveTextColor` for text that must adapt to theme.
- See full theme rules in original instructions for details.

---

## 🌐 Website Metadata

- Always update `<title>` and Open Graph meta tags in `index.html` before deployment.
- Verify metadata by sharing the site link after deploy.

---

## 🔒 Security Rules

- **NEVER** commit `.env` files; always add to `.gitignore`.
- Restrict API keys, rotate if compromised, monitor usage.
- Use `cmd.exe` (not PowerShell) for all shell commands.

---

## 🤖 AI Vision UI Design

- Unified Scan button in header for Add/Edit/Details screens.
- Scan options in bottom sheet menu.
- Post-scan verification screen for extracted data.
- Use `HeroCard` widget for all hero/summary cards.

---

## 💻 Terminal & Shell Rules

- **ALWAYS** use `cmd.exe` in VS Code.
- Remove PowerShell from VS Code terminal profiles.
- See settings.json snippet in original instructions.

---

## 🌐 Web Deployment

**Deployment Target: Vercel on main branch**

**Full deployment process:**
```cmd
cd "c:\Users\Brandon 2021\Desktop\In The Biz AI"
flutter clean
flutter pub get
flutter build web --release
Copy-Item -Path "build\web\main.dart.js" -Destination "main.dart.js" -Force
git add .
git commit -m "Deploy: [Your message]"
git push origin main
```

**Quick deploy (if no version change):**
```cmd
cd "c:\Users\Brandon 2021\Desktop\In The Biz AI" ; flutter build web --release ; Copy-Item -Path "build\web\main.dart.js" -Destination "main.dart.js" -Force ; git add . ; git commit -m "Deploy: [Your message]" ; git push origin main
```

**See CRITICAL WEB DEPLOYMENT RULE at top for full details.**

---

## 🗄️ Supabase Migrations

- **Do NOT** use `supabase db push` or `supabase migration up`.
- Use `node scripts/run-migration.mjs <file>.sql` only.
- See `.env` for `DATABASE_URL`.

---

## 🔐 Google Play & RevenueCat

- Use provided scripts for Play Console and RevenueCat automation.
- **Never** upload a release without explicit user confirmation.
- See original for script names and usage.

---

## 🛠️ Android Build & Troubleshooting

- If `ClassNotFoundException`, check Kotlin version, clean build, check `MainActivity.kt` and manifest.
- For Google Sign-In, ensure correct SHA-1 and OAuth setup in Google Cloud Console.

---

## 📝 COPILOT INSTRUCTIONS FILE - PURPOSE AND CONTENT

The copilot instructions file (.github/copilot-instructions.md) contains workflow rules, deployment guides, device setup steps, theming rules, security practices, and troubleshooting tips for the project. It guides AI assistants and developers, ensuring consistency and preventing common mistakes. It does not include app features, business logic, or code documentation; it only contains operational and workflow rules.

---

## 🚨 Deprecated/Legacy Instructions

See end of file for deprecated web deployment and other legacy notes.

---

// ...existing code...

**CRITICAL:** Do NOT add implementation details, feature summaries, or "how things work" documentation to these copilot instructions.

**Where to document instead:**
- **Feature completion:** Update `docs/MASTER_ROADMAP.md`
- **Implementation guides:** Add to relevant phase docs in `docs/phases/`
- **New features:** Document in `docs/FEATURE_BACKLOG.md` (if not started) or roadmap (if completed)
- **Technical specs:** Create dedicated docs in `docs/` folder
- **App Store Submission:** Create `docs/APP_STORE_SUBMISSION_GUIDE.md` and `GOOGLE_PLAY_SUBMISSION_GUIDE.md`
- **Fastlane Setup Guide:** Create `docs/FASTLANE_SETUP_GUIDE.md`

**These copilot instructions should ONLY contain:**
- Critical workflow rules (device IDs, deployment commands, theme rules)
- Things the AI MUST remember every session
- Rules that prevent breaking the app (like "never hardcode colors")

---

## 📱 DEVICE CODE FOR ANDROID PHONE

**User's Android Device:** Samsung Phone (Seeker)
**Device ID:** `SM02G4061996968`
**IP Address:** `10.0.0.65`

**To run the app on the user's phone:**
```powershell
cd "c:\Users\Brandon 2021\Desktop\In The Biz AI" ; flutter run -d SM02G4061996968
```
**To run the app wirelessly:**
```powershell
cd "c:\Users\Brandon 2021\Desktop\In The Biz AI" ; flutter run -d 10.0.0.65:5555
```

**User's Android Tablet:** Samsung Galaxy Tab (SM X210)
**Tablet ID:** `R92X3069WGW`
**Tablet IP Address:** `10.0.0.50`

**To run the app on the user's tablet:**
```powershell
cd "c:\Users\Brandon 2021\Desktop\In The Biz AI" ; flutter run -d R92X3069WGW
```

**Running Multiple Devices Simultaneously:**
- Flutter can only run one device per terminal session.
- Open two separate terminals or use VS Code's split terminal (`Ctrl+Shift+5`) to run both devices simultaneously.
- When you press `r` (hot reload) in either terminal, it will reload **only that device**. But when you **save a file** in VS Code, both devices will hot reload automatically at the same time.
- **Save file (Ctrl+S):** Both devices reload 🔄🔄
- **Press `r` in Terminal 1:** Only phone reloads 🔄
- **Press `r` in Terminal 2:** Only tablet reloads 🔄
- **Press `R` (capital):** Hot restart for that specific device
- **Press `q`:** Quit that specific device
- Hitting **Ctrl+S** will trigger a hot reload on both devices. It's a handy trick when you want to manually reload everything without making an actual code change.
- You can also just add a space somewhere and then delete it, then hit save - Flutter will reload both devices even though nothing actually changed in the code.

**Wireless Debugging Setup (ADB over Wi-Fi):**

These steps allow for wireless debugging, avoiding USB cable issues.

**Prerequisites:**
1.  Android SDK Platform-Tools installed.
2.  USB debugging enabled on your Android device.
3.  Both your computer and Android device connected to the same Wi-Fi network.

**Setup Steps:**

1.  **Connect Device via USB:** Connect your Android device to your computer using a USB cable.

2.  **Enable TCP/IP Mode:** Run the following command in the terminal, replacing `<device_id>` with your device's ID (obtained from `adb devices`):
    ```powershell
    C:\\Android\\Sdk\\platform-tools\\adb.exe -s <device_id> tcpip 5555
    ```
    Example:
    ```powershell
    C:\\Android\\Sdk\\platform-tools\\adb.exe -s SM02G4061996968 tcpip 5555
    ```

3.  **Find Device IP Address:** On your Android device, go to **Settings** → **About phone** → **Status** → **IP address** or **Settings** → **Connections** → **Wi-Fi** → tap your connected network.

4.  **Connect via Wi-Fi:** Run the following command, replacing `<device_ip_address>` with the IP address you found:
    ```powershell
    C:\\Android\\Sdk\\platform-tools\\adb.exe connect <device_ip_address>:5555
    ```
    Example:
    ```powershell
    C:\\Android\\Sdk\\platform-tools\\adb.exe connect 10.0.0.98:5555
    ```

5.  **Verify Connection:** Run `flutter devices` to see your device listed as `<device_ip_address>:5555`.

6.  **Run Wirelessly:** Deploy your Flutter app wirelessly using:
    ```powershell
    cd "c:\Users\Brandon 2021\Desktop\In The Biz AI" ; flutter run -d <device_ip_address>:5555
    ```
    Example:
    ```powershell
    cd "c:\Users\Brandon 2021\Desktop\In The Biz AI" ; flutter run -d 10.0.0.98:5555
    ```

**Batch File for Easy Reconnection:**

Create a batch file (e.g., `connect-wifi.bat`) with the following content, replacing the IP addresses with your device's IPs:

```bat
@echo off
REM All device IP addresses
set TABLET_IP=10.0.0.50
set SEEKER_IP=10.0.0.65
set SN339D_IP=10.0.0.98
set ADB_PATH=C:\\Android\\Sdk\\platform-tools\\adb.exe

echo Connecting all devices over Wi-Fi...
echo.
echo Connecting Tablet (SM X210)...
%ADB_PATH% connect %TABLET_IP%:5555
echo.
echo Connecting Seeker Phone...
%ADB_PATH% connect %SEEKER_IP%:5555
echo.
echo Connecting SN339D Phone...
%ADB_PATH% connect %SN339D_IP%:5555

echo.
echo Available devices:
%ADB_PATH% devices

echo.
echo To disconnect all: adb disconnect
pause
```

**How to Run the Batch File:**

*   **From File Explorer:** Navigate to your project folder (`In The Biz AI`) and double-click `connect-wifi.bat`.
*   **From VS Code Terminal:** Type `connect-wifi.bat` and press Enter.

**When to Use the Batch File:**

*   After restarting your phone/tablet.
*   After disconnecting from Wi-Fi.
*   When `flutter devices` doesn't show the wireless devices.

**Device-Specific Wireless Run Commands:**

*   Tablet: `flutter run -d 10.0.0.50:5555`
*   Seeker: `flutter run -d 10.0.0.65:5555`
*   SN339D: `flutter run -d 10.0.0.98:5555`

**Important Notes:**

*   Keep both devices on the same Wi-Fi network.
*   The first connection requires USB (for enabling TCP/IP mode).
*   IP address may change - if the connection fails, check your IP and update the batch file.
*   Wireless debugging uses more battery than USB.

---

## 🎨 THEME SYSTEM - CRITICAL RULES

**NEVER use hardcoded colors. ALWAYS use AppTheme.**

### General Theming Philosophy:
- Professional apps use a **primary accent color** (green, purple, blue) but keep most of the UI **neutral** (whites, grays, blacks) so the accent color **pops** instead of overwhelming everything.
- Use the accent color **sparingly** - for buttons, highlights, gradients, and key interactive elements.
- **Backgrounds should be neutral** (almost black - `#0D0D0D`) in dark themes to make the colored containers pop.

### Color Usage Rules:
**✅ CORRECT:**
```dart
Container(
  color: AppTheme.primaryGreen,
  child: Icon(Icons.add, color: AppTheme.textPrimary),
)
```

**❌ WRONG:**
```dart
Container(
  color: const Color(0xFF00D632),  // NEVER hardcode
  child: Icon(Icons.add, color: Colors.white),  // NEVER use Colors.xxx
)
```

### Available Theme Colors:
- **Primary:** `AppTheme.primaryGreen` (main brand color - changes with theme)
- **Backgrounds:** `AppTheme.darkBackground`, `AppTheme.cardBackground`, `AppTheme.cardBackgroundLight`
- **Text:** `AppTheme.textPrimary`, `AppTheme.textSecondary`, `AppTheme.textMuted`
- **Accents:** `AppTheme.accentRed`, `AppTheme.accentBlue`, `AppTheme.accentYellow`, `AppTheme.accentOrange`, `AppTheme.accentPurple`
- **Semantic:** `AppTheme.successColor`, `AppTheme.warningColor`, `AppTheme.dangerColor`, `AppTheme.scheduledShiftColor`
- **Charts:** `AppTheme.chartGreen1`, `AppTheme.chartGreen2`, `AppTheme.chartGreen3`
- **Gradients:** `AppTheme.greenGradient`
  // Hero card background - always dark, even in light themes
- **Hero Card:** `AppTheme.heroCardBackground`

### How Theming Works:
1. User selects theme in Settings → Appearance (11 themes available)
2. Theme saved to database via `ThemeProvider.setTheme()`
3. App automatically restarts and loads new theme from database
4. `ThemeProvider` updates `AppTheme.setColors()` with theme-specific colors
5. **ALL colors update** - buttons, text, charts, badges, everything

### Available Themes:
**Dark Themes:**
- Finance Green (Default) - Classic green finance app
- Midnight Blue - Professional blue tones
- Purple Reign - Royal purple
- Ocean Breeze - Teal/aqua
- Sunset Glow - Orange/warm tones
- Forest Night - Nature green
- PayPal Blue - PayPal-inspired
- Finance Pro - Crypto blue/purple

**Light Themes:**
- Light Mode - Classic white background with emerald green accent
- Finance Light - PayPal-inspired blue theme with off-white background
- Soft Purple - Gentle purple theme

### When Creating New UI:
- **NEVER** use `Colors.green`, `Colors.blue`, `Color(0xFFXXXXXX)`, etc.
- **ALWAYS** use `AppTheme.primaryGreen`, `AppTheme.accentBlue`, etc.
- If you need opacity: `AppTheme.primaryGreen.withOpacity(0.5)`
- For text on colored backgrounds: `AppTheme.primaryOnDark` or `AppTheme.textPrimary`
- For AppBar titles and other text directly on backgrounds, use `AppTheme.adaptiveTextColor` to automatically adjust to the current theme.
- **Hero Card Backgrounds:** Hero cards must maintain their dark background even when in Light Mode. Use `AppTheme.heroCardBackground` which is **ALWAYS** the pure black color (`#000000`), regardless of whether you're in Light Mode or any other theme.
- **Hero Card Gradient Colors:** The hero card gradient must ALWAYS use the dark mode gradient colors, regardless of the theme.
- **Header Icon Color:** Header icons (in app bars, etc.) must use `AppTheme.headerIconColor` to automatically switch between black (for light themes) and white (for dark themes) based on the background luminance.
- **"Add Job" and "Restore Deleted Jobs" Buttons:** In the "My Jobs" section of the settings screen, the text on these buttons should use `AppTheme.adaptiveTextColor` to switch between white and black based on the current theme.
- **"Export PDF" and "Export CSV" Options:** In the stats screen's export dropdown, the text on these options should use `AppTheme.adaptiveTextColor` to switch between white and black based on the current theme.
- **"Clear Chat" Option:** In the chat assistant, the chat assistant, the "Clear Chat" text should use `AppTheme.adaptiveTextColor` to switch between black in light mode and white in dark mode.
- **Job Tab Text Color:** When a job is selected in light mode, the text should be white for better visibility.
- **Job Filter/Period Filter Text Color:** When a job is selected, or one of the filters of day, week, month, year or all is selected on the hero card, the inner text should be white.

### Additional Hero Card Rules:
- **Hero Card Background:** Hero cards must maintain a distinct background even when in Light Mode. Use `AppTheme.heroCardBackground` which defaults to a dark color, but adapts to a lighter gray (`#3D3D3D`) in light mode to ensure visual harmony.
- **Hero Card Gradient Colors:** The hero card gradient must use the current theme's primary and accent colors, ensuring the gradient adapts to the selected theme while remaining visible.

### Correct Hero Card Implementation
```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Universal Hero Card widget - dark background with green/blue gradient
/// Used for dashboard earnings, shift summaries, job cards, etc.
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;

  const HeroCard({
    super.key,
    required this.child,
    this.child,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Detect if we're in light mode by checking background luminance
    final isLightMode = AppTheme.darkBackground.computeLuminance() > 0.5;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isLightMode
            ? const Color(0xFF5A5A5A) // Light mode: #5A5A5A (adjust lighter/darker as needed)
            : const Color(0xFF1A1A1A), // Dark mode: #1A1A1A
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusXL),
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryGreen.withOpacity(0.15),
              AppTheme.accentBlue.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusXL),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
```

---

## 🌐 WEBSITE METADATA RULES

- **When deploying the website, ALWAYS update the `<title>` tag** in the `index.html` file to reflect the correct site name (e.g., "In The Biz").
- **ALWAYS update the Open Graph meta tags** (`og:title`, `og:description`, `og:image`, etc.) in the `index.html` file to ensure correct display when sharing links. This includes:
  - `og:title`: The title of your website
  - `og:description`: A brief description of your website
  - `og:image`: The URL of an image to display when sharing the link
- **Verify the website metadata** after deployment by sharing the link on social media or messaging platforms to ensure it displays correctly.

---

## 🔒 SECURITY RULES

- **NEVER commit `.env` files to Git.** These files contain sensitive API keys and credentials.
- **ALWAYS add `.env` to your `.gitignore` file.** This prevents accidental commits.
- **When creating new API keys, restrict their usage** to only the necessary services (e.g., Generative Language API for Gemini).
- **Rotate API keys immediately** if they are compromised (e.g., accidentally committed to a public repository).
- **Monitor API key usage** in the cloud console to detect suspicious activity.
- **For web deployments, configure Docker Desktop to start automatically** to ensure the Supabase CLI and other tools function correctly.
- **When using Docker on Windows, restart the terminal** after installing Docker Desktop to ensure the Supabase CLI and other tools function correctly.
- **From now on, don't use Powershell anymore use cmd.**

---

## 🤖 AI VISION FEATURES - UI DESIGN

This section defines the UI placement strategy for the AI Vision features.

**Consolidated Vision:** The AI Vision features and logic are now consolidated into `docs/AI_VISION_MASTER_BLUEPRINT.md`.

**Core Principle:** A unified Scan button provides access to all AI-powered scanning functionalities.

### 1. ✨ Unified Scan Button

-   **Placement:** Header of Add Shift, Edit Shift, and Shift Details screens.
    ```
    │  ← Back    [Title]    [✨ Scan]  │
    ```
-   **Action:** Tapping the Scan button opens a bottom sheet menu.
-   **Icon:** Use ✨ (sparkles) to suggest AI magic.

### 2. Scan Options - Bottom Sheet Menu

-   **Menu Items:**
    ```
    ┌──────────────────────────────────┐
    │ ✨ Scan Business Card              │
    │ ✨ Scan BEO (Banquet Event Order)   │
    │ ✨ Scan Paycheck                  │
    │ ✨ Scan Invoice                   │
    └──────────────────────────────────┘
-   **Behavior:**
    -   Each item triggers the camera, initiating the respective scan.

### 3. Post-Scan Verification Screen

-   **Purpose:** Display extracted data for confirmation.
-   **Elements:**
    -   Image of the scanned document.
    -   Fields: Job, Client, Date, Hours, Pay Rate, Total Pay
    -   Button: ✅ Confirm & Save Shift
    -   Button: 重新扫描 (Rescan) - to retake the scan.

### 4. Empty State

-   **Display:** When no shifts exist.
    ```
    ✨ No Shifts Yet - Start Scanning! ✨
    ```
-   **Action:** Tapping this displays the Scan Options menu.

### 5. Code Overview

-   **Central Widget:** A single, versatile `HeroCard` widget.
-   **Integration:** Used across the app for dashboard earnings, shift summaries, and job cards.
-   **Functionality:** Displays key interactive elements with a dark background and green/blue gradient.

---

## 💻 TERMINAL & SHELL RULES

- **ALWAYS use `cmd.exe` instead of PowerShell.**
- To ensure VS Code **always** uses `cmd.exe`, add the following to your VS Code `settings.json` and remove the PowerShell profile:

```json
"terminal.integrated.defaultProfile.windows": "CommandPrompt",
"terminal.integrated.profiles.windows": {
  "Command Prompt": {
    "path": "${env:windir}\\System32\\cmd.exe",
    "args": [],
    "icon": "terminal-cmd"
  }
}
```
This removes PowerShell from the profiles entirely, so VS Code can't offer it as an option and will **only** show Command Prompt. PowerShell itself will still be installed on your Windows machine but not available as an option in VS Code.
- If the above settings do not work, try reloading the VS Code window (`Ctrl+Shift+P` → "Reload Window").
- If a PowerShell terminal opens, manually switch to the Command Prompt tab or close the PowerShell terminal entirely so only `cmd.exe` is available.

---

## 🌐 WEB DEPLOYMENT TO GITHUB PAGES (CRITICAL)

**IMPORTANT:** GitHub Pages serves files from the **ROOT** of the gh-pages branch, NOT from `build/web/` folder.

### SINGLE-COMMAND DEPLOYMENT (RECOMMENDED)

**Use this one-line command for all web deployments:**

```cmd
cd "c:\Users\Brandon 2021\Desktop\In The Biz AI" ; flutter build web --release ; robocopy "build\web" "." *.* /E /XD build .git node_modules android ios lib docs scripts supabase .idea .vscode .github assets web .specstory .dart_tool ; git add . ; git commit -m "Deploy: [Your message]" ; git push origin gh-pages
```

**What this command does:**
1. Navigates to project directory
2. Builds Flutter web app in release mode
3. Copies build files from `build/web` to root (excluding source folders)
4. Stages all changes
5. Commits with your message
6. Pushes to gh-pages branch

**Example Usage:**
```cmd
cd "c:\Users\Brandon 2021\Desktop\In The Biz AI" ; flutter build web --release ; robocopy "build\web" "." *.* /E /XD build .git node_modules android ios lib docs scripts supabase .idea .vscode .github assets web .specstory .dart_tool ; git add . ; git commit -m "Deploy: Fix UTC timezone in AI agent" ; git push origin gh-pages
```

**Why this approach:**
- ✅ Single command deploys everything
- ✅ No manual steps required
- ✅ Consistent deployment process
- ✅ Less room for error
- ✅ Fast and efficient

**Alternative: Use deploy.bat**

If you prefer, you can still use the `deploy.bat` script in the project root:

```bat
@echo off
echo.
echo ========================================
echo   IN THE BIZ - WEB DEPLOYMENT
echo ========================================
echo.

echo Step 1: Building Flutter web app...
call flutter build web --release --base-href=/
if errorlevel 1 (
    echo BUILD FAILED!
    pause
    exit /b 1
)

echo.
echo Step 2: Copying build files to root...
xcopy /E /Y "build\web\*" "." >nul

echo.
echo Step 3: Committing changes...
git add .
git commit -m "Deploy: %date% %time%"

echo.
echo Step 4: Pushing to GitHub...
git push origin gh-pages

echo.
echo ========================================
echo   DEPLOYMENT COMPLETE!
echo   Website: https://inthebiz.app
echo ========================================
echo.
pause
```

**To use the batch file:**
- Double-click `deploy.bat` in File Explorer, or
- Run `deploy.bat` in the terminal

---

## 🗄️ SUPABASE DATABASE MIGRATIONS

**DO NOT use `supabase db push` or `supabase migration up`** - these require Docker and are unreliable on Windows.

### How to Run SQL Migrations:

**Use the Node.js Script (Only Method):**
```powershell
node scripts/run-migration.mjs <migration-file>.sql
```

**Example:**
```powershell
node scripts/run-migration.mjs supabase/migrations/20251231000000_create_chat_messages.sql
```

### Required Setup:

1. **Script Location:** `scripts/run-migration.mjs` (already created)
2. **SQL Files Location:** `supabase/migrations/` directory
3. **Required Packages:** `pg` and `dotenv` (already installed via `npm install pg dotenv`)
4. **Environment Variable:** `DATABASE_URL` in `.env` file

**DATABASE_URL format:**
```
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-ID].supabase.co:5432/postgres
```

### How It Works:

The script (`scripts/run-migration.mjs`):
- Reads the SQL file from the migrations directory
- Connects directly to PostgreSQL using the `pg` npm package
- Executes the SQL in a transaction (BEGIN/COMMIT/ROLLBACK on error)
- Shows helpful error messages if it fails

### Getting the Database Password:

1. Go to: **https://app.supabase.com/project/[PROJECT-ID]/settings/database**
2. Click **"Reset Database Password"** (safe - only affects this project)
3. Copy the new password
4. Update `DATABASE_URL` in `.env` with the new password
5. Run the migration

### Creating New Migrations:

1. Create a new SQL file in `supabase/migrations/`
2. **Naming format:** `YYYYMMDDHHMMSS_description.sql` (e.g., `20251231235959_add_new_table.sql`)
3. Write your SQL with proper error handling
4. Run: `node scripts/run-migration.mjs supabase/migrations/[filename].sql]`

### On Windows:

On Windows, configure Docker Desktop to start automatically to ensure the Supabase CLI and other tools function correctly. Restart the terminal after installing Docker Desktop to ensure the Supabase CLI and other tools function correctly.

---

## 🔐 GOOGLE PLAY & REVENUECAT API ACCESS

**We have automated API access to both Google Play Console and RevenueCat.**

### Google Play Developer API

**Service Account:** `revenuecat-play-billing@gen-lang-client-0009693474.iam.gserviceaccount.com`
**Credentials File:** `play-service-account.json` (in project root)
**Package Name:** `com.inthebiz.app`

**Available Scripts:**
```cmd
# Test Google Play API authentication
node scripts/test-play-auth.mjs

# Create subscription products in Google Play
node scripts/create-play-products.mjs

# Upload new release to Google Play (internal testing track)
node scripts/upload-release.mjs

# Get tester emails from database
node scripts/get-tester-emails.mjs
```

**IMPORTANT:** The service account and OAuth clients must be configured for the correct Google Cloud project. There are two projects: "In The Biz AI" and "gen-lang-client-0009693474". The service account is in "gen-lang-client-0009693474".

**What the AI can do automatically:**
- ✅ Create subscription products in Google Play Console
- ✅ Upload new releases to Google Play (internal testing track)
- ✅ Test API authentication
- ✅ List existing subscriptions
- ✅ Verify service account permissions
- ✅ Extract tester emails from Supabase database

**IMPORTANT:** Always ASK the user before uploading a release. Do NOT automatically run `upload-release.mjs` without explicit user confirmation. The script is available but should only be used when user explicitly requests deployment.

**Requirements:**
- Service account must have **Admin (all permissions)** at app level in Play Console
- Payment profile must be set up in Google Play Console
- App must be uploaded to Play Console (at least to internal testing)
- App signing key configured in `android/key.properties`

**Automated Release Workflow:**
1. Update version in `pubspec.yaml` (e.g., `version: 1.0.0+3`)
2. Build: `flutter build appbundle --release`
3. Upload: `node scripts/upload-release.mjs`
4. Script automatically creates edit, uploads bundle, assigns to track, and commits

**Adding Testers:**
- Run `node scripts/get-tester-emails.mjs` to get emails from database
- Testers must be added manually via Play Console (API doesn't support email lists, only Google Groups)

**If you create a NEW service account through the Google Play Console:** Be sure to grant it access to RevenueCat as well.

### RevenueCat API

**API Keys stored in `.env`:**
- `REVENUECAT_SECRET_KEY` - V2 Secret Key (starts with `sk_`)\n- `REVENUECAT_PUBLIC_KEY` - Public SDK key (starts with `goog_`)\n
**Project Info:**\n- **Project ID:** &#96;proj42034829&#96;\n- **App ID:** &#96;app9cc9915545&#96;\n
**Available Script:**\n```cmd
# Automatically configure RevenueCat (products, entitlements, offerings)
node scripts/setup-revenuecat-complete.mjs
```\n
**What the AI can do automatically:**\n- ✅ Create products in RevenueCat\n- ✅ Create entitlements\n- ✅ Create offerings and packages\n- ✅ Attach products to entitlements\n- ✅ Configure complete subscription setup\n
**Current Configuration:**\n- **

**IMPORTANT: Google Play requires the SHA-1 certificate fingerprint of the app signing key to be added to the OAuth client in Google Cloud Console.**

**To locate the SHA-1 fingerprint:**

1.  Go to Google Play Console: https://play.google.com/console
2.  Select your app ("In The Biz AI").
3.  Navigate to **Release > Setup > App integrity**.
4.  In the "App signing" section, find the "SHA-1 certificate fingerprint."
    **This is the fingerprint that Google Play uses, NOT the upload key fingerprint.**

**There are separate OAuth clients for debug and release