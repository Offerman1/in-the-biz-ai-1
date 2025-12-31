# 📊 POS System Research - Server Checkout Formats

**Research Date:** December 31, 2025  
**Purpose:** Document common POS system checkout receipt formats for AI vision training

---

## Overview

This document outlines the common checkout receipt formats used by major POS systems in the restaurant and hospitality industry. The goal is to ensure our AI vision model can extract financial data from ~90% of real-world server checkouts.

**Most Common POS Systems by Market Share (Estimated 2025):**
1. **Toast** (Hospitality-focused) - ~20-25% of upscale restaurants
2. **Square** (SMB-focused) - ~15-20% of casual restaurants  
3. **Aloha/Oracle Micros** (Enterprise) - ~20-25% of larger chains
4. **Clover** (Square ecosystem) - ~10% of retail/casual
5. **TouchBistro** (iPad-based) - ~5-10% of independent restaurants
6. **Lightspeed** (Hospitality/Retail) - ~5% of upscale
7. **Handwritten** (Manual/old-school) - ~5-10% legacy restaurants

---

## POS System Details

### 1. Toast (Hospitality-Focused)

**Market Position:** Premium/Upscale Restaurants  
**Availability:** Cloud-based, iPad/Android tablet terminals

**Typical Checkout Receipt Layout:**

```
┌─────────────────────────────────────┐
│  [Restaurant Logo/Name]             │ Header
│  Address & Phone                    │
├─────────────────────────────────────┤
│ Server: [Name/ID]                   │ Server Info
│ Table: [#]                          │ Table Info
│ Date: MM/DD/YYYY  Time: HH:MM       │ Date/Time
├─────────────────────────────────────┤
│ [Item Description]        $XX.XX    │
│ [Item Description]        $XX.XX    │ Line Items
│ [Special Instructions]              │ (can be long)
│                                      │
├─────────────────────────────────────┤
│ Covers: [#]                          │ Guest Count
│ Duration: [X min]                    │ Duration
├─────────────────────────────────────┤
│ Subtotal:              $XXX.XX       │
│ Tax (XX%):             $XX.XX        │ Financial Summary
│ Service Charge:        $XX.XX        │
│ TOTAL:                 $XXX.XX       │
├─────────────────────────────────────┤
│ Payment Method: [Card/Cash]          │
│ [Card Last 4 digits if card]         │
│                                      │
│ Tip Line: $_____  (if card)          │
│ FINAL TOTAL:          $XXX.XX        │
├─────────────────────────────────────┤
│ Authorization Code: XXXXXX           │
│ Receipt ID: XXXXXXXXXXX              │
│ Printed: MM/DD/YYYY HH:MM:SS         │
└─────────────────────────────────────┘
```

**Key Extractable Fields:**
- ✅ Server name/ID
- ✅ Table number
- ✅ Date and Time (ALWAYS present)
- ✅ Number of covers/guests
- ✅ Subtotal, Tax, Service Charge
- ✅ Final Total
- ✅ Payment method (Card/Cash)
- ✅ Tip amount (if paid)

**Data NOT typically on receipt:**
- ❌ Individual tip breakdown (unless itemized gratuity)
- ❌ Hour of shift (just close time)
- ❌ Manager name (only shown on closed batch reports)

**OCR Difficulty:** EASY - Modern printer, clear fonts, structured layout

---

### 2. Square (Small Business / Casual)

**Market Position:** Quick Service, Casual, Coffee Shops  
**Availability:** iPad/Android, Web Dashboard

**Typical Checkout Receipt Layout:**

