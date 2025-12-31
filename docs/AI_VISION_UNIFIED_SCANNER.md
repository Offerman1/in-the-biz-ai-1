# 🤖 AI Vision - Unified Scanner System + Event Planner Features

**Status:** Planning Phase (Phase 6 - Integrated)  
**Priority:** HIGH - Core Feature  
**Last Updated:** December 31, 2025  
**Created By:** Brandon + GitHub Copilot

---

## 📋 Executive Summary

Build a unified "Scan" button available on **Add Shift/Party**, **Edit Shift/Party**, and **Details** screens. This button opens a bottom sheet menu with multiple scanning options, supporting **two distinct user workflows:**

### **Workflow 1: Servers & Bartenders**
- Scan server checkouts at end of shift
- Track sales, tips, earnings
- Build deep checkout analytics
- "Shifts" terminology

### **Workflow 2: Event Planners & Coordinators** (NEW)
- Scan BEOs (Banquet Event Orders)
- Log event details, contacts, guests, staffing
- Track commission income
- Build event portfolio
- "Parties" terminology (auto-renamed based on job type)

**Scanning Options:**
1. **BEO Scanner** (Event Details) - Multi-page event contracts, guest lists, floor plans
2. **Server Checkout Scanner** (Financial Data) - Restaurant POS receipts
3. **Business Card Scanner** (Contact Info) - Already built, wire into menu
4. **Invoice Scanner** (Future) - For freelancers/contractors
5. **Receipt Scanner** (Future) - For gig workers/1099 contractors

**Vision:** Create the most comprehensive work tracking app that adapts to different job types - servers track income via checkouts, event planners track events via BEOs - all in one intelligent system.

---

## 🎯 Phase 6 Plan - NOW (Immediate Build)

### What We're Building First:

1. **Unified Scan Button UI** ✨
   - Header icon on Add Shift / Edit Shift / Shift Details
   - Bottom sheet menu with scan options

2. **BEO Scanner** 
   - Multi-page photo support (AI asks "Scan another page?" or "Ready to import?")
   - Auto-fill event details to shift form
   - Extracts: Event name, Guest count, Contact name, Contact phone, Job location, Total sales, Date

3. **Server Checkout Scanner** ⭐ (PRIMARY FEATURE)
   - Research & document Toast, Square, Aloha, Micros POS formats
   - Scan single/multiple receipts
   - Extract financial data
   - Auto-fill shift form
   - Store checkout data for analytics

4. **Wire Business Card Scanner** into menu
   - Already works, just add to bottom sheet options

---

## 🏗️ UI Design

### Header Placement

**Add Shift / Edit Shift / Shift Details:**
```
┌─────────────────────────────────────┐
│  ← Back    [Screen Title]   [✨ Scan] │
└─────────────────────────────────────┘
```

### Scan Button Menu

**When user taps Scan icon:**
```
┌──────────────────────────────────────┐
│  What would you like to scan?        │
├──────────────────────────────────────┤
│  🧾 BEO (Event Details)              │
│     Event name, guest count, contact │
│                                      │
│  📊 Server Checkout                  │
│     Sales, tips, financial data      │
│                                      │
│  💼 Business Card (Contact)          │
│     Create/add event contact         │
│                                      │
│  📄 Invoice (Coming Soon)            │
│  🧾 Receipt (Coming Soon)            │
└──────────────────────────────────────┘
```

### Scan Flow (Any Option)

```
User taps option
    ↓
Camera/Gallery picker
    ↓
AI analyzes image
    ↓
Review modal (user can edit extracted data)
    ↓
Confirm → Data auto-fills shift form / Creates contact / Stores data
```

---

## 📊 Feature Details

### 1. BEO Scanner ✅ (Build in Phase 6)

**Purpose:** Capture event details from Event Planning BEOs (multi-page contracts)

**Input:**
- Photos of BEO (Banquet Event Order)
- Can be multi-page document
- AI asks "Scan another page?" or "Ready to import?"

**Extracts:**
- Event name / Party name
- Guest count / Number of covers
- Date of event
- Contact person name
- Contact person phone
- Contact person email (if present)
- Job location / Venue
- Total event sales
- Menu details (if present)
- Special notes

**Auto-fills in Shift Form:**
- `event_name`
- `guest_count`
- `date`
- Job location field
- Creates/links Event Contact
- Notes field

**Key Feature:** Multi-page concatenation
- Gemini vision analyzes each page
- AI determines if more pages needed
- Combines all data into single shift entry

**Data Flow:**
```
BEO Photo(s) 
    ↓ Gemini Vision
Extract Data
    ↓ Review Modal
User Confirms/Edits
    ↓ Save
Shift form auto-filled + Event Contact created
```

---

### 2. Server Checkout Scanner ⭐ (Build in Phase 6)

**Purpose:** Revolutionize server tracking by capturing checkout data at end of every shift

**The Vision:**
- Servers scan checkout receipt at end of EVERY shift
- AI extracts financial data consistently
- Automatic deep analytics database builds over time
- Server gets insights no other app provides
- 90%+ coverage of real-world POS systems

