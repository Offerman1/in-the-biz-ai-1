# 🗺️ In The Biz AI - Master Roadmap

**Project Goal:** Build the ultimate AI-powered financial companion for the service industry.

**Last Updated:** December 27, 2025

---

## 💰 MONETIZATION OVERVIEW

**Full Strategy:** See [MONETIZATION_STRATEGY.md](./MONETIZATION_STRATEGY.md)

**Business Model:**
- **Free Tier:** Ad-supported (strategic video ads, no banners) with hard limits
- **Pro Tier:** $4.99/month - Remove ads, unlimited features
- **Target Conversion:** 15-20% Free → Pro

**Key Metrics (1000 users, 15% conversion):**
- Monthly Revenue: $987
- Monthly Costs: $129
- Monthly Profit: **$858**
- Annual Profit: **$10,296**
- **Blended Average: $0.86/user/month**

**Cost Structure (REALISTIC):**
- Free user: $0.078/month (storage + AI, bandwidth FREE until 30K users)
- Pro user: $0.42/month (unlimited features)
- Ad revenue: $0.28/month per free user (15 shifts/month avg)

**Critical Insight - Bandwidth is FREE:**
- Supabase includes 250GB bandwidth/month
- Realistic usage: 7.5MB/user/month (75 photo views @ 100KB thumbnails)
- Stays FREE until 30,000+ users
- **NOT a cost concern until massive scale**

**Simple Optimizations:**
- Collapsible photo sections (load only when expanded)
- Thumbnails-first loading (100KB, not 3MB)
- Smart AI routing (Flash-Lite for simple queries)

---

## 🚨 HONEST AUDIT (Last Updated: December 27, 2025)

### ✅ ACTUALLY BUILT & WIRED (Working Now):
| Feature | Status | Notes |
|---------|--------|-------|
| Flutter project running | ✅ Complete | Web, iOS, Android |
| Dashboard with summary card | ✅ Complete | Shows total income, hours, tips |
| **Dashboard goal progress** | ✅ Complete | Hero card shows weekly goal progress bar |
| **Dashboard goals icon** | ✅ **NEW** | Yellow flag icon navigates to Goals screen |
| Add Shift form (manual entry) | ✅ Complete | All fields, job types, time pickers |
| **Dynamic Add Shift** | ✅ **NEW** | Collapsible sections based on job template |
| Shift list on dashboard | ✅ Complete | With totals display |
| Camera screen UI | ✅ Complete | Take photo or gallery picker |
| Analytics/Stats screen | ✅ Complete | Monthly breakdown, weekly bars, best days, fl_chart |
| AI Assistant chat screen | ✅ Complete | Chat UI with photo attachment options |
| Calendar screen | ✅ Complete | Month/Week/Year views, shift markers |
| Bottom navigation | ✅ Complete | Home, Calendar, Chat, Stats tabs |
| Login screen | ✅ Complete | Google Sign-In + Email/Password |
| Dark theme | ✅ Complete | AppTheme with green accent |
| **Supabase Edge Functions** | ✅ **DEPLOYED** | chat + analyze-image |
| **Gemini 3 Flash Preview** | ✅ **CONNECTED** | AI chat working! |
| **AI Vision (Image Analysis)** | ✅ **CONNECTED** | BEO/Receipt scanning working! |
| **Supabase Auth** | ✅ Complete | Google OAuth + Email auth |
| **Supabase PostgreSQL** | ✅ Complete | shifts, jobs, goals, user_settings tables |
| **Storage Bucket** | ✅ Complete | shift-photos bucket configured |
| Database migrations | ✅ Complete | 6 migration files |
| **Charts/Graphs** | ✅ Complete | fl_chart: Bar, Line, Pie charts |
| **Photo Attachments** | ✅ Complete | Gallery grid, full-screen viewer |
| **Multi-job support** | ✅ Complete | Multi-select in onboarding + employer field |
| **Goal setting** | ✅ **REBUILT** | Full goals screen with 4 types + per-job goals |
| **Tax estimation** | ✅ Complete | TaxService + Settings UI with state selector |
| **Export reports (CSV/PDF)** | ✅ Complete | ExportService + Stats export button |
| **Industry templates** | ✅ Complete | 9 industries with full customization |
| **User settings** | ✅ Complete | UserSettings model for preferences |
| **AI Actions Service** | ✅ Complete | 15+ actions AI can perform |
| **AI Context Awareness** | ✅ Complete | Chat sends user data context to AI |
| **Onboarding flow** | ✅ **REBUILT** | 6-page wizard with template customization |
| **Settings screen** | ✅ Complete | Editable jobs with employer, clickable list |
| **Add Job options** | ✅ **NEW** | Choice: Guided Setup vs Quick Add |
| **Job picker in forms** | ✅ Complete | "My Job" chips at top of Add Shift |
| **Event name field** | ✅ Complete | Prominent field with AI query hint |
| **Start/End time** | ✅ Complete | Time pickers with auto-calculate hours |
| **Review Screen** | ✅ Complete | Editable AI verification with all fields |
| **Calendar Sync** | ✅ Complete | Import shifts from Hot Schedules, 7shifts, etc. via device calendar |