```
┌─────────────────────────────────────┐
│  ☐ [Business Name]                  │ Header
│  [Address]                          │
│  [Phone]                            │
├─────────────────────────────────────┤
│ Date: MM/DD/YYYY HH:MM              │ Date/Time
│ Transaction ID: XXXXXXXXXX          │ Transaction ID
├─────────────────────────────────────┤
│ [Item Name]                  $XX.XX  │
│ [Item Name]                  $XX.XX  │ Line Items
│ [Modifier]                    +$X.XX │
│                                      │
├─────────────────────────────────────┤
│ Subtotal:                    $XXX.XX │
│ Tax:                          $XX.XX │ Financial Section
│ TOTAL:                        $XXX.XX │
├─────────────────────────────────────┤
│ Payment Method: [Type]               │
│ [Card Brand] ending in XXXX          │
│ Authorization: XXXXXX                │
│                                      │
│ Tip: $_____                          │
│ AMOUNT DUE: $XXX.XX                  │
├─────────────────────────────────────┤
│ [QR Code for online receipt]         │
│ Receipt #: XXXXX                     │
└─────────────────────────────────────┘
```

**Key Extractable Fields:**
- ✅ Business name
- ✅ Date and Time
- ✅ Subtotal, Tax, Total
- ✅ Payment method
- ✅ Item list (good for context)

**Data NOT present:**
- ❌ Server name (unless cashier entered)
- ❌ Table number (mostly counter service)
- ❌ Number of covers
- ❌ Time of day detail (just timestamp)

**Variations by Business Type:**
- **Retail:** No server info, just items & total
- **Hospitality:** May include table/server if customized
- **QSR:** Minimal info, focus on items

**OCR Difficulty:** EASY-MEDIUM - Modern printer, but can be small/faded

---

### 3. Aloha / Oracle Micros (Enterprise)

**Market Position:** Large Chains, Hotels, Casinos  
**Availability:** Terminal-based (older tech), Cloud (newer)

**Typical Checkout Receipt Layout (Legacy Aloha):**

```
┌─────────────────────────────────────┐
│ ALOHA                               │ Header
│ [Restaurant Name]                   │
│ [Location #]                        │
├─────────────────────────────────────┤
│ Check #: XXXX    Terminal: XX        │
│ Server: [Name] (#XX)                 │ Server Info
│ Table: [#]                           │ Table Info
│ Date: MM/DD/YY    Time: HH:MM        │ Date/Time
│ Covers: X                            │ Covers
├─────────────────────────────────────┤
│ [Item Description]                X │
│ [Item Description]                X │ Line Items
│ [Mods / Special Instructions]        │ (often with Qty)
│                                      │
├─────────────────────────────────────┤
│ Guest Check Total        $XXX.XX     │
│ Tax                       $XX.XX     │ Financial Section
│ Service Charge / Tip      $XX.XX     │ (tip may or may not be shown)
│ Amount Due:               $XXX.XX    │
├─────────────────────────────────────┤
│ [Payment Info if settled]            │
│ Card Last 4: XXXX                    │
│ Auth Code: XXXXXX                    │
│ Tip: $XX.XX                          │
│ TOTAL PAID:               $XXX.XX    │
├─────────────────────────────────────┤
│ [Void/Comp notes if applicable]      │
│ Printed: MM/DD/YY HH:MM:SS           │
└─────────────────────────────────────┘
```

**Key Extractable Fields:**
- ✅ Server name and ID
- ✅ Table number
- ✅ Date and Time (in MM/DD/YY format)
- ✅ Covers/Guests
- ✅ Check total, Tax, Tip, Amount Due
- ✅ Payment method if shown
- ✅ Void/Comp notes

**Data NOT always present:**
- ⚠️ Tip amount (depends on when settled)
- ⚠️ Payment details (may be on separate batch report)

**Variations:**
- **Newer Micros Touch:** More modern font, tablet-based
- **Legacy Aloha:** Older printer, sometimes dot-matrix quality
- **Multi-unit restaurants:** Check number may repeat across locations

**OCR Difficulty:** MEDIUM - Fonts can be dated, sometimes dot-matrix quality, but layout is consistent

---

### 4. Clover (Square Competitor)

**Market Position:** SMB, Retail, Casual  
**Availability:** iPad/Android tablets (similar to Square)

**Typical Checkout Receipt Layout:**

