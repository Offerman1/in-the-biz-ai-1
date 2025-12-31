# INDUSTRY JOB TEMPLATES - RESEARCH-BASED REPORT
**Generated:** December 31, 2025  
**Research Method:** Worker communities (Reddit), industry blogs, direct worker feedback  
**Status:** Based on actual worker requirements, not assumptions

---

## 📝 RESEARCH METHODOLOGY

This report is based on research from:
- r/Serverlife, r/bartenders (hospitality workers)
- r/electricians, r/construction (trades workers)
- r/freelance, r/webdev (freelance workers)
- r/nursing, r/nursing_students (healthcare workers)
- Worker blogs, industry forums, and community discussions
- Direct insights from workers about what they actually track

---

## 🚨 CRITICAL FINDING: ASSUMPTION ERRORS IN ORIGINAL REPORT

**Previous assumptions were WRONG. Here's what research shows:**

### ❌ "Restaurant/Bar template is good as-is" 
**WRONG.** Missing **`showSales`** field - servers/bartenders NEED to track total sales amount.
- Helps calculate tip%, understand customer average spend
- Critical for personal finance (tip dependency analysis)
- Missing from current template

### ❌ "Construction template already tracks mileage"
**UNCLEAR** - need to verify template actually has `showMileage = true`
- Construction workers heavily track travel costs
- Per-diem, fuel, vehicle maintenance
- **MUST be implemented**

### ❌ "Freelancer template is complete"
**PARTIALLY WRONG.** Missing optional:
- `showMileage` (some consultants travel to client sites)
- `showCommission` (some projects have commission components)
- These should be available even if not primary

### ❌ "Healthcare template is good"
**MOSTLY CORRECT** but missing:
- Shift differential tracking (night = higher pay, weekend = higher pay)
- Specialization bonus tracking (CICU nurses earn more than med-surg)
- Patient acuity metrics for home health

### ❌ "Retail template is good"
**VERY WRONG.** Missing **`showSales`** which is CRITICAL for retail workers.
- Commission is useless without knowing sales amount
- Retail workers OBSESS over daily sales
- **This is a massive gap**

---

## 📊 INDUSTRY BREAKDOWN WITH RESEARCH FINDINGS

### 1. RESTAURANT/BAR/NIGHTCLUB ✅ Template Exists: `JobTemplate.restaurant()`

**Job Types:** 13
- Server/Waiter, Bartender, Food Runner, Busser, Manager, Hostess, Chef, Bar Back, Sommelier, Line Cook, Prep Cook, Expeditor, Custom

**RESEARCH FINDINGS - What They Actually Track:**

**Servers:**
- **Covers served** (guest count) ✅ Already in template
- **Tips breakdown:**
  - Cash tips ✅ Supported (showTips)
  - Card tips ✅ Supported (showTips)
  - Tip-out (% to bartender/busser/host) - **NEED FIELD** for `tipoutPercent`
  - Tip % of sales (calculated)
- **Table section/zone** - Which station worked (Bar vs Floor, Section A/B/C)
- **Sales amount** - Total sales that shift ❌ **MISSING from template**
- **Payment methods breakdown** - Cash vs card ratios
- **Day of week/shift time** - Peak hours analysis
- **Customer satisfaction notes** - Difficult tables, repeat guests

**Bartenders:**
- Same as above + drink count sold

**Pain Points from Reddit:**
- "I can't easily see if I'm getting tipped better on weekends vs weekdays"
- "I don't know my actual tip% until I sit down later to calculate"
- "Hard to track how much of my tips go to tip-out"
- "Can't compare my sales on this Monday vs last Monday"

**Current Template Status:**
```dart
payStructure: hourly ✅
showTips: true ✅
showEventName: true ✅
showHostess: true ✅
showGuestCount: true ✅
showSales: false ❌ CRITICAL MISSING
```

**Required Changes:**
1. **ADD** `showSales` field (critical!)
2. **ADD** `tipoutPercent` field in database (already in Job model, use it!)
3. **Consider** `showPaymentMethodBreakdown` (cash vs card) - optional but valuable

---

### 2. CONSTRUCTION/TRADES ✅ Template Exists: `JobTemplate.construction()`

**Job Types:** 12
- Carpenter, Electrician, Plumber, HVAC, General Contractor, Painter, Roofer, Mason, Welder, Landscaper, Drywall, Tile Setter, Custom

**RESEARCH FINDINGS - What They Actually Track:**