**Why This Matters:**
- ✅ Solves core problem: Servers don't manually track because it's tedious
- ✅ Automatic history: Just scan, no data entry
- ✅ Deep analytics: After 50+ scans, incredible insights
- ✅ Competitive moat: No other app does this comprehensively
- ✅ Gets smarter: AI learns from each scan

**Input:**
- Single photo of POS checkout/receipt
- Supports: Toast, Square, Aloha, Micros POS systems + handwritten
- Different formats handled by Gemini vision

**Extracts (Common Fields):**
- Date of shift
- Total sales/Total revenue
- Gross tips (if calculated on receipt)
- Credit tips (separated if available)
- Cash tips (if separated)
- Tipout amount
- Tipout percentage
- Number of covers/checks served
- Table numbers (if listed)
- Payment methods breakdown (if visible)
- Server name/ID (if present)
- Shift time (if present - doubtful)
- Special notes/comps/voids (if visible)

**Auto-fills in Shift Form:**
- `date`
- `sales_amount` (or `total_revenue`)
- `credit_tips`
- `cash_tips` (calculated from receipt if available)
- `tipout_percent`
- `additional_tipout` (if listed)
- Calculates net tips automatically
- `guest_count` (if covers listed)

**Future Analytics Dashboard:**
After multiple checkout scans, user sees:
- Total sales trends (daily, weekly, monthly, yearly)
- Average sales per shift
- Tip percentage trends
- Best earning days/times
- Shift frequency (which shifts logged)
- Year-over-year comparison
- Seasonal patterns
- Best/worst performing shifts
- Correlations: "Your tip % is higher on Friday nights"

**Data Flow:**
```
Checkout Receipt Photo
    ↓ Gemini Vision (trained on POS formats)
Extract Financial Data
    ↓ Review Modal (user confirms/corrects)
Data Validated
    ↓ Save
Shift form auto-filled + Checkout data stored
    ↓ Over time
Analytics Dashboard shows deep insights
```

---

### 3. Business Card Scanner ✅ (Already Built - Wire Into Menu)

**Status:** Fully implemented in Event Contacts edit screen

**How it works:**
- Takes photo of business card
- Gemini vision extracts contact info
- Auto-fills contact form
- Uploads image to storage
- Creates Event Contact entry
- Can attach to shift

**What We Do:** Just add to the bottom sheet menu options
- Routes to existing scan-business-card flow
- No new code needed

---

### 4. Invoice Scanner ⏸️ (Future - Phase 7+)

**Status:** Not building in Phase 6

**Why:** Needs separate freelancer/contractor infrastructure first

**Future Plan:**
- Scan invoice/receipt photos or PDFs
- Extract: Client name, Invoice amount, Date, Service description, Payment terms
- Create "Freelance Income" entry (not shift-based)
- Track payment status (pending → paid)
- Link to gig worker analytics

**When to build:** After "Invoice/Receipt Tracking for 1099 Workers" phase

---

### 5. Receipt Scanner ⏸️ (Future - Phase 7+)

**Status:** Not building in Phase 6

**Why:** Belongs with invoice tracking for expense deduction

**Future Plan:**
- Scan receipts from purchases
- Extract: Vendor, Amount, Category, Date
- Store as "Expense" or "Deduction"
- Two use cases:
  1. Business expenses (equipment, tools, etc.)
  2. Items bought FOR shifts (catering, supplies - less common)
- Use for tax purposes

**When to build:** With Invoice Scanner (Phase 7+)

---

## 🔍 Server Checkout Research - POS Systems Analysis

### Task: Document Popular POS Systems

**Systems to Research:**
1. ✅ Toast (Hospitality focused)
2. ✅ Square (Small business)
3. ✅ Aloha/Oracle Micros (Enterprise)
4. ✅ Micros (Legacy, still widely used)
5. ⚠️ Clover (Square competitor)
6. ⚠️ TouchBistro (iPad-based)
7. ⚠️ Lightspeed (Retail/Restaurant)
8. ⚠️ Handwritten (Manual receipts)

### Research Questions to Answer:

**For Each POS System:**

1. **Visual Layout:**
   - What does a typical checkout receipt look like?
   - Single page or multiple pages?
   - Text orientation (standard or rotated)?
   - Logo placement?

2. **Data Fields Present:**
   - Server/bartender name/ID?
   - Table/check numbers?
   - Date and time?
   - Item names (food/drinks)?
   - Subtotal, tax, total?
   - Tip line (pre-calculated or empty)?
   - Payment method breakdown?
   - Covers/number of guests?
   - Voids, comps, adjustments?
   - Manager signature line?

3. **Financial Data:**
   - Gross sales (before tax)?
   - Net sales (after discounts)?
   - Total tips (if calculated)?
   - Separate cash/credit?
   - Tipout percentage?
   - Tipout amount?
   - House fees/service charges?

4. **Variations:**
   - Multi-shift receipts (if server closes out multiple times)?
   - Different formats for bar vs. restaurant?
   - Mobile orders vs. dine-in?
   - Takeout receipts?

5. **OCR Challenges:**
   - Handwriting quality (if applicable)?
   - Font readability?
   - Image quality issues?
   - Blurry or damaged receipts?
   - Different paper colors/styles?

### Research Deliverables:

- [ ] Screenshot/PDF of each POS system's checkout
- [ ] Document common fields across all systems
- [ ] List which fields appear in MOST systems (priority to extract)
- [ ] List edge cases and variations
- [ ] Create "POS Format Guide" for AI training
- [ ] Design test dataset with real examples

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

## 🤖 AI Implementation Strategy

### Gemini Vision Configuration

**Model:** `gemini-3-flash-preview` (with vision)

**Cost:**
- $0.50 per 1M input tokens (includes images)
- $3.00 per 1M output tokens
- Per scan cost: ~$0.001-0.002

**Why this model:**
- ✅ Superior OCR for receipts
- ✅ Handles multiple image formats
- ✅ Semantic understanding of financial data
- ✅ Learns from context (understands POS systems)
- ✅ Cost-effective at scale

### Prompts for Each Scanner

**BEO Prompt:**
```
Analyze this BEO (Banquet Event Order) image and extract:
1. Event/Party name
2. Date of event
3. Number of guests/covers
4. Contact person name
5. Contact phone number
6. Contact email (if present)
7. Venue/Job location
8. Total event sales
9. Menu items (if listed)
10. Special notes or requirements

If this is a multi-page document, indicate if more pages are needed.
Return as JSON.
```

**Checkout Prompt:**
```
Analyze this restaurant/bar POS checkout receipt and extract:
1. Shift date
2. Server/bartender name (if present)
3. Total sales/revenue
4. Subtotal (if different from total)
5. Tax amount
6. Gross tips (if calculated)
7. Credit tips
8. Cash tips
9. Tipout amount
10. Tipout percentage
11. Number of covers/checks
12. Payment methods breakdown
13. Special notes (voids, comps, adjustments)

This appears to be from: [Toast/Square/Aloha/Micros/Other]
Confidence level: [High/Medium/Low]

Return as JSON with all extracted fields and confidence scores.
```

**Business Card Prompt:** (Already exists)

---

## 📈 Checkout Analytics Dashboard (Stats Screen - New Tab)

### Location: Stats Screen → "Checkout Tracking" Tab

**New tab on Stats screen, separate from "Overall Stats"**

```
STATS SCREEN
├─ TAB: Overall Stats (existing)
│  └─ Shift-based analytics (unchanged)
│
└─ TAB: Checkout Tracking (NEW)
   └─ Checkout-based analytics
```

### Checkout Analytics Tab Content

**Period Selector:** [Week] [Month] [Year] [Custom Range]

**Key Metrics:**
```
CHECKOUT TRACKING (December 2025)

├─ Checkouts Scanned: 47
├─ Total Sales Tracked: $8,450
├─ Average Sale/Checkout: $179.79
├─ Checkouts Verified: 44 (93%)
│
├─ TIPS ANALYSIS
│  ├─ Total Tips: $1,546.50
│  ├─ Average Tip: $32.91
│  ├─ Average Tip %: 18.3%
│  ├─ Best Tip: 28% (Table 7, 4 covers)
│  └─ Worst Tip: 8% (Large party, 20 people)
│
├─ BY RESTAURANT
│  ├─ "The Steakhouse" - 12 checkouts, $2,856 sales, 19.2% tip %
│  ├─ "Quick Bistro" - 18 checkouts, $1,710 sales, 17.8% tip %
│  └─ "Farm to Table" - 17 checkouts, $3,884 sales, 18.5% tip %
│
├─ BY POS SYSTEM
│  ├─ Toast: 28 checkouts (avg $198, 19% tip %)
│  ├─ Square: 12 checkouts (avg $140, 16% tip %)
│  ├─ Aloha: 7 checkouts (avg $205, 19% tip %)
│  └─ Other: 0 checkouts
│
└─ CHARTS
   ├─ Sales by Day of Week (bar chart)
   ├─ Tip % Trend (line chart)
   ├─ Checkouts by Restaurant (pie chart)
   └─ POS System Distribution
```

### Future: Toggle to Include in Overall Analytics (v1.1+)

When implemented (NOT in MVP):

```
Settings → Analytics Preferences
├─ Include Checkout Data in Overall Stats
│  [Toggle ON/OFF]
│  "When ON, checkout sales trends appear in main dashboard"
```

**Important:** Keep separate because:
- Checkout sales ≠ Your earnings
- Checkout trends ≠ Shift income trends
- Some users track ONLY checkouts (no shifts)
- Prevents data confusion

---

## 🛠️ Implementation Roadmap (Phase 6 - Integrated)

### Phase 6a: UI Foundation & Job Type System (Week 1)
- [ ] Create/update Job Type system
  - [ ] Add job type detection (Server vs Event Planner)
  - [ ] Auto-configure features based on job type
  - [ ] Auto-rename "Shift" ↔ "Party" based on context
  - [ ] Add toggles for optional sections
- [ ] Add ✨ Scan button icon to Add Shift/Party header
- [ ] Add Scan button to Edit Shift/Party header  
- [ ] Add Scan button to Shift/Party Details header
- [ ] Create bottom sheet menu component with options:
  - [ ] 🧾 BEO (Event Details) - For Event Planners
  - [ ] 📊 Server Checkout - For Servers/Bartenders
  - [ ] 💼 Business Card
  - [ ] 📄 Invoice (Coming Soon)
  - [ ] 🧾 Receipt (Coming Soon)