```
┌─────────────────────────────────────┐
│ [Business Name]                     │ Header
│ [Address & Phone]                   │
├─────────────────────────────────────┤
│ Date: MM/DD/YYYY  HH:MM PM          │
│ Order #: XXXXXXX                    │ Order Info
├─────────────────────────────────────┤
│ [Item Name]                  $XX.XX  │
│ [Item Name]                  $XX.XX  │ Line Items
│ [Discount/Modifier]           -$X.XX │
│                                      │
├─────────────────────────────────────┤
│ Subtotal:                     $XXX.XX│
│ Tax:                           $XX.XX│ Financial Section
│ TOTAL:                        $XXX.XX│
├─────────────────────────────────────┤
│ Tendered: [Cash/Card]               │
│ [Card last 4] [Card Brand]          │
│ Tip: $XX.XX                         │
│ TOTAL:                        $XXX.XX│
├─────────────────────────────────────┤
│ Receipt #: XXXXXXXXX                │
│ Device #: X                          │
└─────────────────────────────────────┘
```

**Key Extractable Fields:**
- Similar to Square
- ✅ Date, Time, Order #
- ✅ Items, Subtotal, Tax, Total
- ✅ Tip amount
- ✅ Payment method

**OCR Difficulty:** EASY-MEDIUM - Similar to Square

---

### 5. TouchBistro (iPad-Based)

**Market Position:** Independent Restaurants, Casual Dining  
**Availability:** iPad only, Cloud-based

**Typical Checkout Receipt Layout:**

```
┌─────────────────────────────────────┐
│ [Restaurant Name]                   │ Header
│ [Address & Phone]                   │
├─────────────────────────────────────┤
│ Check: XXXX    Server: [Name]        │
│ Table: [#]     Covers: X             │
│ Date: MM/DD/YYYY  Time: HH:MM AM/PM │
├─────────────────────────────────────┤
│ [Item Description]          $XX.XX   │
│ [Item Description]          $XX.XX   │ Line Items
│ [Modifiers]                          │
│                                      │
├─────────────────────────────────────┤
│ Subtotal:               $XXX.XX      │
│ [Discounts]:             -$XX.XX     │
│ Tax:                      $XX.XX     │ Financial
│ Service Charge (XX%):      $XX.XX    │
│ TOTAL:                   $XXX.XX     │
├─────────────────────────────────────┤
│ Payment: [Card/Cash]                 │
│ Tip: $_____  ($XX.XX if preset)      │
│ FINAL TOTAL:            $XXX.XX      │
├─────────────────────────────────────┤
│ [QR Code for digital receipt]        │
│ Printed: MM/DD/YYYY HH:MM:SS         │
└─────────────────────────────────────┘
```

**Key Extractable Fields:**
- ✅ Server name
- ✅ Table number
- ✅ Covers
- ✅ Date and Time
- ✅ All financial data (subtotal, tax, discounts, service charge, total, tip)

**OCR Difficulty:** EASY - Modern iPad printing, clear fonts

---

### 6. Handwritten / Legacy Receipts

**Market Position:** Very small restaurants, old-school establishments  
**Availability:** Manual checkout (less common now)

**Typical Layout (Handwritten):**

```
┌─────────────────────────────────────┐
│ [Restaurant name - pre-printed]      │
│                                      │
│ Server: [Handwritten]                │
│ Table: [Handwritten #]               │
│ Date: [Handwritten date]             │
│                                      │
│ Item 1:              $ [written]     │
│ Item 2:              $ [written]     │
│ Item 3:              $ [written]     │
│                                      │
│ Subtotal:            $ [written]     │
│ Tax:                 $ [written]     │
│ TOTAL:               $ [written]     │
│                                      │
│ Payment: [Cash/Card - written]       │
│ Tip: [$ - written or N/A]           │
│                                      │
│ [Server initials]                    │
└─────────────────────────────────────┘
```

**Key Extractable Fields:**
- ⚠️ Server name (handwriting quality varies)
- ⚠️ Table (can be unclear)
- ⚠️ Date (often abbreviated or unclear)
- ✅ Item count (somewhat legible)
- ✅ Total amounts (usually written clearly)
- ⚠️ Tip (if not cash)

**OCR Difficulty:** HARD - Handwriting quality varies widely, needs context clues

---

## Common Fields Across All Systems