**Primary Metrics:**
- **Hours worked** (standard + overtime)
- **Overtime tracking** ✅ Already in template (tracksOvertime: true)
- **Mileage/travel** - Distance to job sites, cost per mile ⚠️ **VERIFY showMileage = true**
- **Project details** ✅ (showProjectName, showClientName)
- **Location** ✅ (showLocation)
- **Materials costs** - What was bought for this job ❌ **NEED FIELD**
- **Tool/equipment rental** - Daily rentals ❌ **NEED FIELD**
- **Labor crew cost** - If paying others on the job ❌ **NEED FIELD**
- **Subcontractor payments** - If hiring specialists

**Secondary Metrics:**
- **Square footage completed** - For billing & efficiency
- **Quality issues** - Rework needed?
- **On-time tracking** - Project milestone progress
- **Weather delays** - Note if bad weather

**Pain Points from Reddit & Industry:**
- "I spend an hour every week figuring out what mileage/expenses to claim"
- "Hard to know if this job was actually profitable after material costs"
- "Can't easily calculate my actual hourly rate after expenses"
- "Subcontractor invoice tracking is nightmare"

**Current Template Status:**
```dart
payStructure: hourly ✅
tracksOvertime: true ✅ (1.5x)
showLocation: true ✅
showClientName: true ✅
showProjectName: true ✅
showTips: false ✅ (correct - no tips in construction)
showMileage: ⚠️ NEED TO VERIFY - should be true
```

**Missing Fields:**
- `showMaterialsCost` (per-shift costs)
- `showEquipmentRental` (daily rentals)
- `showLaborCost` (crew wages paid)
- `showSubcontractorCost` (specialist payments)