### Phase 6b: Unified Verification Framework (Week 1-2)
- [ ] Build reusable verification screen component
  - [ ] Preview card with confidence badges
  - [ ] Questions section (responsive 2-4 cards)
  - [ ] Action buttons (Approve/Answer/Discard)
  - [ ] Notes section (formatted or free-text)
- [ ] Build question generation logic
- [ ] Implement Gemini vision integration (base)

### Phase 6c: Server Checkout Scanner (Week 2-3)
- [ ] Create checkout scan screen (photo picker)
- [ ] Implement multi-page detection logic
  - [ ] After each photo: "Another page?" or "Ready to import?"
  - [ ] Concatenate multi-page data
- [ ] Customize verification for checkout data
  - [ ] Checkout preview card (sales, tips, tax, etc.)
  - [ ] Questions for unclear fields
  - [ ] Optional notes section
- [ ] Build Gemini vision integration for checkouts
  - [ ] POS system detection (Toast/Square/Aloha/etc)
  - [ ] Field extraction with confidence scores
  - [ ] Question generation for low-confidence fields
- [ ] Create server_checkouts database table
- [ ] Save verified checkout data
- [ ] Error handling for unclear receipts

### Phase 6d: BEO Scanner (Week 3-4)
- [ ] Create BEO scan screen (photo picker)
- [ ] Implement multi-page detection (same as checkout)
- [ ] Customize verification for BEO data
  - [ ] Event preview card (event name, date, guests, venue, contact, sales)
  - [ ] Questions for unclear fields
  - [ ] Formatted notes section (with categories)
- [ ] Build Gemini vision integration for BEOs
  - [ ] Extract all BEO fields (using comprehensive field database)
  - [ ] Generate questions for ambiguous data
  - [ ] Format unstructured data into readable notes
- [ ] Create beo_events database table
- [ ] Wire extracted contacts to Contact Database
- [ ] Auto-fill shift/party form with BEO data

### Phase 6e: Event Planner Features (Week 4)
- [ ] Build Guest List section
  - [ ] Table for guest name, dinner choice, dietary restrictions, table #
  - [ ] Filter by dietary/table
  - [ ] Check off arrivals
  - [ ] Edit notes per guest
- [ ] Build Floor Plan gallery section
  - [ ] Multi-photo gallery
  - [ ] Photo captions
  - [ ] PDF attachments
- [ ] Update Shift/Party form with new sections
  - [ ] Event Details (Event Name, Type, Venue, Contact)
  - [ ] Event Logistics (Setup time, breakdown, timeline)
  - [ ] Guest List tab
  - [ ] Floor Plan tab
  - [ ] Staffing Assignments (for future)

### Phase 6f: Checkout Analytics Tab (Week 4-5)
- [ ] Add "Checkout Tracking" tab to Stats screen
- [ ] Build analytics queries from server_checkouts table
- [ ] Create dashboard UI with:
  - [ ] Key metrics (total sales, avg sale, tip %)
  - [ ] By Restaurant breakdown
  - [ ] By POS System breakdown
  - [ ] Charts (sales by day, tip % trend)
- [ ] Add period selector (Week/Month/Year/Custom)

### Phase 6g: Optional Features (Week 5)
- [ ] Import to Shift/Party button
  - [ ] Pre-fill Add Shift/Party form with checkout/BEO data
  - [ ] Map fields to shift form
- [ ] Auto-import toggle in settings
- [ ] Duplicate detection
  - [ ] Warn if checkout/event already exists
  - [ ] Options to create new or replace

### Phase 6h: Business Card Integration (Week 5)
- [ ] Add Business Card option to bottom sheet menu
- [ ] Wire to existing business card scanner
- [ ] Test integration with both Server and Event Planner workflows

### Phase 6i: Testing & Documentation (Week 6)
- [ ] Test scanners with 20+ real-world receipts and BEOs
- [ ] Document extraction accuracy by type
- [ ] Test with both Server and Event Planner jobs
- [ ] Collect edge cases and improvements
- [ ] Create user guides (for both job types)
- [ ] Gather feedback for v1.1

---

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

### New Database Table: beo_events

