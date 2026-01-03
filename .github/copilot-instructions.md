---
description: AI rules derived by SpecStory from the project AI interaction history
globs: *
---

---
description: AI rules derived by SpecStory from the project AI interaction history
---

# In The Biz AI - Copilot Instructions

**Knowledge cutoff:** June 2024
**Current date:** January 3, 2026

**These instructions are automatically applied to every Copilot chat session.**

---

## 📝 DOCUMENTATION RULE

**CRITICAL:** Do NOT add implementation details, feature summaries, or "how things work" documentation to these copilot instructions.

**Where to document instead:**
- **Feature completion:** Update `docs/MASTER_ROADMAP.md`
- **Implementation guides:** Add to relevant phase docs in `docs/phases/`
- **New features:** Document in `docs/FEATURE_BACKLOG.md` (if not started) or roadmap (if completed)
- **Technical specs:** Create dedicated docs in `docs/` folder
- **App Store Submission:** Create `docs/APP_STORE_SUBMISSION_GUIDE.md` and `docs/GOOGLE_PLAY_SUBMISSION_GUIDE.md`
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

## 🔐 GOOGLE PLAY & REVENUECAT API ACCESS (NEW - January 3, 2026)

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

**What the AI can do automatically:**
- ✅ Create subscription products in Google Play Console
- ✅ Upload app bundles (.aab files) to internal testing
- ✅ Create releases on internal testing track
- ✅ Test API authentication
- ✅ List existing subscriptions
- ✅ Verify service account permissions
- ✅ Extract tester emails from Supabase database

**IMPORTANT:** Always ASK the user before uploading a release. Do NOT automatically run `upload-release.mjs` without explicit confirmation. The script is available but should only be used when user explicitly requests deployment.

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

### RevenueCat API

**API Keys stored in `.env`:**
- `REVENUECAT_SECRET_KEY` - V2 Secret Key (starts with `sk_`)\n- `REVENUECAT_PUBLIC_KEY` - Public SDK key (starts with `goog_`)\n
**Project Info:**\n- **Project ID:** &#96;proj42034829&#96;\n- **App ID:** &#96;app9cc9915545&#96;\n
**Available Script:**\n&#96;&#96;&#96;cmd\n# Automatically configure RevenueCat (products, entitlements, offerings)\nnode scripts/setup-revenuecat-complete.mjs\n&#96;&#96;&#96;\n
**What the AI can do automatically:**\n- ✅ Create products in RevenueCat\n- ✅ Create entitlements\n- ✅ Create offerings and packages\n- ✅ Attach products to entitlements\n- ✅ Configure complete subscription setup\n
**Current Configuration:**\n- **Products:** &#96;pro_monthly:monthly-plan&#96; ($4.99/mo), &#96;pro_yearly:yearly-plan&#96; ($49.99/yr)\n- **Entitlement:** &#96;pro&#96;\n- **Offering:** &#96;default&#96; with packages &#96;monthly&#96; and &#96;annual&#96;\n
**When user asks to modify subscriptions:**\n1. Use the appropriate script to make changes via API\n2. Do NOT ask user to manually configure things in dashboards
3. Both Google Play and RevenueCat can be managed programmatically

---

## 💻 TERMINAL & SHELL RULES (NEW - January 1, 2026)

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

## 🌐 WEB DEPLOYMENT TO GITHUB PAGES (CRITICAL - January 1, 2026)

**IMPORTANT:** GitHub Pages serves files from the **ROOT** of the gh-pages branch, NOT from `build/web/` folder.

### Correct Automated Deployment with GitHub Actions (UPDATED - January 1, 2026)

**Current setup:**
- Source code on `main` branch (lib/, pubspec.yaml, etc.)
- Built files on `gh-pages` branch (auto-generated by GitHub Actions)
- GitHub Pages serves from `gh-pages` branch root

**Workflow:**
1. Make changes in VS Code
2. Commit and push to `main` (or click "Sync Changes" button)
3. GitHub Actions automatically builds and deploys to `gh-pages`
4. Changes are live at inthebiz.app in ~2-3 minutes

**GitHub Actions Configuration:**

1.  **Workflow File:** Ensure a workflow file named `.github/workflows/deploy.yml` exists in your repository.
2.  **Workflow Configuration:**

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout main branch
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.5' # Use current Flutter version
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Build web
        run: flutter pub get

      - name: Build web
        run: flutter build web --release --base-href /

      - name: Deploy to gh-pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
          publish_branch: gh-pages
          cname: inthebiz.app
```

3.  **Update Flutter Version:** Ensure the `flutter-version` in the workflow file matches your current Flutter version. Check your local Flutter version by running `flutter --version` in the terminal.
4.  **Set Workflow Permissions:**
    -   Go to your repository settings: `https://github.com/munzer221/in-the-biz-ai/settings/actions`
    -   Scroll down to **"Workflow permissions"**
    -   Select **"Read and write permissions"**
    -   Check the box for **"Allow GitHub Actions to create and approve pull requests"**
    -   Click **Save**
5.  **Verify GitHub Pages Settings:**
    -   Go to: `https://github.com/munzer221/in-the-biz-ai/settings/pages`
    -   Make sure it's set to:
        -   **Source:** Deploy from a branch
        -   **Branch:** `gh-pages` / `/ (root)`

**Troubleshooting:**

*   **Deployment Fails:** Check the GitHub Actions logs for error messages. Common issues include incorrect Flutter version or missing permissions.
*   **Permissions Error:** If the deployment fails with a permission error, ensure that the workflow has "Read and write permissions" as described above.

### ALTERNATIVE: Correct Manual Deployment with robocopy

Due to issues with automated deployment, manual deployments remain the primary method.

**Source:**
- Code in the root of the gh-pages branch

