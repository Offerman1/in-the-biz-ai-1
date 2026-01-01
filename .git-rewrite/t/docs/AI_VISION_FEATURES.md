# AI Vision Features - Server Checkout & Invoice Import

**Status:** Planned for Q2 2026 (After MVP)  
**Priority:** High (Post-Launch)  
**Combined Estimated Effort:** 5-7 days  
**Cost per User:** ~$0.001-0.002 per scan (recurring)

---

## Overview

Two complementary AI vision features that use image recognition to automate data entry:

1. **Server Checkout Sheet Reader** - Scan restaurant checkout sheets to auto-fill shift data
2. **Invoice Import** - Scan invoices/receipts to auto-create shift entries for freelancers

Both use Gemini 3 Flash Preview with vision capabilities to extract structured data from unstructured images/PDFs.

---

# Feature 1: AI Vision Server Checkout Sheet Reader

## Business Case

### Problem
- Servers/bartenders get checkout sheets at end of shift with sales, tips, tipout
- Every restaurant has different formats (handwritten, printed, POS systems)
- Manual entry is tedious and error-prone
- Users want quick data entry without typing

### Solution
- Take photo of checkout sheet with phone camera
- AI extracts key fields: Total Sales, Net Sales, Gross Sales, Tipout, Tipout %, Server Take-Home
- Auto-fills shift form
- User confirms and saves

### Impact
- **Data entry time:** 5 minutes → 30 seconds (90% reduction)
- **Accuracy:** Human error eliminated
- **User satisfaction:** "This app reads my checkout sheets!"
- **Competitive moat:** Very few apps have this feature

---

## AI Model Selection & Cost Analysis

### Model Choice: Gemini 3 Flash Preview (with Vision)
**API Identifier:** `gemini-3-flash-preview`

### Pricing (December 2025):
- **Input (text/image/video):** $0.50 per 1M tokens
- **Output (text):** $3.00 per 1M tokens
- **Source:** https://ai.google.dev/pricing (verified Dec 27, 2025)

### Why This Model?
- ✅ **Vision Capability:** Native image understanding
- ✅ **OCR + Reasoning:** Not just text extraction, but semantic understanding
- ✅ **Format Flexibility:** Handles handwritten, printed, photos, screenshots
- ✅ **Context Awareness:** Knows "Net" vs "Gross" sales, calculates derived fields
- ✅ **Error Detection:** Flags inconsistencies (e.g., tipout > total sales)

### Alternatives Considered:
- ❌ **Traditional OCR (Tesseract):** Only extracts text, can't understand context
- ❌ **Gemini 2.5 Flash:** Slightly cheaper but less accurate on messy images
- ❌ **Gemini 3 Pro:** Overkill, 4x more expensive for minimal accuracy gain

### Cost per Scan:
```
Input Tokens:
- Image: ~1290 tokens (for 1024x1024 image)
- Analysis prompt: ~300 tokens
TOTAL INPUT: ~1,600 tokens = 0.0016M tokens

Output Tokens:
- Extracted data JSON: ~200 tokens
TOTAL OUTPUT: ~200 tokens = 0.0002M tokens

COST CALCULATION:
Input: 0.0016M × $0.50 = $0.0008
Output: 0.0002M × $3.00 = $0.0006
TOTAL: ~$0.0014 per scan
```

### Scale Economics:
- **User scans 20 shifts/month:** $0.028/month (~3 cents)
- **1,000 users × 20 scans/month:** $28/month total
- **Revenue:** $4.99 × 1000 users = $4,990/month
- **AI Cost Percentage:** 0.56% (negligible)

---

## User Stories

### Primary Flow
1. **User completes shift**, receives checkout sheet from manager
2. **Opens "Add Shift" screen** in app
3. **Taps camera icon** "Scan Checkout Sheet"
4. **Takes photo** of checkout sheet (or uploads from gallery)
5. **AI analyzes image:**
   - Extracts visible text via OCR
   - Identifies key fields: Total Sales, Tipout, Net Sales, etc.
   - Calculates derived values if needed
   - Validates data consistency