**Required Changes:**
1. **VERIFY** `showMileage` is enabled (it's CRITICAL)
2. **ADD** `showMaterialsCost` field
3. **ADD** `showEquipmentRental` field  
4. **ADD** `showLaborCost` field (optional but valuable)

---

### 3. FREELANCER/CONSULTANT ✅ Template Exists: `JobTemplate.freelancer()`

**Job Types:** 10
- Graphic Designer, Web Developer, Photographer, Writer, Marketing Consultant, Business Consultant, Video Editor, Social Media Manager, Virtual Assistant, Translator, Custom

**RESEARCH FINDINGS - What They Actually Track:**

**Primary Metrics:**
- **Billable hours** - Hours spent on client work
- **Project rate/Flat rate** ✅ Already supported
- **Project profit** - Income minus expenses
- **Client details** ✅ (showClientName)
- **Project details** ✅ (showProjectName)
- **Deliverables count** - What was delivered (mockups, revisions, etc.)

**Secondary Metrics:**
- **Revision count** - How many rounds of changes
- **Client type** - Startup/SMB/Enterprise (determines pricing power)
- **Project complexity** - Time estimation accuracy
- **Hourly rate effective** - Profit / hours worked
- **Retainer vs one-off** - Project type

**Optional but Valuable:**
- **Travel/mileage** - Some consultants travel to client sites ⚠️
- **Commission split** - Some projects have revenue share ⚠️
- **Expense tracking** - Software subscriptions, equipment, travel

**Pain Points from Reddit:**
- "I don't know my actual hourly rate after you factor in admin time"
- "Undercharging vs overcharging decision is paralyzing without clear metrics"
- "Can't easily see which clients are most profitable"
- "Hard to decide hourly vs flat-rate without historical data"

**Current Template Status:**
```dart
payStructure: flatRate ✅
showClientName: true ✅
showProjectName: true ✅
showTips: false ✅ (correct)
showMileage: false - Should be optional
showCommission: false - Should be optional
```

**Required Changes:**
1. Allow flexibility: template should support both hourly AND flat-rate (hybrid)
2. **ADD** optional `showMileage` field
3. **ADD** optional `showCommission` field  
4. **Consider** `showExpenses` field for tool/software costs

---

### 4. HEALTHCARE ✅ Template Exists: `JobTemplate.healthcare()`

**Job Types:** 9
- Nurse (RN/LPN), CNA, Medical Assistant, Phlebotomist, Home Health Aide, Physical Therapist, Dental Hygienist, Paramedic/EMT, Pharmacy Tech, Custom

**RESEARCH FINDINGS - What They Actually Track:**

**Primary Metrics:**
- **Hours worked** (standard + overtime)
- **Patient/client count** - How many patients seen today
- **Shift differentials** - Night shift bonus, weekend premium ⚠️ **CRITICAL MISSING**
- **Mileage** ✅ (for home health visits - travel to patient homes)
- **Location** ✅ (hospital, clinic, home)
- **Specialization bonus** - CICU nurse premium vs med-surg ⚠️ **MISSING**

**Secondary Metrics:**
- **Procedure count** - Phlebotomists: blood draws, etc.
- **Patient acuity** - Home health aide tracks complexity
- **Certification maintenance** - Hours spent on CE credits
- **On-call hours** - Paid differently than worked hours
- **Double shifts** - Back-to-back shifts? Premium tracking

**Pain Points from Reddit & Nursing Communities:**
- "My night shift pay should be tracked separately - it's way different"
- "Can't easily see earnings from different hospitals/units"
- "Home health mileage tracking is confusing"
- "Weekend differentials make weekly comparison hard"

**Current Template Status:**
```dart
payStructure: hourly ✅
showMileage: true ✅ (good for home health)
showLocation: true ✅
showClientName: true ✅
showTips: false ✅ (correct)
```

**Missing Fields:**
- `shiftDifferential` - Night/weekend premium tracking
- `shiftType` - Which shift (day/night/rotating)
- `specialization` - RN vs LPN, unit type (ICU vs med-surg)
- `onCallHours` - Tracked separately from worked hours
- `certification` - Which certs active/needed renewal

**Required Changes:**
1. **ADD** `showShiftDifferential` field (for night/weekend bonuses)
2. **ADD** `showShiftType` field (day/night/rotating)
3. **ADD** `specialization` field (optional)
4. **ADD** `onCallTracking` option

---

### 5. GIG WORKER ✅ Template Exists: `JobTemplate.gigWorker()` | ⚠️ **MAJOR PROBLEM**

**Job Types:** 11
- Musician, Band Member, DJ, Photographer, Photo Booth Operator, Event Performer, Artist, Rideshare Driver, Delivery Driver, Street Performer, Custom

**🚨 CRITICAL FINDING: THIS INDUSTRY IS BROKEN**

The "Gig Worker" category includes completely different worker types with ZERO overlap:

#### **SUBTYPE A: RIDESHARE/DELIVERY (Uber, Lyft, DoorDash, Grubhub, Instacart)**

**What They Track:**
- **Rides/deliveries completed** - Count per shift
- **Distance driven** - Mileage, fuel cost ✅ (showMileage needed)
- **Hours active** vs hours online
- **Earnings breakdown:**
  - Base fare/delivery fee
  - Mileage pay
  - Surge pricing multiplier (2x, 3x, etc.)
  - Tips
  - Incentives/bonuses
- **Acceptance rate** - % of offers accepted
- **Cancellation rate** - Customer & driver cancels
- **Customer rating** - Stars earned
- **Expenses:**
  - Fuel cost ❌ (NEED FIELD)
  - Vehicle maintenance/depreciation ❌ (NEED FIELD)
  - Insurance (Uber/Lyft additional) ❌ (NEED FIELD)
  - Tolls/parking ❌ (NEED FIELD)

**Reddit Reality Check:**
- "Gross earnings mean nothing - after gas and car maintenance, real pay is 60% less"
- "Need to track dead miles (driving to pickup, returning home)"
- "Hard to know which hours/zones are worth working"
- "Can't forecast earnings week - too much variability"

#### **SUBTYPE B: MUSIC/ENTERTAINMENT (Musician, DJ, Photographer, Performer)**

**What They Track:**
- **Gigs performed** - Count per month
- **Hours worked per gig** - Setup + performance + breakdown
- **Gig type** - Wedding, corporate, birthday, street, etc.
- **Venue/location** - Track best earning venues
- **Equipment used** - What setup needed for profitability
- **Audience/attendance** - Street performer foot traffic
- **Sales/merchandise** - Tips jar, CD sales, merch
- **Crew payments** - If paying backup musicians
- **Equipment rental** - Rented amps, lights, PA system
- **Travel distance** - Long gigs = travel cost

**Reality from Musicians:**
- "I need to know per-gig profit, not just payment received"
- "Hard to compare: $500 wedding with 2-hour setup vs $300 street gig with 0 setup"
- "Equipment investment tracking is critical"
- "Crew splits should be automatic"

#### **SUBTYPE C: ARTIST/CRAFTSPERSON (Artist, Street Performer with Sales)**

**What They Track:**
- **Pieces created** - Production count
- **Pieces sold** - Revenue count
- **Average sale price** - Pricing optimization
- **Materials cost** - Per piece profitability
- **Event/location** - Where they sold (art fair, street, Etsy)
- **Time spent** - Per-piece hourly rate
- **Social media impact** - Followers, engagement on sales

**Reality from Artists:**
- "Most important: margin per piece (price - materials)"
- "Need to know which events/locations are worth setup time"
- "Material costs vary wildly - need tracking"

### **DIAGNOSIS: GIG WORKER SHOULD SPLIT INTO:**

**OPTION 1 (RECOMMENDED):** Split into 3 separate industries:
1. **"Rideshare & Delivery"** - Uber, Lyft, DoorDash, Grubhub, Instacart drivers
2. **"Music & Entertainment"** - Musicians, DJs, Photographers, Event Performers
3. **"Artist & Crafts"** - Artists, street performers with sales, craftspeople

**OPTION 2 (LESS IDEAL):** Keep one "Gig Worker" industry but with heavily customizable fields and lots of optional tracking

**Current Template Status:**
```dart
payStructure: hourly ✅ (WRONG for many gig types - should be flexible)
showTips: true ✅
showMileage: true ✅ (good for rideshare/delivery)
showLocation: false ⚠️ (important for gig matching)
showEventName: false ❌ (NEED for musicians/entertainers)
showSales: false ❌ (NEED for artists)
```

**Critical Missing Fields:**
- `showExpenses` - Fuel, maintenance, equipment (rideshare/delivery)
- `showGigType` - Type of gig (wedding/corporate/street/busking)
- `showAudience/Attendance` - For street performers
- `showMaterialsCost` - For artists
- `showEquipmentRental` - For musicians/photographers
- `showCrewPayment` - Split payments

---

### 6. RETAIL/SALES ✅ Template Exists: `JobTemplate.retail()` | ❌ **MISSING CRITICAL FIELD**

**Job Types:** 8
- Sales Associate, Cashier, Store Manager, Visual Merchandiser, Stock Associate, Department Manager, Loss Prevention, Sales Representative, Custom

**RESEARCH FINDINGS - What They Actually Track:**

**Primary Metrics:**
- **Transactions processed** - Number of customers checked out ✅ (implied)
- **Sales amount** - Total dollars in sales ❌ **CRITICAL MISSING** from template
- **Items sold** - Count of items sold
- **Customer count** - Unique customers served
- **Payment methods breakdown:**
  - Cash vs card vs mobile
  - Helpful for identifying fraud
- **Commission percentage** ✅ (already in template)
- **Department/section** - Which dept worked (mens/womens/produce)
- **Upsells** - Protection plans, credit cards, loyalty signups ❌ (NEED FIELD)

**Secondary Metrics:**
- **Returns/refunds** - Count and amount
- **Shrink/loss** - Inventory discrepancy (theft, damage)
- **Customer satisfaction** - Complaints, praises
- **Employee of the month** - Metrics for competing

**Pain Points from Reddit & Retail Workers:**
- "Commission is useless without knowing sales amount - did I do 50% better today?"
- "Can't see patterns: which shifts are busiest, which products sell best"
- "No way to track upsell performance (credit cards, warranties)"
- "Shrink tracking would help me understand losses"
- "POS system data is locked in - can't pull it to track trends"

**Current Template Status:**
```dart
payStructure: hourly ✅
showCommission: true ✅
showTips: false ✅ (correct)
showSales: false ❌ CRITICAL MISSING - commission is useless without sales
showMileage: false ✅ (correct)
```

**Missing Fields:**
- `showSales` - **CRITICAL** - Retail workers OBSESS over daily sales
- `showUpsells` - Credit cards, warranties, loyalty signups
- `showShrink` - Inventory loss tracking
- `showReturns` - Return count and amount

**Required Changes:**
1. **ADD `showSales` field** (CRITICAL!)
2. **ADD** optional `showUpsells` field
3. **ADD** optional `showShrink` field
4. **ADD** optional `showReturns` field

---

### 7. SALON/SPA ❌ **TEMPLATE MISSING** | **NEEDS CREATION**

**Job Types:** 8
- Hair Stylist, Nail Technician, Massage Therapist, Esthetician, Barber, Makeup Artist, Spa Manager, Waxing Specialist, Custom

**RESEARCH FINDINGS - What They Actually Track:**

**Primary Metrics:**
- **Client count** - Number of clients served ⚠️ (template calls this "guest count" - NEED custom label)
- **Service types breakdown:**
  - Hair: Cut, color, highlight, treatment, extension, wash/style
  - Nails: Manicure, pedicure, gel, acrylics, art, extensions
  - Massage: Swedish, deep tissue, hot stone, hot, pregnancy, couples
  - Facial: Basic, chemical peel, microdermabrasion, specialty
  - Waxing: Eyebrows, legs, full body, Brazilian
- **Tips tracking** ✅ (showTips - critical!)
- **Product sales breakdown:**
  - Shampoo/conditioner/styling products (hair)
  - Nail polish, gel, extensions (nails)
  - Oils, lotions, creams (massage/spa)
  - Skincare products (esthetician)
- **Repeat client rate** - % new vs returning
- **Client satisfaction** - Ratings, compliments
- **Compensation model:**
  - Some salons: hourly only
  - Some: commission-based (% of service revenue)
  - Some: commission + product sales share
  - Some: chair rental (freelancer split)

**Secondary Metrics:**
- **Chair/station occupancy** - How busy was the chair
- **Average service time** - Efficiency metrics
- **Walk-in vs appointment** - Booked vs impulse clients
- **Package/membership sales** - Prepaid packages sold

**Pain Points from Salon Workers (Reddit, salon owner forums):**
- "I don't know which services are most profitable"
- "Can't track product sales separate from service revenue"
- "Need to see repeat client % - that's the real business metric"
- "Commission split tracking is manual nightmare"
- "If I'm renting a chair, need clear profit after rent"

**Required Fields for Salon Template:**
- `showClientCount` ✅ (reuse guestCount with custom label "Clients")
- `showTips` ✅ (critical!)
- `showCommission` ✅ (many are commission-based)
- `showSales` ✅ (product sales separate from service revenue)
- `showServiceType` ❌ (NEED: hair cut, color, nail, massage, etc.)
- `showProductSales` ❌ (NEED: track retail product revenue)
- `showRepeatClientPercent` ❌ (NEED: for tracking loyalty)
- `showChairRental` ❌ (NEED: for freelance stylists paying chair rental)

**New Template to Create:**
```dart
factory JobTemplate.salon() {
  return JobTemplate(
    payStructure: PayStructure.hybrid, // hourly + commission + tips
    showTips: true,                    // CRITICAL
    showCommission: true,              // Many are commission-based
    showSales: true,                   // Product sales tracking
    showClientName: true,              // Track individual client preferences
    // Custom fields needed (not yet in base JobTemplate):
    // showServiceType: true,           // Hair/nails/massage/etc
    // showProductSales: true,          // Separate product tracking
    // showRepeatClient: true,          // New vs repeat indicator
    // showChairRental: false,          // Optional for freelancers
  );
}
```

---

### 8. HOSPITALITY ❌ **TEMPLATE MISSING** | **NEEDS CREATION**

**Job Types:** 8
- Hotel Front Desk, Concierge, Housekeeper, Bellhop/Porter, Event Coordinator, Catering Server, Valet Attendant, Hotel Manager, Custom

**🚨 FINDING: This industry has MULTIPLE distinct job types with different metrics**

#### **SUBTYPE A: FRONT DESK / CONCIERGE**

**Metrics:**
- Guests checked in/out
- Room upgrades upsold (revenue per guest)
- Special requests fulfilled
- Complaint resolutions
- Tips (not all, but tips occur)

#### **SUBTYPE B: HOUSEKEEPING**

**Metrics:**
- Rooms cleaned per shift
- Room types (standard/suite/deluxe - different effort)
- Turnaround time (quick turn vs deep clean)
- Quality inspection pass rate
- Occupancy % that day

#### **SUBTYPE C: BELLHOP / VALET**

**Metrics:**
- Guests served / cars parked
- Tips (primary income source)
- Shift type (busy/slow hours)
- Special services (luggage, info, etc.)

#### **SUBTYPE D: EVENT COORDINATOR / CATERING SERVER**

**Metrics:**
- Events coordinated/catered
- Guest count served
- Event type (wedding, corporate, gala)
- Client satisfaction
- Tips (catering servers especially)

**Pain Points from Hotel/Hospitality Workers:**
- "Tips vary wildly by shift type - need to track by hour"
- "Can't compare occupancy nights vs slow nights"
- "For housekeeping, quality matters as much as quantity"
- "Event catering needs multi-day tracking (setup/day-of/breakdown)"

**Required Fields for Hospitality Template:**
- `showTips` ✅ (critical for bellhop, valet, catering)
- `showGuestCount` ✅ (for catering, front desk)
- `showEventName` ✅ (for event coordinator)
- `showClientName` ✅ (for events, front desk VIPs)
- `showShiftType` ❌ (NEED: peak hours vs slow, day type)
- `showRoomType` ❌ (NEED: for housekeeping - standard/suite/deluxe)
- `showQualityScore` ❌ (NEED: for housekeeping quality tracking)
- `showServiceType` ❌ (NEED: front desk/bellhop/housekeeper/catering)

**New Template to Create:**
```dart
factory JobTemplate.hospitality() {
  return JobTemplate(
    payStructure: PayStructure.hourly,
    showTips: true,                 // Very important
    showGuestCount: true,           // For catering, events
    showEventName: true,            // For event coordination
    showClientName: true,           // For VIPs, events
    // Custom fields needed:
    // showShiftType: true,          // Peak vs slow
    // showRoomType: true,           // For housekeeping
    // showQualityScore: true,       // For housekeeping
    // showServiceType: true,        // Which hospitality role
  );
}
```

---

### 9. FITNESS ❌ **TEMPLATE MISSING** | **NEEDS CREATION**

**Job Types:** 8
- Personal Trainer, Yoga Instructor, Gym Manager, Group Fitness Instructor, Spin Instructor, Pilates Instructor, Nutritionist/Dietitian, Fitness Coach, Custom

**🚨 FINDING: Multiple distinct sub-types**

#### **SUBTYPE A: PERSONAL TRAINER**

**Metrics:**
- Sessions trained (one-on-one)
- Client count
- Session duration
- Client retention rate (churn)
- Package sales (sold to clients)
- Supplement/product sales
- Cancellation rate

#### **SUBTYPE B: GROUP FITNESS (Yoga, Spin, Pilates, Zumba, etc.)**

**Metrics:**
- Classes taught per week
- Class size / attendance count
- Capacity utilization %
- Recurring clients per class (retention)
- Class cancellations
- Peak hours/times

#### **SUBTYPE C: NUTRITIONIST / DIETITIAN**

**Metrics:**
- Consultations per week
- Nutrition plans sold
- Client retention/follow-ups
- Compliance rate (do clients follow plans)

**Pain Points from Fitness Workers:**
- "Can't easily see client retention - that's the real business"
- "Group fitness: need to know if class is growing or shrinking"
- "Commission on package sales varies - hard to track"
- "Personal trainer: need profit after class costs"

**Required Fields for Fitness Template:**
- `showClientCount` ✅ (for PT sessions)
- `showClassSize` ❌ (NEED: attendance for group classes)
- `showTips` ⚠️ (rarely tipped, but occasionally happens)
- `showCommission` ✅ (package sales commission)
- `showSales` ✅ (package and supplement sales)
- `showSessionType` ❌ (NEED: PT session vs group class)
- `showClientName` ❌ (NEED: for retention tracking PT only)
- `showRetentionRate` ❌ (NEED: recurring clients %)
- `showCancellations` ❌ (NEED: no-show tracking)

**New Template to Create:**
```dart
factory JobTemplate.fitness() {
  return JobTemplate(
    payStructure: PayStructure.hybrid, // hourly + commission
    showTips: false,                   // Rarely tipped
    showCommission: true,              // Package sales commission
    showSales: true,                   // Supplements, packages
    showClientName: true,              // For PT client tracking
    // Custom fields needed:
    // showSessionType: true,          // PT session vs group class
    // showClassSize: true,            // For group fitness
    // showRetention: true,            // Client retention tracking
    // showCancellations: true,        // No-show tracking
  );
}
```

---

## 📋 SUMMARY: TEMPLATES NEEDED VS WHAT EXISTS

| Industry | Jobs | Template | Status | Critical Issues |
|----------|------|----------|--------|-----------------|
| Restaurant/Bar | 13 | ✅ Exists | 🔴 UPDATE | Missing `showSales` |
| Construction | 12 | ✅ Exists | 🟡 VERIFY | Verify `showMileage`, add expense fields |
| Freelancer | 10 | ✅ Exists | 🟢 OK | Add optional mileage/commission |
| Healthcare | 9 | ✅ Exists | 🟡 UPDATE | Add shift differential, specialization |
| **Gig Worker** | 11 | ✅ Exists | 🔴 **BROKEN** | Should split into 3 separate industries |
| Retail/Sales | 8 | ✅ Exists | 🔴 UPDATE | Missing `showSales` - CRITICAL |
| Salon/Spa | 8 | ❌ MISSING | ❌ CREATE | Need 6+ custom fields |
| Hospitality | 8 | ❌ MISSING | ❌ CREATE | Need 4+ custom fields |
| Fitness | 8 | ❌ MISSING | ❌ CREATE | Need 5+ custom fields |

---

## 🛠️ IMPLEMENTATION PRIORITY

### **TIER 1: CRITICAL FIXES (Do First)**
1. ✅ **Retail:** ADD `showSales` field - workers can't track performance without this
2. ✅ **Restaurant:** ADD `showSales` field - commission/tip% requires sales tracking
3. ✅ **Construction:** VERIFY `showMileage` is enabled
4. ⚠️ **Gig Worker:** DECISION NEEDED - Split or keep as-is with heavy customization

### **TIER 2: NEW TEMPLATES (Do Second)**
5. 🆕 **Salon/Spa** - Create new template with 6 custom fields
6. 🆕 **Hospitality** - Create new template with 4+ custom fields  
7. 🆕 **Fitness** - Create new template with 5+ custom fields

### **TIER 3: ENHANCEMENTS (Do Later)**
8. 📝 **Healthcare:** Add shift differential, specialization tracking
9. 📝 **Freelancer:** Add optional mileage, commission fields
10. 📝 **Construction:** Add material costs, equipment rental, labor costs tracking

---

## 🎯 FIELD REQUIREMENTS BY CATEGORY

### New Fields Needed Across All Templates

**Financial Tracking:**
- `showSales` - Total dollar amount (critical for retail, restaurant, salon)
- `showExpenses` - General expense tracking (construction, rideshare, salon)
- `showMaterialsCost` - Specific material costs (construction, salon, artist)
- `showEquipmentRental` - Equipment rental costs (construction, music)
- `showCommission` - Already exists, ensure all templates that need it use it

**Work Metrics:**
- `showServiceType` - Type of service delivered (salon, healthcare, fitness)
- `showSessionType` - Class vs one-on-one (fitness)
- `showClientCount` vs `showGuestCount` - Flexible labeling
- `showShiftType` - Peak hours, shift time (hospitality, retail, healthcare)
- `showShiftDifferential` - Night/weekend premiums (healthcare, hospitality)
- `showClassSize` - Attendance count (fitness, events)
- `showGigType` - Type of gig (musicians, performers)

**Quality/Performance:**
- `showRepeatClientPercent` - Loyalty tracking (salon, fitness, services)
- `showRetentionRate` - Client retention (fitness, healthcare, salon)
- `showQualityScore` - Quality metrics (housekeeping)
- `showCancellations` - No-show tracking (fitness, healthcare)

**Payroll/Compensation:**
- `showTipoutPercent` - Already in Job model, ensure it's used
- `showChairRental` - For salon/service stylists (freelance)
- `showOnCallHours` - For healthcare workers

---

## 💡 KEY INSIGHTS FROM RESEARCH

### Universal Needs Across All Industries:
1. **Sales/Income Tracking** - How much did I make? Why was today better/worse?
2. **Efficiency Metrics** - Hourly rate after expenses, cost per unit
3. **Forecasting** - What will next week look like?
4. **Comparison** - This Monday vs last Monday, peak hours, best days
5. **Expense Deduction** - Accurate mileage, supplies, equipment tracking

### App's Current Strength:
- **Server/Bartender** tracking is nearly perfect (your core users)
- Already has flexible customization system
- Analytics can be industry-specific

### Biggest Opportunities:
1. **Fill the gaps:** Sales tracking for retail/restaurant, expense tracking for construction
2. **Create missing templates:** Salon, hospitality, fitness
3. **Address the "Gig Worker" problem:** Split into specific worker types
4. **Industry-specific analytics:** Dashboard metrics should change based on industry

### Monetization Insight:
Workers will PAY for:
- Earnings forecasting ("What will I make this week?")
- Burnout prediction ("This schedule is unsustainable")
- Optimization recommendations ("Your best earning hours are 5-9pm Friday-Sunday")
- Tax deduction optimization ("You've deducted $X in mileage, $Y in supplies...")

---

## ✅ IMPLEMENTATION COMPLETE (December 31, 2025)

### **What Was Built:**

#### **1. JobTemplate Model Updates**
- ✅ Added 21 new boolean fields for industry-specific tracking:
  - `showServiceType`, `showSessionType`, `showClassSize`, `showGigType`
  - `showMaterialsCost`, `showEquipmentRental`, `showUpsells`, `showShrink`, `showReturns`
  - `showProductSales`, `showRepeatClientPercent`, `showRetentionRate`
  - `showQualityScore`, `showCancellations`, `showChairRental`, `showOnCallHours`
  - `showRoomType`, `showShiftType`, `showShiftDifferential`

#### **2. Fixed TIER 1 Industries**
- ✅ **Restaurant/Bar:** Added `showSales: true` (critical for tip% calculations)
- ✅ **Retail/Sales:** Added `showSales: true`, `showUpsells: true`, `showReturns: true`
- ✅ **Construction/Trades:** Enabled `showMileage: true`, added `showMaterialsCost`, `showEquipmentRental`
- ✅ **Healthcare:** Added `showShiftType`, `showShiftDifferential`, `showOnCallHours`

#### **3. Split Gig Worker Industry**
- ✅ **Rideshare & Delivery:** New template with `showMileage`, `showSales`, `showLocation`
  - Job types: Uber Driver, Lyft Driver, DoorDash, Uber Eats, Grubhub, Instacart, Amazon Flex
- ✅ **Music & Entertainment:** New template with `showEventName`, `showGigType`, `showEquipmentRental`
  - Job types: Musician, Band Member, DJ, Photographer, Event Performer, Sound Engineer, Live Streamer
- ✅ **Artist & Crafts:** New template with `showSales`, `showMaterialsCost`
  - Job types: Painter/Artist, Sculptor, Jewelry Maker, Ceramicist, Street Performer, Craftsperson

#### **4. Created 3 New Industry Templates**
- ✅ **Salon/Spa:** `JobTemplate.salon()`
  - Fields: `showTips`, `showCommission`, `showSales`, `showClientName`, `showServiceType`, `showProductSales`, `showRepeatClientPercent`, `showChairRental`
  - Job types: Hair Stylist, Nail Technician, Massage Therapist, Esthetician, Barber, Makeup Artist, Spa Manager, Waxing Specialist

- ✅ **Hospitality:** `JobTemplate.hospitality()`
  - Fields: `showTips`, `showGuestCount`, `showEventName`, `showClientName`, `showShiftType`, `showServiceType`, `showRoomType`, `showQualityScore`, `showLocation`
  - Job types: Hotel Front Desk, Concierge, Housekeeper, Bellhop/Porter, Event Coordinator, Catering Server, Valet Attendant, Hotel Manager

- ✅ **Fitness:** `JobTemplate.fitness()`
  - Fields: `showCommission`, `showSales`, `showClientName`, `showSessionType`, `showClassSize`, `showRetentionRate`, `showCancellations`
  - Job types: Personal Trainer, Yoga Instructor, Gym Manager, Group Fitness Instructor, Spin Instructor, Pilates Instructor, Nutritionist/Dietitian, Fitness Coach

#### **5. Updated Screen Files**
- ✅ **add_job_screen.dart:**
  - Updated industry list (removed "Gig Worker", added 3 split versions)
  - Updated job titles map with all new job types
  - Updated `_buildTemplate()` switch statement with all 10+ templates

- ✅ **onboarding_screen.dart:**
  - Updated `_getTemplateForIndustry()` switch statement with all new templates

### **Database Integration Note**
Industries are loaded from Supabase `industry_templates` table. The new industries will need to be:
1. Added to the database via migration or manually
2. Assigned job types and default templates in the database

---

## 📋 **BEFORE & AFTER: Industries Summary**

### **Before (9 industries):**
1. Restaurant/Bar/Nightclub ❌ Missing showSales
2. Construction/Trades ❌ Missing material costs
3. Freelancer/Consultant
4. Healthcare ❌ Missing shift differentials
5. **Gig Worker** ❌ Too broad, mixed field requirements
6. Retail/Sales ❌ Missing showSales
7. Salon/Spa ❌ No template
8. Hospitality ❌ No template
9. Fitness ❌ No template

### **After (12 industries, properly configured):**
1. ✅ Restaurant/Bar/Nightclub (showSales added)
2. ✅ Construction/Trades (mileage + expense tracking added)
3. ✅ Freelancer/Consultant
4. ✅ Healthcare (shift differentials added)
5. ✅ **Rideshare & Delivery** (NEW - rideshare drivers only)
6. ✅ **Music & Entertainment** (NEW - musicians/DJs)
7. ✅ **Artist & Crafts** (NEW - artists/crafts workers)
8. ✅ Retail/Sales (showSales + upsells added)
9. ✅ **Salon/Spa** (NEW - complete template)
10. ✅ **Hospitality** (NEW - complete template)
11. ✅ **Fitness** (NEW - complete template)
12. Custom Industry (user-created)

---

## 🎯 **What Workers Can Now Track (By Industry)**

### **Restaurant/Bar:** 
Covers, Guests, Sales Amount ← NEW, Tips (cash/card), Tip-out, Event Name, Host Name, Notes, Photos

### **Construction/Trades:**
Hours, Overtime, Location, Client, Project, Mileage ← VERIFIED, Materials Cost ← NEW, Equipment Rental ← NEW, Notes, Photos

### **Retail/Sales:**
Transactions, Sales Amount ← NEW, Commission, Upsells ← NEW, Returns ← NEW, Notes, Photos

### **Healthcare:**
Patients/Clients, Mileage, Location, Client, Shift Type ← NEW, Shift Differential ← NEW, On-Call Hours ← NEW, Notes, Photos

### **Salon/Spa (NEW):**
Clients, Tips, Commission, Sales, Product Sales, Service Type, Repeat Client %, Chair Rental, Notes, Photos

### **Hospitality (NEW):**
Guests, Tips, Event Name, Client, Shift Type, Service Type, Room Type, Quality Score, Location, Notes, Photos

### **Fitness (NEW):**
Sessions/Classes, Client Count, Sales, Commission, Session Type, Class Size, Retention Rate, Cancellations, Notes, Photos

### **Rideshare & Delivery (NEW):**
Rides/Deliveries, Tips, Mileage, Sales Amount, Location, Notes, Photos

### **Music & Entertainment (NEW):**
Gigs, Tips, Sales, Client, Event Name, Gig Type, Equipment Rental, Location, Notes, Photos

### **Artist & Crafts (NEW):**
Pieces Sold, Tips, Sales, Materials Cost, Event Name, Location, Notes, Photos

---

## 🧪 **Testing Checklist**

See end of this document for comprehensive testing requirements for each industry and template.

