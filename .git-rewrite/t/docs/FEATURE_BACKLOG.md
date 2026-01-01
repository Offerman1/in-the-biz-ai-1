# 📦 Feature Backlog - In The Biz AI

**Future features not yet scheduled for MVP (Version 1.0)**

**Last Updated:** December 27, 2025

---

## 💰 MONETIZATION STRATEGY

**See:** [MONETIZATION_STRATEGY.md](./MONETIZATION_STRATEGY.md) for complete details.

**Summary:**
- **Free Tier:** Ad-supported with hard limits (500 photos, 50 AI messages/month, 10 AI scans/month)
- **Pro Tier:** $4.99/month - Unlimited everything, no ads
- **Projected Profit:** $858/month with 1000 users (15% conversion)
- **Blended Average:** ~$0.86/user/month profit

**Key Optimizations:**
- **Bandwidth is FREE** until 30K+ users (within 250GB Supabase free tier)
- **Collapsible photo sections** - Load only when expanded
- **Thumbnails-first** (100KB) - 30x smaller than full images
- **Smart AI routing** - Flash-Lite for simple queries (10x cheaper)
- **Device caching** - Repeat views cost nothing

**Per-User Economics (REALISTIC):**
- Free user cost: $0.078/month (storage + AI, bandwidth FREE)
- Free user revenue: $0.28/month (15 shifts/month avg)
- Free user profit: $0.20/month (72% margin)
- Pro user profit: $4.57/month (92% margin)

**Reality Check:**
- Most users work 10-15 shifts/month (not 30)
- Users view photos 2-3x/day (not 20+)
- Bandwidth stays free until massive scale (30K+ users)

---