```sql
CREATE TABLE public.beo_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Event Identification
  event_name TEXT NOT NULL,
  event_type TEXT,  -- "Wedding", "Corporate", "Social", "Birthday", etc.
  event_date DATE NOT NULL,
  event_time_start TIME,
  event_time_end TIME,
  
  -- Contact Information
  primary_contact_id UUID REFERENCES event_contacts(id),  -- Link to contact
  primary_contact_name TEXT,
  primary_contact_phone TEXT,
  primary_contact_email TEXT,
  alternate_contact_name TEXT,
  alternate_contact_phone TEXT,
  
  -- Venue & Logistics
  venue_name TEXT,
  venue_address TEXT,
  setup_time TIME,
  breakdown_time TIME,
  
  -- Guests & Details
  expected_guest_count INT,
  confirmed_guest_count INT,
  
  -- Financial
  total_sale_amount DECIMAL(10, 2),
  deposit_amount DECIMAL(10, 2),
  balance_due DECIMAL(10, 2),
  service_charge_percent DECIMAL(5, 2),
  commission_percent DECIMAL(5, 2),
  commission_amount DECIMAL(10, 2),
  
  -- Extracted Details
  menu_details TEXT,  -- Formatted menu info
  decor_details TEXT,  -- Formatted decor info
  staffing_details TEXT,  -- Formatted staffing info
  
  -- AI Metadata
  ai_confidence_scores JSONB,  -- Confidence for each field
  overall_confidence DECIMAL(3, 2),
  
  -- User Verification
  user_verified BOOLEAN DEFAULT FALSE,
  user_verified_at TIMESTAMPTZ,
  user_adjustments JSONB,  -- What user changed
  user_questions_answered JSONB,
  
  -- Formatted Notes (All unstructured BEO data)
  formatted_notes TEXT,  -- Nicely formatted notes with sections
  
  -- Images & Attachments
  image_urls TEXT[],  -- Multi-page BEO photos
  floor_plan_urls TEXT[],  -- Floor plan photos/PDFs
  image_count INT,
  
  -- Linking
  linked_shift_id UUID REFERENCES shifts(id) ON DELETE SET NULL,  -- If user created shift from BEO
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_beo_events_user ON public.beo_events(user_id);
CREATE INDEX idx_beo_events_date ON public.beo_events(event_date);
CREATE INDEX idx_beo_events_verified ON public.beo_events(user_verified);
```

### New Database Table: beo_guest_list

```sql
CREATE TABLE public.beo_guest_list (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  beo_event_id UUID NOT NULL REFERENCES beo_events(id) ON DELETE CASCADE,
  
  guest_name TEXT NOT NULL,
  dietary_restrictions TEXT,  -- "Vegetarian", "Gluten-free", "Shellfish allergy", etc.
  entree_choice TEXT,  -- "Filet Mignon", "Herb Chicken", "Vegetarian Pasta"
  table_number INT,
  notes TEXT,  -- Special instructions for this guest
  
  arrived BOOLEAN DEFAULT FALSE,
  arrived_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_guest_list_event ON public.beo_guest_list(beo_event_id);
CREATE INDEX idx_guest_list_table ON public.beo_guest_list(table_number);
```

### Shifts Table Updates (For Both Servers & Event Planners)

**No database changes needed initially.** The system will use the existing shifts table and link to server_checkouts or beo_events via foreign keys.

Future enhancement (v1.1):
```sql
ALTER TABLE public.shifts ADD COLUMN (
  source_checkout_id UUID REFERENCES server_checkouts(id),  -- If created from checkout
  source_beo_id UUID REFERENCES beo_events(id),  -- If created from BEO
  shift_type TEXT DEFAULT 'shift'  -- "shift" or "party" (for UI display)
);
```

---

## 🎯 Success Metrics

After Phase 6 completion:

### **For Servers & Bartenders:**
- ✅ Users can scan server checkout receipts
- ✅ 90%+ of real-world POS receipts can be parsed successfully
- ✅ Automatic financial data extraction (sales, tips, tax)
- ✅ Multi-page checkout support
- ✅ Checkout Analytics dashboard shows trends
- ✅ Optional "Import to Shift" for shift creation
- ✅ Servers report "This app finally understands my checkout"

### **For Event Planners & Coordinators:**
- ✅ Users can scan BEOs (Banquet Event Orders)
- ✅ 85%+ of BEO data extracted accurately
- ✅ All event details captured (contact, guests, menu, decor, staffing, logistics)
- ✅ Multi-page BEO support
- ✅ Guest list with dietary restrictions and seating
- ✅ Floor plan/photo gallery
- ✅ Auto-populates party/event form
- ✅ Commission tracking
- ✅ Contact database integration
- ✅ Event planners report "This is the event planning tool I've been waiting for"

### **Overall System:**
- ✅ Job type system works (Server vs Event Planner features)
- ✅ Terminology adapts based on job (Shift vs Party)
- ✅ Business card integration seamless
- ✅ All extracted data editable in verification screen
- ✅ Multi-user platform supports diverse job types

---

## 🚀 Next Phase (7+)

- **Invoice/Receipt Tracking:** Build freelancer/contractor income tracking
- **Advanced Analytics:** Correlate checkout data with shifts for insights
- **Batch Scanning:** Upload multiple checkouts at once
- **POS API Integration:** Direct API connections (if available)
- **Expense Tracking:** Separate receipt tracking for deductions

---

## 📚 Related Documentation

- [MASTER_ROADMAP.md](./MASTER_ROADMAP.md) - Overall project timeline
- [FEATURE_BACKLOG.md](./FEATURE_BACKLOG.md) - Future features
- [AI_VISION_FEATURES.md](./AI_VISION_FEATURES.md) - Original AI vision specs

---

## 👥 Team Notes

**Brandon:** This unified system needs to support TWO completely different workflows - servers tracking income via checkouts, and event planners tracking events via BEOs. Both matter equally.

**Copilot:** The job type system is elegant - it auto-configures the feature set based on what they do. A server sees "Shifts" and checkout tracking. An event planner sees "Parties" and BEO scanning. Same code, different UX.

**Next Steps:** Integrate BEO research into planning, research POS systems, then build everything together in Phase 6! 🚀

---

# 📋 BEO (Banquet Event Order) Fields Research