6. **Shows extracted data** with confidence scores
7. **User reviews and confirms:**
   - Can edit any field if AI got it wrong
   - Confidence indicators (90%+ = green, 70-89% = yellow, <70% = red)
8. **Saves shift** with all data auto-filled

### Edge Cases
- **Handwritten checkout:** AI uses context to interpret messy handwriting
- **Multiple formats:** AI adapts to different restaurant POS systems
- **Partial data:** If AI can't find tipout, user enters manually
- **Low confidence:** App warns "Please review these fields carefully"
- **Complete failure:** If AI confidence <50%, fallback to manual entry + send report to developer

---

## Common Restaurant Checkout Formats

### Format Examples AI Must Handle:

#### Format 1: Aloha POS (Common)
```
SERVER: Sarah #152
DATE: 12/27/2025

TOTAL SALES:     $1,247.50
TIPS DECLARED:   $   234.60
TIPOUT:          $    24.95
NET TIPS:        $   209.65
```

#### Format 2: Toast POS
```
Server Checkout - Toast POS
===========================
Gross Sales:    $987.00
Cash Tips:      $45.00
CC Tips:        $156.80
Total Tips:     $201.80
Tip Share:      $18.00
Take Home:      $183.80
```

#### Format 3: Handwritten
```
[Photo of handwritten note]
Sales: 1,456
Tipout: 5% (72.80)
Tips: 267
Total: 194.20
```

### Fields to Extract (Priority Order):

| Field | Priority | Notes |
|-------|----------|-------|
| Total Sales | HIGH | Most common field |
| Tipout Amount | HIGH | Critical for calculations |
| Tipout % | MEDIUM | Can calculate from amount + sales |
| Net Tips / Take Home | HIGH | What server actually earned |
| Gross Tips | MEDIUM | Before tipout |
| Cash Tips | LOW | Nice to have, not always shown |
| CC Tips | LOW | Nice to have, not always shown |
| Date | MEDIUM | Usually matches shift date |

---

## Technical Implementation

### Architecture
```
User takes photo
    ↓
Compress image (max 2MB)
    ↓
Upload to Supabase Storage
    ↓
Send image + prompt to Gemini 3 Flash
    ↓
Receive extracted data JSON
    ↓
Validate data consistency
    ↓
Pre-fill shift form
    ↓
User reviews & saves
    ↓
If low confidence, log to error table
```

### Required Packages
```yaml
dependencies:
  image_picker: ^1.0.4          # Camera/gallery access
  image: ^4.0.17                # Image compression
  google_generative_ai: ^0.2.0  # Gemini API with vision
```

### Gemini Prompt Template
```dart
final prompt = '''
Analyze this server checkout sheet and extract shift data.

CONTEXT: This is a checkout sheet from a restaurant/bar showing end-of-shift totals.

FIELDS TO EXTRACT:
- total_sales: Total revenue from tables (Gross Sales, Net Sales, Total Sales)
- gross_tips: Tips before tipout
- tipout_amount: Amount paid to support staff
- tipout_percent: Percentage tipped out (calculate if needed)
- net_tips: Tips after tipout (Take Home, Net Tips)
- cash_tips: Cash tips (if shown separately)
- credit_tips: Credit card tips (if shown separately)
- date: Shift date

INSTRUCTIONS:
1. Use OCR to read all text from image
2. Identify which numbers correspond to which fields
3. Handle variations: "Total Sales" = "Gross Sales" = "Net Sales" (context-dependent)
4. Calculate derived fields: tipout_percent = (tipout_amount / total_sales) × 100
5. Validate: tipout should be <= total_sales, net_tips should be <= gross_tips
6. Provide confidence score (0-100) for each field

RESPOND IN JSON:
{
  "extracted_data": {
    "total_sales": 1247.50,
    "gross_tips": 234.60,
    "tipout_amount": 24.95,
    "tipout_percent": 2.0,
    "net_tips": 209.65,
    "cash_tips": null,
    "credit_tips": null,
    "date": "2025-12-27"
  },
  "confidence_scores": {
    "total_sales": 98,
    "gross_tips": 95,
    "tipout_amount": 95,
    "net_tips": 98
  },
  "warnings": [],
  "raw_ocr_text": "Full extracted text for debugging"
}
''';
```