**Deployment Steps:**

1.  **Build**: From the project root, build the web app:
    ```powershell
    flutter build web
    ```

2.  **Copy to Root**: Copy the contents of `/build/web` to the root directory, EXCLUDING the `build` directory itself (to avoid infinite loops). Use robocopy with proper exclusions to prevent accidental commits of node_modules, .git folder, etc.:

```powershell
robocopy "c:\Users\Brandon 2021\Desktop\In The Biz AI\build\web" "c:\Users\Brandon 2021\Desktop\In The Biz AI" *.* /E /XD build /XD .git /XD node_modules /XD android /XD ios /XD lib /XD docs /XD scripts /XD supabase /XD .idea /XD .vscode /XD .github /XD assets /XD web /XD .specstory /XD .dart_tool
```

*Note: Using robocopy is essential to prevent accidentally deleting files in the root directory.*

3.  **Commit and Push**: Commit all the changes and push them to the `gh-pages` branch.

```powershell
git add *.js *.html *.json .last_build_id flutter_bootstrap.js flutter_service_worker.js
git commit -m "Deploy: Web files in root for GitHub Pages"
git push origin gh-pages
```

### ALTERNATIVE: Automated Deployment with GitHub Actions (OLD INSTRUCTIONS)
~~Due to the current repository structure, where both source code and built files reside in the `gh-pages` branch root, GitHub Actions cannot be directly used for automated deployment without potentially destroying the source code.~~

~~To enable automated deployments with GitHub Actions, refactor the repository structure:~~

~~1.  **Move Source Code to `main` Branch:** Create a new `main` branch and move all source code (lib/, pubspec.yaml, etc.) to this branch.~~
~~2.  **Keep `gh-pages` for Built Files Only:** Ensure the `gh-pages` branch only contains the built web files.~~
~~3.  **Configure GitHub Actions:** Set up a workflow to automatically build the Flutter web app from the `main` branch and deploy the built files to the `gh-pages` branch.~~

~~Once the repository structure is refactored, follow these steps to set up GitHub Actions:~~

~~1.  **Create a GitHub Actions Workflow File:** Create a new file named `.github/workflows/deploy.yml` in your repository.~~
~~2.  **Add the Following Configuration:**~~

```yaml
# name: Deploy to GitHub Pages
#
# on:
#   push:
#     branches:
#       - main
#
# jobs:
#   build-and-deploy:
#     runs-on: ubuntu-latest
#
#     steps:
#       - name: Checkout main branch
#         uses: actions/checkout@v4
#
#       - name: Setup Flutter
#         uses: subosito/flutter-action@v2
#         with:
#           flutter-version: '3.38.5' # Use current Flutter version
#           channel: 'stable'
#
#       - name: Install dependencies
#         run: flutter pub get
#
#       - name: Build web
#         run: flutter pub get
#
#       - name: Build web
#         run: flutter build web --release --base-href /
#
#       - name: Deploy to gh-pages
#         uses: peaceiris/actions-gh-pages@v3
#         with:
#           github_token: ${{ secrets.GITHUB_TOKEN }}
#           publish_dir: ./build/web
#           publish_branch: gh-pages
#           cname: inthebiz.app
```

~~3.  **Update Flutter Version:** Ensure the `flutter-version` in the workflow file matches your current Flutter version. Check your local Flutter version by running `flutter --version` in the terminal.~~
~~4.  **Set Workflow Permissions:**~~
    -   ~~Go to your repository settings: `https://github.com/munzer221/in-the-biz-ai/settings/actions`~~
    -   ~~Scroll down to **"Workflow permissions"**~~
    -   ~~Select **"Read and write permissions"**~~
    -   ~~Check the box for **"Allow GitHub Actions to create and approve pull requests"**~~
    -   ~~Click **Save**~~
~~5.  **Commit and Push:** Commit the changes to the `main` branch and push them to the remote repository.~~
~~6.  **Verify GitHub Pages Settings:**~~
    -   ~~Go to: `https://github.com/munzer221/in-the-biz-ai/settings/pages`~~
    -   ~~Make sure it's set to:~~
        -   ~~**Source:** Deploy from a branch~~
        -   ~~**Branch:** `gh-pages` / `/ (root)`~~

~~After completing these steps, GitHub Actions will automatically build and deploy your Flutter web app to GitHub Pages whenever you push changes to the `main` branch.~~

---

## 🚀 VERCEL DEPLOYMENT (OPTIONAL - NOT CURRENTLY USED)

**The project now uses GitHub Actions for automated deployment to GitHub Pages. Vercel setup is available as an alternative but is not currently active.**

### Current Deployment Method:
- **Active:** GitHub Actions → GitHub Pages
- **Deprecated:** Manual Vercel deployment
- **Reason:** GitHub Actions provides seamless automated deployment without requiring manual builds

### Vercel Configuration Files (Present but Inactive):
- `vercel.json` - Vercel configuration
- `.vercelignore` - Files to exclude from Vercel deployment
- `deploy-vercel.bat` - Manual deployment script

### If Switching to Vercel:
Vercel cannot auto-build Flutter apps natively, so it would still require either:
1. Manual local builds + `vercel --prod` deployment
2. GitHub Actions to build + deploy to Vercel

**Recommendation:** Continue using the current GitHub Actions + GitHub Pages setup for simplicity.

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
4. Run: `node scripts/run-migration.mjs supabase/migrations/[filename].sql]`

### On Windows:

On Windows, configure Docker Desktop to start automatically to ensure the Supabase CLI and other tools function correctly. Restart the terminal after installing Docker Desktop to ensure the Supabase CLI and other tools function correctly.

---

## 🤖 AI VISION FEATURES - UI DESIGN (UPDATED - January 2, 2026)

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
    │  What would you like to scan?    │