**Fields Present in 90%+ of Receipts:**
- ✅ Total Sale Amount
- ✅ Tax Amount
- ✅ Date (format varies)
- ✅ Time (sometimes)
- ✅ Payment method (usually)
- ✅ Tip (if card payment)
- ⚠️ Server name (90% present)
- ⚠️ Table number (85% for dine-in)
- ⚠️ Number of covers (70% present)

**Optional but Important:**
- Service charge / automatic gratuity
- Discounts
- Item descriptions
- Voids / Comps
- Check/Order number
- Manager signature line

---

## OCR & AI Vision Challenges

**Easy to Extract (High Confidence):**
- Total amount - usually clear and distinct
- Date format - standardized
- Tax - clearly labeled
- Time - usually in standard format

**Medium Difficulty (Medium Confidence):**
- Server name - sometimes poorly printed or abbreviated
- Table number - can be small or unclear
- Tip amount - may be handwritten or in different location
- Number of covers - varies in format

**Difficult (Low Confidence / Context Dependent):**
- Service charge vs. tip (need context)
- Which "Total" is the right one (multiple totals sometimes shown)
- Whether payment was completed (some show auth code, some don't)
- Handwritten amounts (especially old receipts)
- Multiple tables on one receipt (some POS systems group)

**Image Quality Issues:**
- Faded printing (old receipts)
- Wrinkled/folded receipts
- Poor lighting in photo
- Blurry camera angle
- Thermal paper degradation (receipts fade over time)
- Slanted/rotated photo

---

## AI Vision Strategy

**Approach:**
1. **Primary OCR:** Use Gemini vision to extract text
2. **Layout Recognition:** Identify POS system type by layout patterns
3. **Field Extraction:** Use system type + layout to find key fields
4. **Confidence Scoring:** Rate extraction confidence (High/Medium/Low)
5. **User Review:** Show extracted data for confirmation
6. **Learning:** Store confidence scores to improve over time

**Training Data Recommendations:**
- Collect 50-100 real receipts per POS system
- Include variations: different restaurants, different amounts, different dates
- Include poor-quality photos to train robustness
- Include multi-table/multi-check receipts for edge cases

---

## Extraction Priorities (MVP)

**Must Extract (for MVP):**
1. Date
2. Total Sales Amount
3. Tip (if present)
4. Payment Method
5. Server name (if present)

**Should Extract (v1.1):**
6. Tax amount
7. Table number (if present)
8. Covers/Guests (if present)
9. Service charge (if different from tip)

**Nice to Have (v1.2+):**
10. Item list (for context)
11. Duration / Check duration
12. Void/Comp notes
13. Authorization code
14. Discount amounts

---

## Next Steps

1. **Research Completion:**
   - [ ] Collect real Toast receipts (5-10 variations)
   - [ ] Collect real Square receipts (5-10 variations)
   - [ ] Collect real Aloha receipts (5-10 variations)
   - [ ] Collect real Clover receipts (3-5 variations)
   - [ ] Collect handwritten samples (3-5 variations)
   - [ ] Create AI training dataset

2. **Prompt Engineering:**
   - [ ] Design checkout-specific extraction prompt
   - [ ] Create confidence scoring logic
   - [ ] Test with real receipt samples
   - [ ] Refine for edge cases

3. **Implementation:**
   - [ ] Build checkout scanner UI
   - [ ] Integrate Gemini vision API
   - [ ] Create review modal
   - [ ] Auto-fill shift form
   - [ ] Store checkout metadata

4. **Testing:**
   - [ ] Test with 20+ real receipts
   - [ ] Measure extraction accuracy
   - [ ] Document edge cases
   - [ ] Improve low-confidence fields

---

## Assumptions & Notes

- **Market data is estimated** based on industry reports from 2024-2025
- **Receipt layouts may vary** within each system (customization options)
- **Some fields are optional** and may not appear on all receipts
- **Handwritten receipts are rare** but still encountered
- **Modern systems are better** for OCR (clear fonts, structured layout)
- **Thermal printers** (common in restaurants) produce fading over time

---

**Status:** Research Template Complete  
**Next Action:** Begin collecting real receipt samples and building AI training dataset