**Purpose:** Comprehensive database of all possible BEO fields to ensure AI vision captures complete event details for event planners, coordinators, and catering managers.

**Status:** Planning Phase  
**Scope:** Catering, Weddings, Corporate Events, Banquets

---

## Overview

BEOs are the master documents for event planning in the hospitality industry. Unlike server checkouts (which are financial summaries), BEOs contain extensive operational details that event planners must track:

- Guest management (counts, dietary restrictions, seating)
- Menu planning (courses, selections, plating)
- Logistics (setup, breakdown, timing)
- Decor & ambiance (linens, flowers, lighting, AV)
- Staffing (servers, bartenders, coordinators)
- Financial terms (pricing, deposits, payments)
- Special requests and notes

---

## Complete BEO Fields Database

### **1. EVENT IDENTIFICATION**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| Event Name/Party Name | Text | Party Form | ✅ Yes |
| Event Type | Dropdown | Event Details | ✅ Yes |
| Event Date | Date | Party Date | ✅ Yes |
| Event Time (Start) | Time | Manual Entry | ⚠️ Optional |
| Event Time (End) | Time | Manual Entry | ⚠️ Optional |
| Duration | Number | Auto-calculated | ⚠️ Optional |
| Occasion Description | Text | Notes | ✅ Yes |
| Expected Guest Count | Number | Guest Count | ✅ Yes |
| Confirmed Guest Count | Number | Guest Count | ✅ Yes |

### **2. PRIMARY CONTACT INFORMATION**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| Primary Contact Name | Text | Contact Database | ✅ Yes |
| Primary Contact Phone | Phone | Contact Database | ✅ Yes |
| Primary Contact Email | Email | Contact Database | ✅ Yes |
| Primary Contact Address | Text | Contact Database | ✅ Yes |
| Alternate Contact Name | Text | Contact Database | ✅ Yes |
| Alternate Contact Phone | Phone | Contact Database | ✅ Yes |
| Contact Title/Role | Text | Notes | ✅ Yes |
| Special Instructions | Text | Notes | ✅ Yes |

### **3. VENUE & LOGISTICS**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| Venue Name | Text | Event Details | ✅ Yes |
| Venue Address | Text | Event Details | ✅ Yes |
| Room/Space Name | Text | Notes | ✅ Yes |
| Room Setup Style | Dropdown | Notes | ✅ Yes |
| Parking Information | Text | Notes | ✅ Yes |
| Loading Dock Time | Time | Notes | ✅ Yes |
| Setup Start Time | Time | Notes | ✅ Yes |
| Event Start Time | Time | Notes | ✅ Yes |
| Breakdown Start Time | Time | Notes | ✅ Yes |
| Final Departure Time | Time | Notes | ✅ Yes |
| Special Venue Restrictions | Text | Notes | ✅ Yes |

### **4. GUEST MANAGEMENT**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| Total Guest Count | Number | Party Form | ✅ Yes |
| VIP Guests | Number | Guest List | ✅ Yes |
| Children Count | Number | Guest List | ✅ Yes |
| Guest List | List | Guest List Section | ✅ Yes |
| Dietary Restrictions | List | Guest List Section | ✅ Yes |
| Seating Arrangement | Dropdown | Guest List Section | ✅ Yes |
| Table Assignments | List | Guest List Section | ✅ Yes |
| Accessibility Needs | Text | Notes | ✅ Yes |
| Children's Menu | Boolean | Notes | ✅ Yes |

### **5. MENU & BEVERAGE**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| Number of Courses | Number | Notes | ✅ Yes |
| Course Details (Appetizers, Soup, Entree, etc.) | Text | Notes | ✅ Yes |
| Entree Selections | List | Guest List Section | ✅ Yes |
| Special Items (Cake, Champagne) | Text | Notes | ✅ Yes |
| Bar Package | Dropdown | Financial Section | ✅ Yes |
| Alcohol Restrictions | Text | Notes | ✅ Yes |
| Non-Alcoholic Options | Text | Notes | ✅ Yes |
| Beverage Count Per Person | Number | Notes | ✅ Yes |
| Water Service | Boolean | Notes | ✅ Yes |
| Special Food Requests | Text | Notes | ✅ Yes |
| Cake Details | Text | Notes | ✅ Yes |

### **6. DECOR & AMBIANCE**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| Linens - Colors | Text | Notes | ✅ Yes |
| Linens - Material | Text | Notes | ✅ Yes |
| Centerpieces - Type | Text | Notes | ✅ Yes |
| Centerpieces - Flowers | Text | Notes | ✅ Yes |
| Centerpieces - Height | Text | Notes | ✅ Yes |
| Flower Delivery Time | Time | Notes | ✅ Yes |
| Lighting | Text | Notes | ✅ Yes |
| Chair Covers | Text | Notes | ✅ Yes |
| Table Numbers | Boolean | Notes | ✅ Yes |
| Entrance Decor | Text | Notes | ✅ Yes |

