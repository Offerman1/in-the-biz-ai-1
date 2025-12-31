---
description: AI rules derived by SpecStory from the project AI interaction history
globs: *
---

---
description: AI rules derived by SpecStory from the project AI interaction history
---

# In The Biz AI - Copilot Instructions

**Knowledge cutoff:** June 2024
**Current date:** December 31, 2025

**These instructions are automatically applied to every Copilot chat session.**

---

## 📝 DOCUMENTATION RULE

**CRITICAL:** Do NOT add implementation details, feature summaries, or "how things work" documentation to these copilot instructions.

**Where to document instead:**
- **Feature completion:** Update `docs/MASTER_ROADMAP.md`
- **Implementation guides:** Add to relevant phase docs in `docs/phases/`
- **New features:** Document in `docs/FEATURE_BACKLOG.md` (if not started) or roadmap (if completed)
- **Technical specs:** Create dedicated docs in `docs/` folder

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
**IP Address:** `10.0.0.50`

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

**Wireless Debugging Setup (ADB over Wi-Fi) (NEW - December 29, 2025):**

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

**Making IP Addresses Permanent (DHCP Reservation):**

1.  Log into your router (usually `192.168.1.1` or `10.0.0.1` in a browser).
2.  Find **DHCP Reservation** or **Static IP Assignment**.
3.  Reserve these IPs for each device's MAC address:
    *   Tablet: `10.0.0.50`
    *   Seeker: `10.0.0.65`
    *   SN339D: `10.0.0.98`

**Important Notes:**

*   Keep both devices on the same Wi-Fi network.
*   The first connection requires USB (for enabling TCP/IP mode).
*   IP address may change - if the connection fails, check your IP and update the batch file.
*   Wireless debugging uses more battery than USB.

---

## 🎨 THEME SYSTEM - CRITICAL RULES (UPDATED December 30, 2025)

**NEVER use hardcoded colors. ALWAYS use AppTheme.**

### General Theming Philosophy (NEW - December 30, 2025):
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
- **"Clear Chat" Option:** In the chat assistant, the "Clear Chat" text should use `AppTheme.adaptiveTextColor` to switch between black in light mode and white in dark mode.
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

### Shift Details Screen - File Attachments (NEW RULE - December 30, 2025):
- **Feature:** Enable the ability to include attachments (PDFs, DOCs, Excel files, etc.) to shift records on the Shift Details screen.
- **Implementation:**
  - Implement a universal file picker that supports all file types using the `file_picker` package (already installed).
  - Update the `Shift` model to include a field for storing file attachments (e.g., `fileUrls`).
  - Allow users to attach multiple files to each shift.
  - Display and manage these attachments alongside existing image/video attachments on the Shift Details screen.
  - **UI Change:** On the Edit shift screen, replace the gallery button with an attachment button (using a paperclip or attach_file icon) that gives users the option to pick any file type or choose from the gallery.
  - Add a method to show a bottom sheet with options for "Pick File" or "Choose from Gallery".
- **Tablet Specific Implementation:** On tablet, the modal for selecting attachments should slide down from the top instead of sliding up from the bottom.

### Shift Details Screen - Date Display (NEW RULE - December 30, 2025):
- **Rule:** On the Shift Details screen, keep the compact date badge INSIDE the hero card and remove the long-form date display (e.g., "Monday, December 30, 2025") that was previously above the hero card. This avoids redundancy and improves visual balance.

### Calendar Screen - Modal Shift Cards (NEW RULE - December 30, 2025):
- **Rule:** On the calendar screen's slide-up modal, the shift cards should match the style of the "Recent Shifts" cards on the dashboard. This includes:
  - Box shadow for depth.
  - Ripple effect on tap (using Material/InkWell).
  - Same layout structure:
    - Row 1: Job Name + Dollar Amount (or "Scheduled" badge).
    - Row 2: Event badge (with guest count) + Hours.
    - Row 3: Employer badge + Time range.
