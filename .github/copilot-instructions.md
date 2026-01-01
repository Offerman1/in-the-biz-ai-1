---
description: AI rules derived by SpecStory from the project AI interaction history
globs: *
---

---
description: AI rules derived by SpecStory from the project AI interaction history
---

# In The Biz AI - Copilot Instructions

**Knowledge cutoff:** June 2024
**Current date:** January 1, 2026

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

---

## 🌐 WEBSITE METADATA RULES (NEW - December 31, 2025)

- **When deploying the website, ALWAYS update the `<title>` tag** in the `index.html` file to reflect the correct site name (e.g., "In The Biz").
- **ALWAYS update the Open Graph meta tags** (`og:title`, `og:description`, `og:image`, etc.) in the `index.html` file to ensure correct display when sharing links. This includes:
  - `og:title`: The title of your website
  - `og:description`: A brief description of your website
  - `og:image`: The URL of an image to display when sharing the link
- **Verify the website metadata** after deployment by sharing the link on social media or messaging platforms to ensure it displays correctly.

---

## 🔒 SECURITY RULES (NEW - December 31, 2025):

- **NEVER commit `.env` files to Git.** These files contain sensitive API keys and credentials.
- **ALWAYS add `.env` to your `.gitignore` file.** This prevents accidental commits.
- **When creating new API keys, restrict their usage** to only the necessary services (e.g., Generative Language API for Gemini).
- **Rotate API keys immediately** if they are compromised (e.g., accidentally committed to a public repository).
- **Monitor API key usage** in the cloud console to detect suspicious activity.
- **For web deployments, configure Docker Desktop to start automatically** to ensure the Supabase CLI and other tools function correctly.
- **When using Docker on Windows, restart the terminal** after installing Docker Desktop to ensure the Supabase CLI and other tools function correctly.
- **From now on, don't use Powershell anymore use cmd.**

---

## 🗄️ SUPABASE DATABASE MIGRATIONS (NEW - December 31, 2025)

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
4. Run: `node scripts/run-migration.mjs supabase/migrations/[filename].sql`

### On Windows:

On Windows, configure Docker Desktop to start automatically to ensure the Supabase CLI and other tools function correctly. Restart the terminal after installing Docker Desktop to ensure the Supabase CLI and other tools function correctly.

---

## 🤖 AI VISION FEATURES - UI DESIGN (NEW - December 31, 2025)

This section defines the UI placement strategy for the AI Vision features.

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
    │  What would you like to scan?    │
    ├──────────────────────────────────┤
    │  🧾 BEO (Event Details)          │
    │  📊 Server Checkout              │
    │  💼 Business Card (Contact)      │
    │  📄 Invoice (Future)             │
    │  🧾 Receipt (Future)             │
    └──────────────────────────────────┘
    ```

### 3. Scan Actions

-   **BEO (Event Details):** Extracts event details and auto-fills the shift form.
    *   AI should prompt: "Scan another page?" or "Ready to import?"
    *   Concatenate data from multi-page scans.
-   **Server Checkout:** Extracts financial data and auto-fills the shift form.
    *   Account for variable formats.
    *   Account for multiple pages in a checkout.
    *   Start simple, extract what is consistently available, and improve over time.
    *   Review modal lets user verify/edit extracted data.
-   **Business Card:** Creates/adds to Event Contacts and attaches it to the current shift.
-   **Invoice (Future):** Links to a separate freelancer workflow (not shift-based).
-   **Receipt (Future):** Links to expense tracking for 1099 contractors.

### 4. Implementation Details

-   **BEO Scanner:**
    *   AI should prompt: "Scan another page?" or "Ready to import?"
    *   Concatenate data from multi-page scans.
-   **Server Checkout Scanner:**
    *   Account for variable formats.
    *   Account for multiple pages in a checkout.
    *   Start simple, extract what is consistently available, and improve over time.
    *   Review modal lets user verify/edit extracted data.
-   **Receipt and Invoice:**
    *   These features are for future development.
    *   Build a separate "Invoice/Receipt Tracking" system for 1099 workers.

### 5. Future Considerations

-   **Discovery:**
    *   How do we make users AWARE of these features?
    *   Consider onboarding tooltips or dashboard badges.

---

## 🤖 AI Vision - Server Checkout "Checkout Analyzer" (NEW - December 31, 2025)

### The Vision

Create an amazing checkout system by extracting common POS systems for servers to use, and the AI to analyze all images constantly. The servers could use this app, take a picture of their checkout at the end of every shift, and it would be tracking everything all the time. Probably the 90% of the POS systems that are being used out there, then uses the AI to figure out the other ones that are most likely pretty close, so we'd get pretty much 100 percent of these checkouts into an amazing like checkout system. That the AI would analyze the image and constantly if this server took this picture every single shift of their checkouts, everything would always be tracked, their sales, and their analytics would be incredibly deep.

### Checkout Analyzer - Post-Scan Flow:

```
Scan Photo(s)
    ↓
AI Analyzes
    ↓