### UI Flow

#### Screen: Enhanced `add_shift_screen.dart`
1. **Camera Icon Button** - "Scan Checkout Sheet"
2. **Take Photo or Upload** - Opens camera or gallery
3. **Loading State** - "Reading your checkout sheet..." (2-3 seconds)
4. **Auto-filled Form** - All extracted fields populated
5. **Confidence Indicators** - Green/yellow/red dots next to each field
6. **Review & Edit** - User can adjust any field
7. **Save Shift** - Standard save flow

#### Confidence Indicators
- 🟢 **90-100%:** Auto-fill without warning
- 🟡 **70-89%:** Auto-fill with yellow border, suggest review
- 🔴 **<70%:** Show extracted value but highlight for review

---

## Error Handling & Developer Reporting

### Error Categories

| Error Type | Handling | Developer Report |
|------------|----------|------------------|
| Low image quality | Ask user to retake photo | No report |
| OCR failure | Manual entry + log error | Yes - with image sample |
| Inconsistent data | Warn user, allow override | Yes - might indicate new format |
| Unknown format | Manual entry + log | Yes - HIGH PRIORITY |
| API timeout | Retry once, then manual | Log but don't report |

### Developer Error Reports

#### Supabase Table: `vision_scan_errors`
```sql
CREATE TABLE vision_scan_errors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  scan_date TIMESTAMPTZ DEFAULT NOW(),
  image_url TEXT,              -- Stored in Supabase Storage
  error_type TEXT,             -- 'ocr_failure', 'unknown_format', 'low_confidence'
  extracted_text TEXT,         -- Raw OCR output
  attempted_extraction JSONB,  -- What AI tried to extract
  confidence_score FLOAT,
  user_feedback TEXT,          -- Optional: user can report "This didn't work"
  resolved BOOLEAN DEFAULT FALSE,
  notes TEXT,                  -- Developer notes
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_vision_errors_unresolved ON vision_scan_errors(resolved) WHERE resolved = FALSE;
```

#### Weekly Error Report Email
```
Server Checkout Vision Errors - Week of Jan 1, 2026
===================================================
Total Scans: 1,247
Success Rate: 94.2%
Errors: 72

Error Breakdown:
1. Unknown Format (35 cases) - HIGH PRIORITY
   - Appears to be "Square POS" format
   - Example image: [link]
   - Common fields: "Net Sales", "Team Tips", "Total Payout"
   - Recommendation: Add Square POS format training

2. Low Image Quality (20 cases)
   - User education needed: "Hold camera steady"
   - Not actionable

3. Handwritten Illegible (12 cases)
   - OCR limitation, acceptable failure rate
   
4. Inconsistent Data (5 cases)
   - Tipout > Total Sales (likely user error or OCR mistake)
   - Needs manual review

Action Items:
- Train AI on Square POS format (affects 2.8% of users)
- Add image quality tips in UI
```

---

# Feature 2: AI Invoice Import

## Business Case

### Problem
- Freelancers, contractors, gig workers create invoices for clients
- Must manually enter invoice data into income tracking app
- Tedious double-entry (invoice tool → tracking app)
- Want single source of truth for income tracking

### Solution
- Take photo of sent invoice (or upload PDF)
- AI extracts: Client Name, Amount, Date, Service Description, Payment Terms
- Auto-creates shift/job entry with "Pending Payment" status
- When paid, user marks complete