### 🆕 NEW FEATURES (December 27, 2025):
| Feature | Status | Notes |
|---------|--------|-------|
| **Sales Tracking** | ✅ **NEW** | Track total sales per shift for tip % analysis |
| **Tip Out System (Sales-Based)** | ✅ **NEW** | Calculate tip out as % of sales, not tips |
| **Additional Tip Out** | ✅ **NEW** | Track extra cash (e.g., $20 to dishwasher) |
| **Tip Out Notes** | ✅ **NEW** | Record who received additional tipout |
| **Event Cost Tracking** | ✅ **NEW** | Track event value for DJs, planners ($10K wedding, etc.) |
| **Net Tips Calculation** | ✅ **NEW** | Auto-calculate net tips after all tipouts |
| **Tip % on Sales** | ✅ **NEW** | Real-time calculation of tip percentage on sales |
| **Job Default Tip Out %** | ✅ **NEW** | Set default tip out % on job (auto-fills in shifts) |
| **Dashboard Net Tips** | ✅ **NEW** | Shows gross tips - tipout = net tips |
| **Tip Out Breakdown** | ✅ **NEW** | Detailed breakdown in shift form (from sales + additional) |

### 🆕 NEW FEATURES (December 26, 2025):
| Feature | Status | Notes |
|---------|--------|-------|
| **Full Goals Screen** | ✅ **NEW** | 2 tabs: Overall & Per Job |
| **Daily/Weekly/Monthly/Yearly Goals** | ✅ **NEW** | Toggle on/off each type with custom amount |
| **Per-Job Goals** | ✅ **NEW** | Set weekly/monthly goals for individual jobs |
| **Goal Progress Tracking** | ✅ **NEW** | Progress bars, percentages, celebration badges |
| **6-Page Onboarding** | ✅ **NEW** | Welcome → Industry → Jobs → Template → Goals → Review |
| **Template Customization Page** | ✅ **NEW** | Pay structure, field toggles (tips, commission, mileage, etc.) |
| **Multi-Goal Onboarding** | ✅ **NEW** | Set daily/weekly/monthly/yearly during setup |
| **Reusable Onboarding** | ✅ **NEW** | isFirstTime param for first-time vs add-job modes |
| **Add Job Choice Modal** | ✅ **NEW** | Bottom sheet: Guided Setup vs Quick Add |
| **Dynamic Add Shift Screen** | ✅ **NEW** | Collapsible sections based on job template |
| **Goals Dashboard Icon** | ✅ **NEW** | Yellow flag icon next to Add button |
| **Hourly Rate Manual Input** | ✅ **NEW** | Text field + slider in onboarding |

### 🆕 FEATURES FROM (December 25, 2025 - Evening):
| Feature | Status | Notes |
|---------|--------|-------|
| **Multi-job onboarding** | ✅ Complete | Select multiple roles with individual rates |
| **Custom roles in chips** | ✅ Complete | Custom jobs appear as selectable chips |
| **Goal manual input** | ✅ Complete | Text field + slider for precise goal amounts |
| **Onboarding confirmation** | ✅ Complete | Summary screen before completing setup |
| **Dashboard goal tracking** | ✅ Complete | Weekly goal progress in hero card |
| **Editable jobs** | ✅ Complete | Click jobs in settings to edit |
| **Employer field** | ✅ Complete | Track which employer for each job |
| **Updated industries** | ✅ Complete | Restaurant/Bar/Nightclub merged, Healthcare & Fitness added |
| **Enhanced time pickers** | ✅ Complete | Green/red icons, auto-calculate badge |
| **Editable review modal** | ✅ **NEW** | Edit AI-extracted data before saving |
| **App Icon** | ✅ **NEW** | ITB tip jar icon for iOS/Android/Web |