VERIFICATION SCREEN
├─ Checkout Preview Card (top)
│  └─ Shows AI's findings in nice stat layout
│
├─ Questions Section (below)
│  ├─ "X questions found"
│  ├─ 2 questions per card (scrollable)
│  └─ Each question has input field + hint text
│
└─ Action Buttons
   ├─ [Approve as-is] (use AI data exactly)
   ├─ [Answer Questions] (fill in blanks, then approve)
   └─ [Discard]
```

### Server Checkout - After Approval:

Data goes to separate `server_checkouts` table.
Shows in "Checkout Analytics" dashboard.
User can later tap "Import into Shift" button.
Auto-imports all applicable data into Add Shift form.
Optional toggle: "Auto-import next time".

### Multi-Photo Support

Some checkouts are long, especially:
High-volume restaurants with 50+ line items
Event catering (multiple covers on one check)
Split checks (some POS systems print multiple pages)
Itemized gratuity receipts (extra pages)

Solution: Same pattern as BEO
User taps "Scan Checkout"
Takes first photo
AI analyzes, asks: "Scan another page?" or "Ready to import?"
If another page → concatenate data
Review modal shows all extracted data combined

### AI Model
- Gemini vision
- trained on those formats + variations

### Priority

High

### Long Term Vision

every shift = automatic checkout scan → auto-tracked data
Over time = incredibly deep server analytics
Competitive moat: No other app does this - HUGE differentiator
AI gets smarter: Each scan trains the system - handles more edge cases
Server becomes a power user: They NEED this app because their data is so valuable

## 🎯 Implementation Strategy

### Phase 6a: Research & Design
Document POS formats
Design the "Checkout Analytics" dashboard
Create AI training data for OCR/parsing

### Phase 6b: Build Checkout Scanner
Scan receipt → Extract fields
Review modal (user confirms/corrects)
Store checkout data with metadata

### Phase 6c: Build Checkout Analytics Dashboard
New tab on Stats screen or separate dashboard
Shows:
Total sales (this week/month/year)
Average sales per shift
Tip % trends
Best earning days/times
Checkout frequency (which shifts logged)
Comparison: "Your sales are up 12% vs last month"

### Phase 6d: Advanced Analytics (Later)
Correlate checkout data with shifts
Show "On shifts with high sales, your tip % is X"
Predict peak earning shifts
Seasonal trends

### POS Systems Analysis

Document popular POS systems, as well as what data those systems can provide.

**Systems to Research:**

Toast (Hospitality focused)
Square (Small business)
Aloha/Oracle Micros (Enterprise)
Micros (Legacy, still widely used)
Clover (Square competitor)
TouchBistro (iPad-based)
Lightspeed (Retail/Restaurant)
Handwritten (Manual receipts)

## 👍 Extraction Priorities (MVP)
Date, Total Sales Amount, Tip (if present), Payment Method, Server name (if present)

## 📝 Real World Challenges

### Challenge 1: Inconsistent Data Across POS Systems

Solution Options:
Extract whatever is available and mark confidence level
Ask user in review modal if data looks wrong

### Challenge 2: Ambiguous Totals

Solution Options:
Always extract subtotal (before tax) as sales
Extract both subtotal AND total, let user choose

### Challenge 3: Handwritten Tips

Solution Options:
Skip tip extraction if handwritten, let user type it
Try OCR but mark as low confidence

### Challenge 4: Faded/Old Receipts

Solution Options:
Try to extract anyway, marks low confidence
Show user the original photo in review modal so they can manually verify/correct extracted data.

### Challenge 5: Multiple Checkouts on One Receipt

Solution Options:
Warn user in modal if we detect multiple server names or table numbers. User can manually edit to match their specific check.

### Challenge 6: Currency & International Formats

Solution Options:
Only support USD

### Challenge 7: Service Charge vs. Tip

Solution Options:
Extract service charge separately, show user in review modal with label "Service Charge (likely deducted from your tips)". User can move it to additional_tipout field if it's a house fee.

### Challenge 8: Date Format Variations

Solution Options:
Gemini is good at date detection. Extract it, but show user the parsed date in modal for confirmation (especially for YY ambiguity).

### Challenge 9: Time Information (or Lack Thereof)

Solution Options:
Most users will already know what shift they worked. Show them the date, they fill in the time manually in the form.

### Challenge 10: Confidence Scoring & User Trust

Solution Options:
Show confidence badges (Green checkmark for high confidence, Yellow warning for medium, Red X for low). Always show original photo so user can verify.

### Questions UI

Users can skip unanswered questions, unless there's required ones. If you're not sure about it for sure. If you have a low confidence, for sure you need to ask, but. They shouldn't be required to answer every question to complete it. If they want to leave some unanswered, that's their choice?

### Question Cards

It depends how much screen space we have. I suppose if we make them small enough you could do 3 or 4.

### Service Charge Classification

You should definitely have the question cards like Server charge classification for sure if you don't know it.

### Checkout Analytics

Should be on the stats screen. May want to have a toggle button somewhere where they can include server checkout tracking into overall analytics. Or keep it separate. In its own screen. Start out as its own tab. And then they can choose to include with Shift Analytics.

## 📝 Data Storage

### New Database Table: server_checkouts

```sql
CREATE TABLE public.server_checkouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Extracted Data from Receipt
  checkout_date DATE NOT NULL,
  checkout_time TIME,  -- If available on receipt, else NULL

  sales_amount DECIMAL(10, 2),
  tax_amount DECIMAL(10, 2),
  tips_amount DECIMAL(10, 2),
  service_charge DECIMAL(10, 2),
  total_amount DECIMAL(10, 2),

  -- Context Information
  server_name TEXT,
  table_number TEXT,
  covers INT,
  pos_system TEXT,  -- "Toast", "Square", "Aloha", "Clover", etc.

  -- AI Metadata
  ai_confidence_scores JSONB,  -- { "tips": 0.45, "sales": 0.95, ... }
  ai_notes TEXT,  -- "Handwritten tip, unclear" or system notes
  overall_confidence DECIMAL(3, 2),  -- Average confidence (0.0-1.0)

  -- User Verification
  user_verified BOOLEAN DEFAULT FALSE,
  user_verified_at TIMESTAMPTZ,
  user_adjustments JSONB,  -- What user changed: { "tips": "95.00", "server_name": "John" }
  user_questions_answered JSONB,  -- Answers to verification questions

  -- Images (Multi-page Support)
  image_urls TEXT[] NOT NULL,  -- Array of photo URLs
  image_count INT,  -- Number of pages scanned

  -- Linking
  linked_shift_id UUID REFERENCES shifts(id) ON DELETE SET NULL,  -- If user imported to shift

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_server_checkouts_user ON public.server_checkouts(user_id);
CREATE INDEX idx_server_checkouts_date ON public.server_checkouts(checkout_date);
CREATE INDEX idx_server_checkouts_verified ON public.server_checkouts(user_verified);
```

### No Changes to Shifts Table (MVP)

MVP keeps shifts table unchanged. In Phase 2 (v1.1), we can add:

```sql
ALTER TABLE public.shifts ADD COLUMN (
  source_checkout_id UUID REFERENCES server_checkouts(id)  -- Track origin if imported
);
```

---

## 🎯 Post-Scan Verification Flow

### User Journey After Scanning

```
1. User scans checkout receipt(s)
   ↓