### Impact
- **Expands TAM:** Attract freelancers beyond hourly workers
- **Reduces friction:** 5 minutes → 30 seconds per invoice
- **Stickiness:** Recurring use (10-20 invoices/month)
- **Competitive moat:** Few apps combine invoice scanning + income tracking

---

## AI Model Selection & Cost Analysis

### Model Choice: Gemini 3 Flash Preview (with Vision)
**API Identifier:** `gemini-3-flash-preview`

### Pricing: Same as Server Checkout feature
- **Input (text/image):** $0.50 per 1M tokens
- **Output:** $3.00 per 1M tokens

### Why This Model?
- ✅ **Document Understanding:** Excellent at structured documents (invoices, receipts)
- ✅ **Multi-format:** Handles PDF screenshots, photos, digital invoices
- ✅ **Semantic Extraction:** Understands "Amount Due" vs "Subtotal" vs "Total"
- ✅ **Date Parsing:** Various formats ("Net 30", "Due 1/15/26", etc.)

### Cost per Invoice Scan:
```
Input Tokens:
- Invoice image: ~1290 tokens
- Analysis prompt: ~200 tokens
TOTAL INPUT: ~1,500 tokens = 0.0015M tokens

Output Tokens:
- Extracted data JSON: ~150 tokens
TOTAL OUTPUT: ~150 tokens = 0.00015M tokens

COST CALCULATION:
Input: 0.0015M × $0.50 = $0.00075
Output: 0.00015M × $3.00 = $0.00045
TOTAL: ~$0.0012 per invoice scan
```

### Scale Economics:
- **Freelancer scans 10 invoices/month:** $0.012/month (~1 cent)
- **1,000 freelancers × 10 invoices/month:** $12/month total
- **Revenue:** $4.99 × 1000 users = $4,990/month
- **AI Cost Percentage:** 0.24% (negligible)

---

## User Stories

### Primary Flow
1. **Freelancer completes project**, creates invoice in QuickBooks/FreshBooks/Word
2. **Opens In The Biz AI app**
3. **Taps "Add Income"** → "Scan Invoice"
4. **Takes photo or uploads PDF** of sent invoice
5. **AI extracts data:**
   - Client name
   - Invoice amount
   - Date issued
   - Due date / Payment terms
   - Service description
6. **Creates shift entry** with status: "Pending Payment"
7. **User confirms** and saves
8. **When paid**, user marks shift as "Paid" (becomes part of income totals)

### Secondary Flows
- **Payment tracking:** Dashboard shows "Pending: $2,450" + "Paid: $8,320"
- **Overdue alerts:** "Invoice for ABC Corp is 15 days overdue"
- **Client history:** See all invoices per client
- **Recurring clients:** Auto-suggest client name from history

---

## Invoice Formats to Support

### Common Invoice Types:

#### Format 1: Professional Invoice (QuickBooks, FreshBooks)
```
INVOICE #12345
Date: December 27, 2025
Due: January 27, 2026 (Net 30)

Bill To:
ABC Corporation
123 Main St
New York, NY 10001

Description:
Website Redesign - Phase 2

Amount: $3,500.00
Tax: $280.00
TOTAL: $3,780.00
```

#### Format 2: Simple Invoice (Word/Google Docs)
```
Invoice from: John Smith Design

To: XYZ Company
Date: 12/27/25
Service: Logo Design
Amount Due: $1,500

Payment Terms: Net 15
```

#### Format 3: Email Screenshot
```
[Screenshot of email]
"Hi Sarah, attached is my invoice for this month's consulting work.
Total: $4,200 for 24 hours @ $175/hr
Due by end of month. Thanks!"
```

### Fields to Extract:

| Field | Priority | Notes |
|-------|----------|-------|
| Amount | HIGH | Total amount due |
| Client Name | HIGH | Who owes the money |
| Date | HIGH | Invoice date |
| Service Description | MEDIUM | What work was done |
| Due Date / Terms | MEDIUM | Net 30, Net 15, etc. |
| Invoice Number | LOW | For reference only |
| Hourly Rate | LOW | If shown, extract for job info |

---

## Technical Implementation

### Architecture
```
User uploads invoice image/PDF
    ↓
Compress/convert to image
    ↓
Send to Gemini 3 Flash
    ↓
Extract structured data
    ↓
Create shift entry with "Pending" status
    ↓
User reviews & saves
    ↓
Dashboard shows pending vs paid income
```

### Database Schema Changes

#### New Fields in `shifts` table:
```sql
ALTER TABLE shifts ADD COLUMN payment_status TEXT DEFAULT 'paid';
-- Values: 'paid', 'pending', 'overdue'

ALTER TABLE shifts ADD COLUMN invoice_date DATE;
ALTER TABLE shifts ADD COLUMN due_date DATE;
ALTER TABLE shifts ADD COLUMN client_name TEXT;
ALTER TABLE shifts ADD COLUMN invoice_number TEXT;
```

OR create new `invoices` table (better long-term):
```sql
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  shift_id UUID REFERENCES shifts(id),
  client_name TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  invoice_date DATE NOT NULL,
  due_date DATE,
  payment_terms TEXT,          -- "Net 30", "Net 15", etc.
  payment_status TEXT DEFAULT 'pending',
  paid_date DATE,
  service_description TEXT,
  invoice_number TEXT,
  image_url TEXT,              -- Stored invoice image
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_invoices_user ON invoices(user_id);
CREATE INDEX idx_invoices_status ON invoices(payment_status);
CREATE INDEX idx_invoices_due ON invoices(due_date) WHERE payment_status = 'pending';
```

### Gemini Prompt Template
```dart
final prompt = '''
Analyze this invoice and extract key financial data.

CONTEXT: This is an invoice for freelance/contractor work showing payment details.

FIELDS TO EXTRACT:
- client_name: Who is being billed (company or person name)
- amount: Total amount due (look for "Total", "Amount Due", "Balance Due")
- invoice_date: Date invoice was issued
- due_date: Payment due date (may be explicit date or "Net 30" terms)
- payment_terms: Net 30, Net 15, Due on Receipt, etc.
- service_description: Brief description of work/services
- invoice_number: Invoice ID/number (if present)
- hourly_rate: If mentioned (e.g., "24 hrs @ \$175/hr")

INSTRUCTIONS:
1. Extract all visible text from invoice
2. Identify key fields (handle variations: "Amount Due" = "Total" = "Balance")
3. Parse payment terms: "Net 30" = 30 days from invoice_date
4. If multiple amounts shown, use the TOTAL (after tax/fees)
5. Extract client name carefully (may be in "Bill To" or "Client" section)

RESPOND IN JSON:
{
  "extracted_data": {
    "client_name": "ABC Corporation",
    "amount": 3780.00,
    "invoice_date": "2025-12-27",
    "due_date": "2026-01-27",
    "payment_terms": "Net 30",
    "service_description": "Website Redesign - Phase 2",
    "invoice_number": "12345",
    "hourly_rate": null
  },
  "confidence_scores": {
    "client_name": 95,
    "amount": 98,
    "invoice_date": 98,
    "due_date": 90
  },
  "warnings": []
}
''';
```

### UI Flow

#### New Screen: `invoice_scan_screen.dart`
1. **Upload Invoice** - Camera or gallery picker
2. **Loading State** - "Reading your invoice..."
3. **Extracted Data Form** - Pre-filled with AI data
4. **Payment Status** - Toggle: "Paid" or "Pending"
5. **Client Autocomplete** - Suggest previous clients
6. **Save** - Creates shift + invoice record