### ❌ NOT BUILT (Still Needed):
| Feature | Status | Priority |
|---------|--------|----------|
| Dark mode toggle | ❌ NOT BUILT (always dark) | 🟢 LOW |
| Paywall/Monetization | ❌ NOT BUILT | 🔴 HIGH |
| Voice memos | ❌ NOT BUILT | 🟢 LOW |
| Year-over-year comparison UI | ❌ NOT BUILT | 🟡 MEDIUM |

> **Note:** Voice Input (speech-to-text) is NOT needed - phones have this built into keyboards.
> **Note:** Hot Schedules API is NOT available to third-party apps. Using Calendar Sync instead - users enable "Sync to Calendar" in Hot Schedules/7shifts/etc, then our app imports from device calendar.

---

## 📦 Tech Stack

| Component | Technology | Status |
| :--- | :--- | :--- |
| **Frontend** | Flutter (iOS, Android, Web) | ✅ Working |
| **Chat AI** | Gemini 3 Flash Preview | ✅ **CONNECTED** |
| **Vision AI** | Gemini 3 Flash Preview | ✅ **CONNECTED** |
| **Local Database** | SharedPreferences (fallback) | ✅ Working |
| **Cloud Database** | Supabase PostgreSQL | ✅ **CONNECTED** |
| **Backend** | Supabase Edge Functions | ✅ **DEPLOYED** |
| **Authentication** | Supabase Auth (Google + Email) | ✅ **WORKING** |
| **Storage** | Supabase Storage (shift-photos) | ✅ Configured |
| **AI Actions** | AiActionsService | ✅ **BUILT** |

---

## 🎯 Current Progress

**Last Updated:** December 27, 2025

### ✅ COMPLETED (December 27, 2025)
- **Sales tracking system** - Track total sales per shift for accurate tip % analysis
- **Corrected tip out system** - Calculate tip out as % of sales (industry standard)
- **Additional tip out field** - Track extra cash given beyond percentage
- **Tip out notes** - Record who received additional tipout (e.g., "Dishwasher", "Holiday bonus")
- **Event cost tracking** - Track total event value for DJs, planners, event workers
- **Net tips calculation** - Auto-calculate: (gross tips) - (sales × tipout% + additional) = net tips
- **Tip % on sales** - Real-time display of tip percentage based on sales amount
- **Job default tip out** - Set default tip out % on job, auto-fills in shift form
- **Dashboard net tips** - Shows tip breakdown: gross - tipout = net
- **Tip out breakdown UI** - Detailed summary card showing all tip calculations
- **Database migrations (2)** - Added sales_amount, tipout_percent, additional_tipout, additional_tipout_note, event_cost
- **Onboarding updates** - Added Sales Amount and Event Cost toggles to template customization
- **AI-Enhanced Import System** - CSV/Excel upload with Gemini 3 Flash Preview smart mapping, preview UI, batch import, edge function deployed (`analyze-import`)

### ✅ COMPLETED (December 26, 2025)
- **Full Goals Screen rebuild** - 2 tabs (Overall / Per Job), all 4 goal types
- **Daily/Weekly/Monthly/Yearly goals** - Toggle on/off each type
- **Per-job goals** - Set weekly/monthly goals for individual jobs
- **6-page onboarding wizard** - Welcome, Industry, Jobs, Template, Goals, Review
- **Template customization page** - Pay structure, field toggles by section
- **Reusable onboarding** - isFirstTime param, skip buttons, returns to Settings
- **Add Job choice modal** - Guided Setup vs Quick Add options
- **Dynamic Add Shift screen** - Collapsible sections based on job template
- **Goals icon on dashboard** - Yellow flag button next to Add button
- **Hourly rate manual input** - Text field + slider in onboarding