## 📋 PLANNED AI FEATURES (Q2 2026)
### 8. **AI Vision - Server Checkout Reader** 🆕 PLANNED (Q2 2026)
📋 **Full Spec:** [AI_VISION_FEATURES.md](./AI_VISION_FEATURES.md#feature-1-ai-vision-server-checkout-sheet-reader)

**Priority:** HIGH - Post-Launch  
**Effort:** 3-4 days  
**Cost:** ~$0.001 per scan (recurring)

**What It Does:**
- Take photo of restaurant checkout sheet
- AI extracts: Total Sales, Tipout, Tipout %, Net Tips, Gross Tips
- Handles different restaurant formats (Aloha, Toast, Square, handwritten)
- Auto-fills shift form with extracted data
- Confidence indicators (green/yellow/red)
- Error reporting when format is unknown

**AI Model:** Gemini 3 Flash Preview (with vision)  
**Pricing:** $0.50/1M input tokens (includes images), $3.00/1M output  
**Why This Model:** Superior OCR + semantic understanding, handles messy formats

**Business Impact:**
- Data entry time: 5 minutes → 30 seconds (90% reduction)
- Eliminates manual entry errors
- Competitive moat (few apps have this)

### 9. **AI Vision - Invoice Import** 🆕 PLANNED (Q2 2026)
📋 **Full Spec:** [AI_VISION_FEATURES.md](./AI_VISION_FEATURES.md#feature-2-ai-invoice-import)

**Priority:** MEDIUM - TAM Expansion  
**Effort:** 3-4 days  
**Cost:** ~$0.001 per invoice (recurring)

**What It Does:**
- Scan invoices/receipts (photos or PDFs)
- AI extracts: Client, Amount, Date, Service, Payment Terms
- Auto-creates shift/job entry with "Pending Payment" status
- Payment tracking (pending → paid)
- Overdue alerts
- Dashboard shows pending vs paid income

**AI Model:** Gemini 3 Flash Preview (with vision)  
**Pricing:** Same as Server Checkout  
**Why This Model:** Document understanding, multi-format support

**Target Users:**
- Freelancers (designers, developers, writers)
- Independent contractors (plumbers, electricians)
- Consultants and coaches
- Photographers, videographers

**Business Impact:**
- Expands TAM to freelancers (huge market)
- Recurring feature (10-20 invoices/month)
- Higher LTV users
- Stickier product (core workflow tool)

**Cost per Freelancer:** 10 invoices/month × $0.001 = $0.01/month (negligible)

---

### 10. **Photo Gallery & Search** ⚠️ PARTIAL
- ✅ View all photos from past shifts (PhotoViewerScreen)
- ⚠️ AI search: "Show me all buffet setups from December" - NOT YET
- ⚠️ Tag photos (e.g., #wedding #cocktailhour) - NOT YET
- ✅ View all photos from past shifts (PhotoViewerScreen)
- ⚠️ AI search: "Show me all buffet setups from December" - NOT YET
- ⚠️ Tag photos (e.g., #wedding #cocktailhour) - NOT YET

---

## 🔴 NOT STARTED (Still in Backlog)

### 5. **Tip Out Analytics Dashboard**
- Total tipped out over time (weekly, monthly, yearly)
- Breakdown by recipient ("Dishwasher: $80 over 4 shifts")
- Average tipout per shift
- Sales efficiency metrics (tips per $100 sold)
- **Priority:** Medium (nice-to-have analytics)
- **Status:** ⚠️ PARTIAL (calculations done, dashboard card not built)

### 6. **Hot Schedules / 7shifts Integration**
- **Status:** ✅ SOLVED VIA CALENDAR SYNC
- Users enable "Sync to Calendar" in their scheduling app (Hot Schedules, 7shifts, When I Work)
- App imports shifts from device calendar
- **Note:** Direct API integration not available for third-party apps

### 7. **Social Features**
- Anonymous benchmarking ("You made more than 70% of servers this week")
- Share achievements (opt-in)
- **Priority:** Low (post-launch)
- **Status:** ❌ NOT STARTED

### 8. **Integrations**
- Export to QuickBooks/Mint
- Connect to payroll systems (ADP, Paychex)
- **Priority:** Low (enterprise feature)
- **Status:** ❌ NOT STARTED

### 10. **Voice Memo Attachments**
- Record voice notes for shifts
- "Today was crazy, we had a 200-person party..."
- Transcribe to text automatically
- **Priority:** Medium (convenience feature)
- **Status:** ❌ NOT STARTED

### 11. **Bulk Edit Shifts**
**Description:** Advanced feature to bulk update shifts by date range or filter criteria.

**Use Cases:**
- Update hourly rates for specific months (e.g., "I had training pay in March")
- Bulk edit shifts from a specific job during a date range
- Apply changes to filtered shift sets

**Implementation:**
- Filter UI: Date range picker, job selector, custom filters
- Preview selected shifts before applying changes
- Bulk update: hourly rate, job, tags, or other fields
- Undo/rollback functionality

**Why in Backlog:**
- Most users can handle this with "All existing shifts" option when editing job
- Per-shift overrides handle edge cases (training pay, manager shifts)
- Complex UI required for date range selection and filtering
- Edge case feature - 95% of users won't need it

**Priority:** Low (advanced feature, edge case)
**Status:** ❌ NOT STARTED

---

## 🟡 PARTIALLY COMPLETE (Needs More Work)

| Feature | Done | Still Needed |
|---------|------|--------------|
| **Goal Notifications** | Progress bar | Push notifications |
| **AI Custom Templates** | Industry selection | AI-generated fields |
| **Photo AI Search** | Gallery view | AI-powered search & tagging |

---

## 📊 Summary

| Category | Count |
|----------|-------|
| ✅ **Fully Complete** | 9 features |
| 🟡 **Partially Complete** | 3 features |
| ❌ **Not Started** | 6 features |

### High Priority Items Still Needed:
1. **Paywall/Monetization** - RevenueCat integration
2. **Push Notifications** - For goal milestones
3. **AI Photo Search** - "Show me buffet photos"
4. **Tip Out Analytics Dashboard** - Visual breakdown card (calculations done)