#### Dashboard Updates
- **Pending Income Card:** "$2,450 Pending Payment (3 invoices)"
- **Overdue Badge:** Red indicator on overdue invoices
- **Income Split:** Show "Paid" vs "Pending" in analytics

---

## Payment Tracking Features

### Dashboard Enhancements:
```
┌─────────────────────────────┐
│ Income Overview             │
├─────────────────────────────┤
│ Paid This Month: $8,320 ✓   │
│ Pending: $2,450 (3) ⏳       │
│ Overdue: $800 (1) ⚠️         │
└─────────────────────────────┘
```

### Pending Invoices List:
```
ABC Corp - $3,780
Due: Jan 27 (30 days) 🟢

XYZ Company - $1,500  
Due: Jan 10 (13 days) 🟡

Old Client LLC - $800
Due: Dec 15 (OVERDUE 12 days) 🔴
```

### Payment Status Flow:
1. **Scan invoice** → Status: Pending
2. **Get paid** → User marks "Paid" + optionally adds paid date
3. **Income shifts** → Moves from "Pending" to "Paid This Month"

---

## User Types & Use Cases

### Target Users:
- Freelance designers, developers, writers
- Independent contractors (electricians, plumbers, handymen)
- Consultants and coaches
- Photographers, videographers
- Any gig worker who invoices clients

### Use Case Example:
```
Freelance Web Developer Sarah:
- Completes 3 projects per month
- Invoices clients via QuickBooks
- Old workflow:
  1. Create invoice in QuickBooks
  2. Send to client
  3. Manually enter into In The Biz AI
  4. Update when paid
  Total time: 10 minutes × 3 = 30 min/month

- New workflow:
  1. Create invoice in QuickBooks
  2. Screenshot → Upload to In The Biz AI
  3. Confirm extracted data
  4. Mark paid when received
  Total time: 2 minutes × 3 = 6 min/month
  
Savings: 24 minutes/month, zero errors
```

---

## Success Metrics

### Server Checkout Feature:
- **Scan success rate:** Target >90%
- **Time savings:** Target 90% reduction (5 min → 30 sec)
- **User adoption:** Target 60% of shift entries use scan

### Invoice Import Feature:
- **Scan success rate:** Target >95% (invoices are cleaner than checkout sheets)
- **User retention:** Freelancers should have higher LTV
- **TAM expansion:** Target 20-30% of users are freelancers

---

## Implementation Timeline

### Phase 1: Server Checkout (3-4 days)
- [ ] Add camera button to Add Shift screen
- [ ] Implement image upload + compression
- [ ] Integrate Gemini 3 Flash vision API
- [ ] Build data extraction + validation
- [ ] Add confidence indicators
- [ ] Create `vision_scan_errors` table
- [ ] Test with 10+ different restaurant formats

### Phase 2: Invoice Import (3-4 days)
- [ ] Add "Scan Invoice" option to income screen
- [ ] Create `invoices` table or extend `shifts`
- [ ] Implement invoice extraction logic
- [ ] Build pending payment tracking
- [ ] Add payment status to dashboard
- [ ] Create overdue alert system
- [ ] Test with common invoice formats

### Phase 3: Error Reporting (1 day)
- [ ] Build developer error dashboard
- [ ] Set up weekly email reports
- [ ] Create resolution workflow

---

## Notes

- Both features use same AI model (Gemini 3 Flash Preview)
- Combined cost: ~$0.001-0.002 per scan (negligible)
- Invoice import is Phase 2 - build after server checkout proven
- Server checkout is higher priority (more users, bigger pain point)
- Invoice import expands TAM to freelancers (huge market)
- Error reporting is critical - restaurants/invoices will have new formats we haven't seen

---

**Last Updated:** December 27, 2025  
**Author:** Brandon (with Copilot)  
**Related Docs:** MASTER_ROADMAP.md, FEATURE_BACKLOG.md, AI_ENHANCED_IMPORT_SYSTEM.md
