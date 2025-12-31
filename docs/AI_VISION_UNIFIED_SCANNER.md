# 🤖 AI Vision - Unified Scanner System

**Status:** Planning Phase (Phase 6)  
**Priority:** HIGH - Core Feature  
**Last Updated:** December 31, 2025  
**Created By:** Brandon + GitHub Copilot

---

## 📋 Executive Summary

Build a unified "Scan" button available on **Add Shift**, **Edit Shift**, and **Shift Details** screens. This button opens a bottom sheet menu with multiple scanning options:

1. **BEO Scanner** (Event Details) - Multi-page event contracts
2. **Server Checkout Scanner** (Financial Data) - Restaurant POS receipts
3. **Business Card Scanner** (Contact Info) - Already built, just wire into menu
4. **Invoice Scanner** (Future) - For freelancers/contractors
5. **Receipt Scanner** (Future) - For gig workers/1099 contractors

**Vision:** Create the most comprehensive server tracking app by automatically capturing checkout data at the end of every shift, building a deep analytics database with zero manual effort.

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

## 📈 Analytics Dashboard (Future)

**After user has 10+ checkout scans, show:**

```
CHECKOUT ANALYTICS
├─ This Shift
│  ├─ Sales: $450
│  ├─ Tips: $90 (20%)
│  └─ Net after tipout: $78
│
├─ This Week
│  ├─ Total Sales: $2,150
│  ├─ Avg Sales/Shift: $537.50
│  ├─ Total Tips: $412 (avg 19.2%)
│  └─ Shifts Logged: 4/5
│
├─ This Month
│  ├─ Total Sales: $9,200
│  ├─ Avg Sales/Shift: $520
│  ├─ Best Shift: $650 (Wednesday)
│  ├─ Tip % Trend: ↑ 2% from last month
│  └─ Shifts Logged: 18/24
│
├─ Trends
│  ├─ Best Days: Friday (avg $580), Saturday (avg $560)
│  ├─ Best Times: Dinner shifts tip 3% higher
│  └─ Seasonal: December tips ↑ 12% vs baseline
│
└─ Insights
   ├─ "Your Friday sales are 28% higher than other days"
   ├─ "Tip percentage drops on rainy days (sample size: 3)"
   └─ "You've earned $18,450 tracked via checkout scanner"
```

---

## 🛠️ Implementation Roadmap

### Phase 6a: UI Foundation (Week 1)
- [ ] Add Scan button to Add Shift header
- [ ] Add Scan button to Edit Shift header
- [ ] Add Scan button to Shift Details header
- [ ] Create bottom sheet menu component
- [ ] Wire all scan options to appropriate screens

### Phase 6b: BEO Scanner (Week 2)
- [ ] Create BEO scan screen
- [ ] Implement multi-page detection
- [ ] Build AI concatenation logic
- [ ] Create review modal for extracted data
- [ ] Auto-fill shift form from BEO data
- [ ] Create Event Contact from BEO contact info

### Phase 6c: Server Checkout Research (Week 1-2, parallel)
- [ ] Research Toast POS format
- [ ] Research Square format
- [ ] Research Aloha/Micros format
- [ ] Collect real-world examples
- [ ] Document common fields
- [ ] Create POS Format Guide

### Phase 6d: Server Checkout Scanner (Week 3-4)
- [ ] Create Checkout scan screen
- [ ] Implement Gemini vision with POS-specific prompt
- [ ] Build review modal for financial data
- [ ] Auto-fill shift form from checkout data
- [ ] Store checkout metadata (which POS system detected, confidence level)
- [ ] Error handling for unclear receipts

### Phase 6e: Business Card Integration (Week 5)
- [ ] Add Business Card option to bottom sheet menu
- [ ] Test integration with existing business card scanner

### Phase 6f: Testing & Documentation (Week 5-6)
- [ ] Test all three scanners with real-world data
- [ ] Document POS detection accuracy
- [ ] Create user guide for scanning
- [ ] Note what worked, what needs improvement

---

## 📝 Data Storage

### New Database Fields (Shifts Table)

**For Server Checkouts:**
```sql
ALTER TABLE public.shifts ADD COLUMN (
  checkout_image_url TEXT,           -- Receipt image
  checkout_pos_system TEXT,           -- Toast/Square/Aloha/Micros/Other
  checkout_confidence DECIMAL(3,2),   -- 0.00 to 1.00
  checkout_scanned_at TIMESTAMPTZ,    -- When checkout was scanned
  checkout_metadata JSONB              -- Raw extracted data for future use
);
```

**For BEOs:**
```sql
ALTER TABLE public.shifts ADD COLUMN (
  beo_image_urls TEXT[],              -- Array of BEO photos (multi-page)
  beo_scanned_at TIMESTAMPTZ,
  beo_metadata JSONB                  -- Raw extracted BEO data
);
```

---

## 🎯 Success Metrics

After Phase 6 completion:

- ✅ Users can scan BEOs and automatically populate shift events
- ✅ Users can scan checkout receipts and track sales/tips data
- ✅ 90%+ of real-world POS receipts can be parsed successfully
- ✅ Business card integration works seamlessly
- ✅ All extracted data is editable in review modal
- ✅ Servers report "This is the first app that actually understands my checkout"

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

**Brandon:** This checkout scanner is the killer feature - the differentiator that makes servers choose our app over every other income tracker.

**Copilot:** Agreed. The unified scan button makes it discoverable. The fact that it works with multiple POS systems automatically makes it powerful. And building analytics on top of that data creates stickiness no competitor has.

**Next Steps:** Research the POS systems, then start building! 🚀