### **7. AUDIO/VISUAL & TECHNOLOGY**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| AV Requirements | Boolean | Notes | ✅ Yes |
| Projector/Screen | Boolean | Notes | ✅ Yes |
| Microphone | Boolean | Notes | ✅ Yes |
| Music Source | Text | Notes | ✅ Yes |
| Music Start Time | Time | Notes | ✅ Yes |
| DJ/Band Name | Text | Contact Database | ✅ Yes |
| DJ/Band Contact | Phone | Contact Database | ✅ Yes |
| Special Music Instructions | Text | Notes | ✅ Yes |
| Sound Check Time | Time | Notes | ✅ Yes |

### **8. STAFFING & LOGISTICS**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| Lead Coordinator | Text | Contact Database | ✅ Yes |
| Servers Needed | Number | Staffing Section | ✅ Yes |
| Bartenders Needed | Number | Staffing Section | ✅ Yes |
| Kitchen Staff | Text | Staffing Section | ✅ Yes |
| Event Day Supervisor | Text | Staffing Section | ✅ Yes |
| Special Staffing Notes | Text | Notes | ✅ Yes |
| Timeline for Staff | Text | Notes | ✅ Yes |

### **9. FINANCIAL INFORMATION**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| Total Package Price | Currency | Financial Section | ✅ Yes |
| Price Per Person | Currency | Financial Section | ✅ Yes |
| Base Cost | Currency | Financial Section | ✅ Yes |
| Tax Amount | Currency | Financial Section | ✅ Yes |
| Service Charge % | Percentage | Financial Section | ✅ Yes |
| Service Charge Amount | Currency | Financial Section | ✅ Yes |
| Total Estimated Sale | Currency | Financial Section | ✅ Yes |
| Deposit Amount | Currency | Financial Section | ✅ Yes |
| Balance Due | Currency | Financial Section | ✅ Yes |
| Commission % | Percentage | Financial Section | ✅ Yes |
| Commission Amount | Currency | Financial Section (Auto) | ✅ Yes |

### **10. SPECIAL REQUESTS & VENDORS**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| Ceremony Details | Text | Notes | ✅ Yes |
| Reception Timeline | Text | Notes | ✅ Yes |
| Client Provided Items | Text | Notes | ✅ Yes |
| Florist Name | Text | Contact Database | ✅ Yes |
| Florist Contact | Phone | Contact Database | ✅ Yes |
| Photographer Name | Text | Contact Database | ✅ Yes |
| Videographer Name | Text | Contact Database | ✅ Yes |
| Guest Accommodations | Text | Notes | ✅ Yes |
| Weather Contingency | Text | Notes | ✅ Yes |
| Final Notes | Text | Notes | ✅ Yes |

### **11. FLOOR PLAN & VISUAL DOCUMENTATION**

| Field | Type | Maps To | Extractable |
|-------|------|---------|-------------|
| Floor Plan Image | Image | Floor Plan Gallery | ✅ Yes |
| Table Diagram | Image | Floor Plan Gallery | ✅ Yes |
| Setup Photos | Image | Floor Plan Gallery | ✅ Yes |
| During-Event Photos | Image | Floor Plan Gallery | ✅ Yes |
| Post-Event Photos | Image | Floor Plan Gallery | ✅ Yes |

---

## BEO Scanning → Verification Flow

Same as Server Checkout, but adapted for event data:

```
VERIFICATION SCREEN

PREVIEW CARD:
┌─────────────────────────────────┐
│ 🎉 BANQUET EVENT PREVIEW        │
├─────────────────────────────────┤
│  Event: Smith Wedding            │
│  Date: 6/15/2026                 │
│  Guests: 150                      │
│  Venue: Grand Ballroom            │
│                                  │
│  Contact: Sarah Smith            │
│  Phone: (555) 123-4567  ✅        │
│                                  │
│  Sales: $8,500                    │
│  Commission: 15% ($1,275) ✅      │
│                                  │
│  ✓ High Confidence (8/10)         │
└─────────────────────────────────┘

QUESTIONS (If needed):
☑ Event type is "Wedding" - correct?
☑ 150 guests confirmed - correct?
☐ Did I read the venue correctly as "Grand Ballroom"?

NOTES SECTION:
┌─────────────────────────────────┐
│ BANQUET EVENT ORDER DETAILS     │
│ ─────────────────────────────────│
│ Setup: 2:00 PM                   │
│ Breakdown: 10:00 PM              │
│                                  │
│ LINENS:                          │
│ • Head Table: Ivory satin        │
│ • Guest Tables: Blush satin      │
│                                  │
│ MENU:                            │
│ • Filet Mignon - 65 servings     │
│ • Herb Chicken - 60 servings     │
│ • Vegetarian Pasta - 25 servings │
│ • Wedding cake (client provided) │
│                                  │
│ STAFF CONTACTS:                  │
│ • DJ: Spin Masters DJ - John     │
│ • Florist: Petals & Stems - Mike │
│                                  │
│ SPECIAL NOTES:                   │
│ • Grandma diabetic (Table 5)     │
│ • 6 gluten-free meals            │
│ • Ceremony slideshow during      │
│   cocktail hour                  │
└─────────────────────────────────┘
```

---

## Job Type Configuration

When user selects "Event Planner" job type:

```
AUTOMATICALLY ENABLED:
✓ Party terminology (not Shift)
✓ BEO Scanning button
✓ Guest List section
✓ Floor Plan gallery
✓ Staffing Scheduler
✓ Event Details form section
✓ Commission Tracking
✓ Contact Database (Event Contacts)

FORM SECTIONS SHOWN:
├─ Party Details (Date, Guests, Event Name)
├─ Event Information (Type, Venue, Contact)
├─ Financial (Sales, Commission, Deposit, Balance)
├─ Guest List & Seating (Tab)
├─ Floor Plan & Photos (Tab)
├─ Staffing Assignments (Tab)
├─ Contacts (Tab)
└─ Additional Notes

CAN CUSTOMIZE IN JOB EDIT:
☑ BEO Scanning
☑ Guest List
☑ Floor Plan
☑ Staffing
☑ Commission
☑ Contact Database
☑ Event Details
```

**For Server/Bartender Jobs (default):**
```
AUTOMATICALLY ENABLED:
✓ Shift terminology
✓ Checkout Scanning
✓ Checkout Analytics
✓ Commission (optional)

FORM SECTIONS:
├─ Shift Details (Date, Time, Guests)
├─ Financial (Sales, Tips, Commission)
├─ Attachments (Photos, Files)
├─ Notes
└─ Contacts (optional)
```

---

## Guest List Section (Event Planners)

```
GUEST LIST & DIETARY TRACKING

┌──────────────────────────────────────────────┐
│ Total Guests: 150                            │
│ Confirmed: 142   Pending: 8   Declined: 0   │
├──────────────────────────────────────────────┤
│                                              │
│ NAME            │ DINNER    │ DIETARY   │ TBL│
│─────────────────────────────────────────────│
│ Sarah Smith     │ Filet     │ None      │ 1 │
│ John Smith      │ Filet     │ None      │ 1 │
│ Michael Chen    │ Vegetarian│ Vegan     │ 2 │
│ Maria Garcia    │ Filet     │ Shellfish │ 3 │
│ [+ 146 more]    │           │           │   │
│                 │           │           │   │
│ [✓ Arrived] [×  Absent]                     │
└──────────────────────────────────────────────┘

FEATURES:
- ✓ Check off guests as they arrive
- ✓ Filter by dietary restrictions
- ✓ Group by table for service
- ✓ Meal selection tracking
- ✓ Edit notes per guest
```

---

## Floor Plan & Gallery (Event Planners)

```
FLOOR PLAN & VISUAL DOCUMENTATION

Gallery Grid:
┌──────────┬──────────┬──────────┐
│Setup 2pm │Setup 4pm │Pre-Event │
│ [Photo]  │ [Photo]  │ [Photo]  │
└──────────┴──────────┴──────────┘

┌──────────┬──────────┬──────────┐
│Ceremony  │Cocktail  │Reception │
│ [Photo]  │ [Photo]  │ [Photo]  │
└──────────┴──────────┴──────────┘

Attachments:
□ Floor_Plan_Final.pdf
□ Table_Diagram.png
□ Seating_Chart.pdf

FEATURES:
- ✓ Multi-photo gallery
- ✓ Photo captions/notes
- ✓ PDF attachments
- ✓ Organized by event phase
```

---

## Notes Formatting (All Unstructured Data)

When AI scans BEO, anything that doesn't fit a form field is formatted into readable notes:

```
═══════════════════════════════════════════════
         BANQUET EVENT ORDER DETAILS
═══════════════════════════════════════════════

LOGISTICS & TIMING
─────────────────────────────────────────────
Setup Start: 2:00 PM | Guests: 150
Event Start: 6:00 PM | Breakdown: 10:00 PM
Venue: Grand Ballroom, Downtown Hotel
Parking: Valet (validated)

MENU & SERVICE
─────────────────────────────────────────────
Courses: 5 (Appetizers, Soup, Salad, Entree, Dessert)

Appetizers: Shrimp cocktail, crudités, cheese board
Soup/Salad: Mixed greens, Caesar, Butternut soup

Entrees:
  • Filet Mignon - 65 servings
  • Herb-Brined Chicken - 60 servings  
  • Vegetarian Pasta - 25 servings

Dessert: Chocolate mousse, fruit, wedding cake (client)
Champagne Toast: 150 flutes at 7:45pm

Bar: Open (beer, wine, premium liquor)

DECOR
─────────────────────────────────────────────
Linens: Ivory (head table), Blush (guest tables)
Centerpieces: White roses, greenery (18" tall)
Flower Delivery: 1:00 PM
Lighting: Soft purple uplighting, string lights

VENDORS & CONTACTS
─────────────────────────────────────────────
DJ: Spin Masters - John Williams (555) 234-5678
Florist: Petals & Stems - Mike Chen (555) 111-2222
Photographer: Golden Light - Sarah James (555) 333-4444

SPECIAL REQUESTS
─────────────────────────────────────────────
• Grandmother diabetic (Table 5) - sugar-free dessert
• 6 gluten-free meals
• 4 vegetarian meals  
• 8 children's meals
• Ceremony slideshow during cocktail hour
• Rehearsal dinner previous night, 6pm
• Sunday brunch after (separate event)

═══════════════════════════════════════════════
```

---

**Status:** Comprehensive BEO Fields Database Complete  
**Next Action:** Begin Phase 6 implementation with integrated BEO + Server Checkout + Job Type System