### ✅ COMPLETED (December 25, 2025 - Evening)
- **Enhanced onboarding flow** - Now 6 pages with multi-job selection
- **Multi-job selection** - Select Server, Bartender, Manager all at once
- **Individual hourly rates** - Each selected job gets its own rate slider
- **Custom jobs in chips** - Added custom roles appear as selectable options
- **Goal manual input** - Text field below slider for exact amounts
- **Confirmation screen** - Summary of choices before completing onboarding
- **Dashboard goal progress** - Weekly goal shown in hero card with progress bar
- **Editable jobs in settings** - Click any job to edit name, rate, employer
- **Employer field** - Track which restaurant/company for each job
- **Updated industries** - Restaurant/Bar/Nightclub combined, Healthcare & Fitness added
- **Database migration** - Added employer column to jobs table

### ✅ COMPLETED (December 25, 2025 - Earlier)
- Multi-job support (Job model + DB + Settings UI + Form picker)
- Goal setting (Goal model + DB + Goals Screen)
- Tax estimation (TaxService + Settings UI with all 50 states)
- Export service (CSV + PDF + Stats export button)
- Industry templates (now 9 industries)
- User settings model
- AI Actions Service (15+ actions)
- AI Context awareness (chat sends user data)
- Onboarding flow (now 6 screens + main.dart integration)
- Settings screen (Jobs, Goals, Tax, Account)
- **Job picker chips** in Add Shift form (loads user's jobs)
- **Event name field** prominent with AI query hint
- **Review screen** - Editable AI verification modal with all fields
- **Hostess/guest count fields** - Optional event details in Add Shift
- **Start/End time pickers** - With auto-calculate hours indicator
- 6 database migrations applied

### 🔴 NOT STARTED
- Monetization/Paywall
- Voice memos recording
- App store preparation

---

## 🚀 Phase Tracking

| Phase | Description | Status | Link |
| :--- | :--- | :--- | :--- |
| **Phase 1** | **Foundation & Setup** | ✅ Complete | [View Checklist](phases/PHASE_1_FOUNDATION.md) |
| **Phase 2** | **Core Data & Input** | ✅ Complete | [View Checklist](phases/PHASE_2_DATA_INPUT.md) |
| **Phase 3** | **AI Vision & Camera** | ✅ **Complete** | [View Checklist](phases/PHASE_3_AI_VISION.md) |
| **Phase 4** | **Analytics & Calendar** | ✅ **Complete** | [View Checklist](phases/PHASE_4_ANALYTICS.md) |
| **Phase 5** | **AI Assistant** | ✅ **Complete** | [View Checklist](phases/PHASE_5_ASSISTANT.md) |
| **Phase 6** | **Polish & Monetization** | 🟡 In Progress | [View Checklist](phases/PHASE_6_POLISH.md) |
| **Phase 7** | **AI-Enhanced Onboarding** | 📋 Planned Q1 2026 | [AI Import Spec](AI_ENHANCED_IMPORT_SYSTEM.md) |
| **Phase 8** | **AI Vision Extensions** | 📋 Planned Q2 2026 | [AI Vision Spec](AI_VISION_FEATURES.md) |

---

## 🚀 NEW AI FEATURES - Q1-Q2 2026

### Phase 7: AI-Enhanced Import System ✅ COMPLETE (December 27, 2025)
📋 **Full Specification:** [AI_ENHANCED_IMPORT_SYSTEM.md](AI_ENHANCED_IMPORT_SYSTEM.md)

**Status:** ✅ DEPLOYED & LIVE  
**Cost:** $0.01-0.02 per user onboarded (one-time)

**What It Does:**
- CSV/Excel upload from old tip tracking apps
- AI column mapping using Gemini 3 Flash Preview
- Smart synonym detection ("Wage" = hourly_rate)
- Preview with confidence scores before import
- Batch import 700+ shifts in 30 seconds
- Developer analytics on unmapped fields

**Implementation:**
- ✅ Edge function deployed: `analyze-import`
- ✅ Settings screen integration ("Import Shift Data" button)
- ✅ Database migration applied (import_analytics table)
- ✅ API service method added
- ✅ Error handling and validation

**Expected Impact:**
- +35-50% first-week retention improvement
- Word-of-mouth marketing tool
- Product insights via unmapped field analysis

---

### Phase 8: AI Vision Extensions (Q2 2026)
📋 **Full Specification:** [AI_VISION_FEATURES.md](AI_VISION_FEATURES.md)

**Priority:** HIGH (Server Checkout) + MEDIUM (Invoice Import)  
**Timeline:** 5-7 days total  
**Cost:** $0.001-0.002 per scan (recurring)

#### 8A: Server Checkout Sheet Reader
**What It Does:**
- Scan restaurant checkout sheets (photo)
- Extract: Total Sales, Tipout, Net Tips, etc.
- Handle different formats (Aloha, Toast, Square, handwritten)
- Auto-fill shift form
- Error reporting for unknown formats

**Impact:** 90% reduction in data entry time (5 min → 30 sec)

#### 8B: Invoice Import for Freelancers
**What It Does:**
- Scan invoices/receipts (photo/PDF)
- Extract: Client, Amount, Date, Service
- Create shift entry with "Pending Payment" status
- Payment tracking dashboard
- Overdue alerts

**Impact:** Expands TAM to freelancers, higher LTV users

**Both Features Use:** Gemini 3 Flash Preview with vision ($0.50/$3.00 per 1M tokens)

---

## 🔧 Backend Architecture (COMPLETE)

```
┌─────────────────┐     ┌─────────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│  Supabase Edge Fn   │────▶│   Gemini API    │
│  (User's Phone) │     │  (API Key Secure)   │     │   (Google)      │
└─────────────────┘     └─────────────────────┘     └─────────────────┘
```

**Endpoints DEPLOYED:**
1. ✅ `POST /analyze-image` - Accepts base64 image, returns extracted data (Gemini 3 Flash Preview)
2. ✅ `POST /chat` - Accepts user message + context, returns AI response (Gemini 3 Flash Preview)

---

## 🤖 AI Actions Available

The AI assistant can now perform these actions:
| Action | Description |
|--------|-------------|
| `get_shifts` | Get shifts by date range |
| `get_total_income` | Calculate income for period |
| `get_shifts_by_job` | Filter shifts by job |
| `get_party_income` | Find income by event/party name |
| `add_shift` | Create a new shift |
| `get_jobs` | List user's jobs |
| `add_job` | Create a new job |
| `get_goals` | List user's goals |
| `add_goal` | Create a new goal |
| `check_goal_progress` | See progress toward goals |
| `get_tax_estimate` | Calculate estimated taxes |
| `export_csv` | Generate CSV report |
| `export_pdf` | Generate PDF report |
| `get_best_days` | Find highest earning days |
| `get_templates` | List industry templates |

---

## 📋 Upcoming Features (Phase 6+ - Polish & Enhancement)

These features were previously documented in copilot-instructions.md and are now tracked in the roadmap:

### Shift Details Screen - File Attachments
- **Description:** Enable users to attach multiple file types (PDFs, DOCs, Excel files, images) to shift records
- **Use Case:** Store receipts, invoices, event contracts, BEO sheets as files (not just photos)
- **Implementation:** Universal file picker using `file_picker` package
- **UI:** Replace gallery button with attachment button; bottom sheet with "Pick File" or "Choose from Gallery"
- **Status:** Not started
- **Priority:** Medium

### Shift Details Screen - Date Display
- **Description:** Keep compact date badge INSIDE hero card; remove redundant long-form date display above
- **Use Case:** Cleaner UI, avoid redundancy
- **Implementation:** Minor UI refactor
- **Status:** Not started
- **Priority:** Low (Polish)

### Calendar Screen - Modal Shift Cards
- **Description:** Shift cards in calendar modal should match "Recent Shifts" dashboard cards
- **Style:** Box shadow, ripple effect, consistent layout
- **Layout:** Job Name + Amount | Event + Guest Count | Employer + Time Range
- **Status:** Not started
- **Priority:** Medium

### Calendar Screen - Compact Drawer Summary Bar
- **Description:** Replace large hero card with compact summary bar showing Income, Hours, Shift Count, and Add Button
- **Use Case:** More shifts visible at once in modal
- **Display:** Shows "Double" (2 shifts), "Triple" (3), "Quad" (4), or "5x"+ for 5+ shifts
- **Status:** Not started
- **Priority:** Medium

### Shift Details Screen - Inline Editing
- **Description:** Edit shift fields directly on Shift Details screen (like a word processor) without opening edit modal
- **Features:**
  - Tap field → becomes editable
  - Text brightness increases while editing
  - Pulsing "Save" icon appears when changes made
  - Smart validation (time format, numeric values)
  - Auto-save on blur (with manual save option)
- **Time Format:** Intelligently parse shorthand (e.g., "2" → "2 PM" based on shift length)
- **Status:** Not started
- **Priority:** High

### Shift Details Screen - Hero Card Reorganization
- **Description:** Reorganize hero card layout to match Recent Shifts dashboard cards for consistency
- **Changes:** Better padding, prevent text overflow, dynamic badge placement
- **Status:** Not started
- **Priority:** Medium (Polish)

### Settings Screen - Section Reordering
- **New Order:**
  1. MY JOBS
  2. EVENT CONTACTS ← Moved up
  3. NOTIFICATIONS ← Moved up
  4. APPEARANCE ← Moved up
  5. DATA IMPORT
  6. SCHEDULE SYNC ← Moved down
  7. GOALS
  8. TAX ESTIMATION
  9. ACCOUNT
- **Status:** Not started
- **Priority:** Low (UX improvement)

### App Icon Label
- **Description:** Change app icon label from full name to "ITB" on both iOS and Android
- **Android:** Modify `android:label` in AndroidManifest.xml
- **iOS:** Modify `CFBundleDisplayName` in Info.plist
- **Status:** Not started
- **Priority:** Low (Branding)

### Import Screen - Padding Adjustment
- **Description:** Increase padding on Import Shift Preview screen so bottom buttons (Cancel, Import) are fully visible
- **Status:** Not started
- **Priority:** Low (UX fix)

### Import Screen - AI-Assisted Mapping (Enhanced)
- **Description:** Provide intelligent suggestions when mapping CSV columns to shift fields
- **Features:**
  - Ask user when AI uncertain (e.g., "Party" → Job Name or Event Name?)
  - Auto-detect job names and suggest creating new job if needed
  - Ask for help if >10 jobs detected
  - Distinguish between Jobs (1-5) and Events (many per job)
  - Show sample values for unmapped fields
- **Status:** Not started
- **Priority:** High (Improves import UX)

### Import Screen - Job Pre-Selection
- **Description:** Allow users to select a job BEFORE importing, so AI knows job context
- **Use Case:** "Import all shifts for Restaurant XYZ" → AI maps to existing job
- **Implementation:** Job selector at top of import screen
- **Status:** Not started
- **Priority:** Medium

### Calendar - Conflict Detection
- **Description:** Alert users when personal calendar events (doctor appointments, meetings) conflict with scheduled work shifts
- **Features:**
  - Detect time overlaps between work shifts and personal events
  - Show same-day warnings (e.g., appointment at 2 PM, shift at 5 PM)
  - All-day event conflicts (e.g., "Out of Town" vs. scheduled shift)
- **Database:** `calendar_events` table exists; logic not implemented
- **Settings:** Toggle in Notifications → "Schedule Conflict Alerts" (already UI ready)
- **Alerts:** Push notifications, calendar visual indicators, dedicated conflicts screen
- **Privacy:** Local-only processing, read-only, no data stored
- **Status:** Partially done (DB table + UI exists, logic not implemented)
- **Priority:** Medium

---

## 💰 Monetization Model

| Tier | Price | Features |
| :--- | :--- | :--- |
| **Free** | $0 | Manual entry, basic calendar, 5 AI scans/month |
| **Pro** | $4.99/mo | Unlimited AI scans, analytics, cloud sync |
| **Team** | $9.99/mo | Multi-user, shared reports, manager dashboard |

---

## 🛠️ Quick Links
- [Project Instructions](../.github/copilot-instructions.md)
- [Workflow Kit](../AI_WORKFLOW_TRANSFER_KIT.md)
- [Feature Backlog](FEATURE_BACKLOG.md)