- **Implementation Details:**
  - Add employer badges (blue with business icon).
  - Show time ranges (start/end time in 12-hour format.

### Calendar Screen - Compact Drawer Summary Bar (NEW RULE - December 30, 2025):
- **Feature:** Replace the large hero card and separate "Add Another Shift" button in the calendar's slide-up modal with a compact summary bar.
- **Layout:** All in one compact row:
```
┌─────────────────────────────────────────────────┐
│ Income    Hours    [Double]  [+]                │
│ $245.00   8.5h                                  │
└─────────────────────────────────────────────────┘
```
- **Elements:**
  - **Income:** Left-aligned, tap to see day details.
  - **Hours:** Next to income, tap to see day details.
  - **Shift Count Badge:** Shows only when >1 shift:
    - 2 shifts → "Double"
    - 3 shifts → "Triple"
    - 4 shifts → "Quad"
    - 5+ shifts → "5x", "6x", etc.
  - **Add Button:** Compact plus icon on the right.

### Shift Details Screen - Inline Editing (NEW RULE - December 30, 2025):
- **Feature:** Enable inline editing of shift details directly on the Shift Details screen for a more fluid and modern UX.
- **Implementation:**
  - Make sections on the Shift Details screen directly editable (e.g., event title, guest count, time, hours, notes).
  - When a section is tapped, the cursor should appear, allowing immediate modification like in a word processor.
  - While editing, slightly increase the brightness of the text being edited to visually distinguish it.
  - Display a pulsing "Save" icon near the "Edit" icon when changes are made.
  - Implement input validation to ensure data integrity (e.g., time format, numeric values).
  - Implement auto-save functionality, with a manual "Save" button for confirmation after editing.
  - The "Save" button should be pulsing while the app is waiting to save the changes to the database.
   - **Tap to edit** - Any editable field becomes an inline text field when tapped
   - **Smart validation** - Time fields validate format, numbers validate properly
   - **Pulsing save icon** - Appears when changes are pending
   - **Brightness increase** - Active editing field is slightly brighter
   - **Auto-save on blur** - When you tap away, it saves (with the option to manually save via the pulsing icon)
- **Time Format Validation (NEW RULE - December 30, 2025):** When allowing direct text entry for times (e.g., 3 PM, 10:15 PM), the system must enforce a valid time format. It should also intelligently handle shorthand entries:
    - If the user types "2", intelligently default to a reasonable AM/PM choice based on shift length (e.g., if it's likely a 6-hour shift, pick the appropriate AM/PM).
    - Never allow times to simply be "2" or "8" - always force some structure (e.g., "2 PM" or "2:00").

### Shift Details Screen - Reorganize Hero Card (NEW RULE - December 30, 2025):
- **Rule:** Reorganize the shift details screen's hero card to match the layout of recent shifts cards from the dashboard for a consistent look and feel.
- **Padding Adjustment:** Due to potential overflow issues, adjust the padding for the date card on the left and the content on the right to ensure that event titles and employer names do not overlap with the hours and time range. If necessary, reduce text size to prevent overflow.
- **Badge Container Fit:** Ensure badge containers fit their content, rather than stretching across the full width of the card.
- **Dynamic Badge Placement:** Ensure the same logic from recent shifts cards is applied, such that if the event title isn't present, the employer badge moves up into its spot on that row.

### Settings Screen - Section Reordering (NEW RULE - December 30, 2025):
- **Rule:** Reorder the sections on the settings screen as follows:
    1. **MY JOBS** (stays at top)
    2. **EVENT CONTACTS** (moved up, directly beneath My Jobs)
    3. **NOTIFICATIONS** (moved up, beneath Event Contacts)
    4. **APPEARANCE** (moved up, above Schedule Sync)
    5. **DATA IMPORT** (stays here)
    6. **SCHEDULE SYNC** (moved down, below Appearance)
    7. **GOALS** (unchanged position)
    8. **TAX ESTIMATION** (unchanged position)
    9. **ACCOUNT** (stays at bottom)

### App Icon Label (NEW RULE - December 30, 2025):
- **Rule:** The app icon label should display "ITB" on both Android and iOS devices.
- **Android Implementation:** Modify the `android:label` attribute in the `AndroidManifest.xml` file:
```xml
    <application
        android:label="ITB"
        android:name="${applicationName}"
        android:icon="@mipmap/launcher_icon">
```
- **iOS Implementation:** Modify the `CFBundleDisplayName` key in the `Info.plist` file:
  ```xml
  <key>CFBundleDisplayName</key>
  <string>ITB</string>
  ```

### Import Screen - Padding (NEW RULE - December 30, 2025):
- **Rule:** Increase the padding on the Import Shift Preview screen to ensure that buttons at the bottom (e.g., Cancel, Import) are fully visible and accessible.

### Import Screen - AI-Assisted Mapping (NEW RULE - December 30, 2025):
- **Feature:** Enhance the AI-driven mapping process on the Import Shift Preview screen to provide users with more intelligent and interactive options for mapping data fields.
- **Implementation:**
  - When the AI is uncertain about how to map a data field, present the user with a selection of potential mappings.
  - For example, if the AI detects a column labeled "Party," it should ask the user: "Should this be mapped to the 'Job Name,' or does it represent a specific event? If it's an event, 'Event Name' might be more appropriate."
  - If the AI detects a single job name across all rows, prompt the user with the option to map it to the existing job or create a new job. If creating a new job, provide a field to name the new job.
  - The AI should analyze each line of the imported data to extract pertinent details and provide relevant mapping suggestions.
  - If the AI thinks it found more than 10 jobs, it must start to question that and ask for user help.
  - The AI needs to be much smarter about distinguishing between Jobs (employers - usually only 1-5 total) and Events/Parties (the actual shift details - many per job).

### Import Screen - Job Selection (NEW RULE - December 30, 2025):
- **Feature:** Allow users to pre-select a job before importing data.
- **Implementation:**
    - Add a job selection UI to the import screen.
    - Pass the pre-selected job ID to the AI analysis.
    - Ensure the AI considers the pre-selected job when mapping data fields.

### Calendar - Conflict Detection (NEW RULE - December 30, 2025):
- **Feature:** Implement a feature that alerts the user if there are conflicting appointments or schedules on their Google Calendar or iOS Calendar, such as a shift on the same day as a doctor's appointment.
- **Implementation:**
    - The feature is PARTIALLY implemented:
        - Database table `calendar_events` exists for storing imported calendar events with "conflict detection" purpose.
        - "Schedule Conflict Alerts" setting exists in Notification Settings.
    - The **actual conflict detection logic and alerts** are not implemented yet. Specifically:
        - No function to detect when a work shift overlaps with a personal calendar event (like a doctor's appointment)
        - No notification/alert system to warn you about conflicts
        - No visual indicators on the calendar showing conflicts
    - Add the conflict detection logic and alerts to the notification settings screen.
    - Check `docs/MASTER_ROADMAP.md` and `docs/FEATURE_BACKLOG.md` to determine if this feature was previously planned or implemented.
    - If not implemented, add it to `docs/FEATURE_BACKLOG.md` and prioritize it for a future phase.
    - Design the notification system to provide clear and timely alerts for potential conflicts.
- **User Configuration:**
  - The user would have an option to turn it on.
  - It would be off by default.
  - In the settings, the user would have the option to turn it on.
  - A screen should explain the feature.

- **Settings Screen Implementation**
  - **Location:** Settings → Notifications → "Schedule Conflict Alerts" (already has the toggle)
  - **When User Taps the Toggle:**
    1. **First-time activation** → Show an explanatory screen/dialog:
       - **Title:** "Calendar Conflict Detection"
       - **Explanation:**
         - "This feature checks your personal calendar events (doctor appointments, meetings, family events, etc.) against your work shifts"
         - "If you have a shift scheduled the same day/time as a personal event, you'll get a warning"
         - "This helps you catch scheduling conflicts before they become a problem"
    2. **Permission Request:**
       - "This requires access to read your calendar events"
       - Show what data we access: "We only read event titles, dates, and times - nothing else"
       - Clear "Allow" / "Cancel" buttons
    3. **What Gets Scanned:**
       - Your **imported work shifts** (from Hot Schedules, 7shifts, manual entries, etc.)
       - Your **personal calendar events** (Google Calendar, iOS Calendar, etc.)
       - Looking for time overlaps

- **How Conflict Detection Would Work**
  - **Scenario 1: Direct Time Overlap**
    - Shift: Monday 5:00 PM - 11:00 PM
    - Personal Event: Monday 6:00 PM - Doctor Appointment
    - **Alert:** "⚠️ Conflict detected! You have a doctor appointment at 6 PM during your shift (5-11 PM)"
  - **Scenario 2: Same Day Warning (Less Severe)**
    - Shift: Monday 5:00 PM - 11:00 PM
    - Personal Event: Monday 2:00 PM - Dentist
    - **Alert:** "⚡ Heads up: You have a dentist appointment at 2 PM, then work at 5 PM (tight schedule)"
  - **Scenario 3: All-Day Events**
    - Shift: Tuesday 4:00 PM - 10:00 PM
    - Personal Event: Tuesday (All Day) - "Out of Town"
    - **Alert:** "🚨 Major conflict! You're marked 'Out of Town' all day Tuesday, but have a shift scheduled"

- **Where Would Users See Conflicts?**
  - **Option A: Push Notification (When Feature is On)**
    - Notification: "⚠️ Schedule Conflict: Work shift overlaps with 'Doctor Appointment' on Jan 5"
    - Tap → Opens conflict details screen
  - **Option B: Calendar Screen Visual Indicator**
    - Days with conflicts show a small warning icon (⚠️) on the calendar cell
    - Tap the day → Slide-up modal shows: "This day has a scheduling conflict" with details
  - **Option C: Dedicated Conflicts Screen**
    - New section in Settings or Calendar: "⚠️ 2 Conflicts Detected"
    - List view showing all conflicts with:
      - Date
      - Work shift details (job, time)
      - Personal event details (title, time)
      - Actions: "Dismiss" / "Request shift coverage" / "Reschedule event"

- **Privacy & Data Handling**
  - **Key Points to Emphasize:**
    1. **Off by default** - User opts in
    2. **Local-only processing** - We don't upload personal calendar data to the cloud
    3. **Read-only** - We never modify or delete personal events
    4. **No data storage** - We only check for conflicts in real-time, don't save personal event details
    5. **You can turn it off anytime** - Revoke permission instantly

- **Settings Screen Design**
```
NOTIFICATIONS
├─ Shift Reminders ✓
├─ End-of-Shift Prompts ✓
├─ Schedule Conflict Alerts ⚪ ← User taps here
│  └─ [Tapping opens explanation screen first]
├─ Weekly Summaries ✓
└─ Goal Progress ✓
```
  - **After Enabling:**
```
NOTIFICATIONS
├─ Schedule Conflict Alerts ✓ ON
│  ├─ "Checking your calendar for conflicts"
│  ├─ [View Detected Conflicts] → Shows list
```

### Web Deployment Instructions (NEW - December 31, 2025):

These steps are a **general guide** based on past experiences. Actual deployment may require adjustments.

#### 1. Set the Base Href:

-   Before building for the web, ALWAYS specify the base href:
    ```bash
    flutter build web --release --base-href=/in-the-biz-ai/
    ```
-   This tells the app where it will be hosted.

#### 2. Verify `manifest.json`:

*   Ensure the `web/manifest.json` file exists and is correctly formatted JSON.
*   Double-check the paths to icons.

#### 3. Enable Google Sign-In for Web:

-   In `lib/services/auth_service.dart`, make sure the Google Sign-In logic is correctly implemented for web.
-   Use the correct client ID for web.
*  On web you can't use `authenticate()` - you MUST use the Google button rendered by the SDK.

#### 4. Create a GitHub Repository:

*   Create a new public repository on GitHub (e.g., `in-the-biz-ai`).
*   Do NOT initialize with README, .gitignore, or license.

#### 5. Configure Git:

```powershell
cd "c:\\Users\\Brandon 2021\\Desktop\In The Biz AI"
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/[your-username]/in-the-biz-ai.git
git push -u origin main
```

#### 6. Create and Deploy to `gh-pages` Branch:

```powershell
flutter build web --release --base-href=/in-the-biz-ai/
git checkout -b gh-pages
git add build/web
git commit -m "Deploy web app to GitHub Pages"
git push origin gh-pages --force
```

#### 7. Enable GitHub Pages:

*   Go to your repository settings on GitHub.
*   Navigate to the "Pages" section.
*   Set the source to the `gh-pages` branch.
*   Set the folder to `/build/web`.

#### 8. Test Thoroughly:

*   Access the deployed app via the GitHub Pages URL.
*   Test Google Sign-In.
*   Check for any errors in the browser console.

#### Troubleshooting:

*   **404 Errors:** Double-check the base href, file paths, and GitHub Pages settings.
*   **Google Sign-In Issues:** Ensure the web client ID is correctly configured and that the implementation follows the latest `google_sign_in` package guidelines.
*    **Large File Errors:** Make sure to exclude large files and folders like `node_modules` and `.dart_tool` from the repo.

#### 9. Deploy to Custom Domain (NEW - December 31, 2025):

To deploy to your custom domain `inthebiz.app`, you need to configure GitHub Pages to use that domain:

1.  **Add a CNAME file** to your `gh-pages` branch:
    *   Create a file named `CNAME` (no extension) in the `build/web` directory.
    *   Put one line in it: `inthebiz.app`
    *   Commit and push it

2.  **Update your DNS records** at your domain registrar (Vercel Domains):
    *   Go to your domain settings
    *   Add these CNAME records:
        *   `@` → `munzer221.github.io` (or use the A records GitHub provides if CNAME isn't supported)

3.  **Enable HTTPS** in GitHub Pages:
    *   Go to your repo Settings → Pages
    *   Check "Enforce HTTPS" (after GitHub Pages recognizes your domain)

### Security Rules (NEW - December 31, 2025):

- **NEVER commit `.env` files to Git.** These files contain sensitive API keys and credentials.
- **ALWAYS add `.env` to your `.gitignore` file.** This prevents accidental commits.
- **When creating new API keys, restrict their usage** to only the necessary services (e.g., Generative Language API for Gemini).
- **Rotate API keys immediately** if they are compromised (e.g., accidentally committed to a public repository).
- **Monitor API key usage** in the cloud console to detect suspicious activity.
- **For web deployments, configure Docker Desktop to start automatically** to ensure the Supabase CLI and other tools function correctly.
- **When using Docker on Windows, restart the terminal** after installing Docker Desktop to ensure the Supabase CLI and other tools function correctly.
- **On Windows,