2. AI analyzes (possibly multi-page)
   ↓
3. VERIFICATION SCREEN APPEARS
   ├─ Checkout Preview Card (top)
   │  └─ Shows all extracted data with confidence badges
   │
   ├─ Questions Section (scrollable)
   │  ├─ "X questions need your help"
   │  ├─ 2-4 questions per view (responsive layout)
   │  └─ Each question has input field + hint text
   │
   └─ Action Buttons
      ├─ [Approve as-is] (skip unanswered questions)
      ├─ [Answer Questions] (fill in blanks)
      └─ [Discard]
   ↓
4. Data saved to server_checkouts table
   ↓
5. Optional: User can "Import to Shift" later
```

### Checkout Preview Card

**Layout:**

```
┌─────────────────────────────────────┐
│ 🧾 CHECKOUT PREVIEW                 │
├─────────────────────────────────────┤
│  Sales:        $450.00               │
│  Tax:          $38.25                │
│  Tips:         $95.00   ⚠️ Unclear   │
│  Service Chg:  $0.00   ✅ Clear      │
│  ───────────────────────────────────│
│  TOTAL:        $583.25               │
│                                      │
│  Server: John Smith   Table: 8       │
│  Date: 12/31/2025     Covers: 4      │
│  POS: Toast                          │
│                                      │
│  ✓ High Confidence (5/8 fields)      │
└─────────────────────────────────────┘
```

**Confidence Badges:**
- ✅ Green: High confidence (>80%)
- ⚠️ Yellow: Medium confidence (50-80%)
- ❌ Red: Low/Failed (could not extract)

### Question Card Examples

**Simple Input Question:**

```
┌─────────────────────────────────────┐
│ ❓ What was your tip amount?         │
│    I found $95, but it was unclear   │
│                                      │
│ [_____________________]              │
│  Hint: E.g., $100 or 95.50          │
└─────────────────────────────────────┘
```

**Multiple Choice Question:**

```
┌─────────────────────────────────────┐
│ ❓ Was service charge a house fee?   │
│    Found: Service Charge $15         │
│                                      │
│ [ ] Yes, deduct from my tips         │
│ [ ] No, it's part of my pay          │
│ [ ] Not sure                         │
└─────────────────────────────────────┘
```

**Questions Always Optional:**
- Users CAN skip unanswered questions
- No required fields (user choice)
- Can edit verification data later if needed

---

## 🎯 Implementation Strategy

### Phase 6a: UI Foundation (Week 1)
- [ ] Add ✨ Scan button icon to Add Shift header
- [ ] Add Scan button to Edit Shift header
- [ ] Add Scan button to Shift Details header
- [ ] Create bottom sheet menu component with options:
  - [ ] 🧾 BEO (Event Details)
  - [ ] 📊 Server Checkout
- [ ]