# 🎨 In The Biz AI - Complete UX/UI Design Spec

**Design Language:** Cash App Style (Bold, Modern, Dark Theme)
**Last Updated:** December 24, 2025

---

## 🎨 VISUAL DESIGN SYSTEM

### **Color Palette (Cash App Inspired):**
- **Primary:** Vibrant Green (#00D632 or similar)
- **Background:** Dark Gray/Black (#121212 or #1C1C1E)
- **Cards:** Slightly lighter gray (#2C2C2E)
- **Text:** White (#FFFFFF) and Light Gray (#E5E5EA)
- **Accents:** Bright green for money, tips, positive actions

### **Typography:**
- **Headers:** Bold, sans-serif (SF Pro Display or similar)
- **Body:** Regular sans-serif
- **Numbers:** Bold, large for income amounts

### **Design Elements:**
- Rounded corners on all cards (16px radius)
- Subtle shadows/elevation
- Smooth animations (slide, fade)
- Minimalist icons
- Generous padding/spacing

---

## 📱 BOTTOM NAVIGATION (4 Tabs)

```
┌──────────┬──────────┬──────────┬──────────┐
│ 🏠 Home  │ 📅 Calendar │ 💬 Chat │ 📊 Stats │
└──────────┴──────────┴──────────┴──────────┘
```

1. **Home/Dashboard** - Quick overview, recent shifts
2. **Calendar** - THE COMMAND CENTER (most used screen)
3. **Chat** - AI Assistant + Camera + Voice (WhatsApp style)
4. **Stats** - Analytics, charts, trends

---

## 🏠 SCREEN 1: DASHBOARD (HOME)

### **Purpose:** Quick overview of recent activity

### **Layout:**
```
┌─────────────────────────────────────┐
│  In The Biz AI               [+] [⚙]│
├─────────────────────────────────────┤
│  💰 Total This Week                 │
│     $1,247.50                       │
│     ↑ 23% from last week            │
├─────────────────────────────────────┤
│  Recent Shifts                      │
│  ┌─────────────────────────────┐   │
│  │ Dec 23  •  $250  •  8hrs    │   │
│  │ "John's Wedding Reception"  │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Dec 22  •  $180  •  6hrs    │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### **Elements:**
- **Big Income Number** - Front and center (Cash App style)
- **Trend Indicator** - "↑ 23% from last week" (green if up, red if down)
- **Recent Shifts List** - Last 5 shifts with tap to see details
- **[+] Button** - Top right, manually add shift
- **[⚙] Settings** - Top right, app settings

### **No Floating Camera Button** - Removed! Camera is in Chat tab

---

## 📅 SCREEN 2: CALENDAR (THE COMMAND CENTER) ⭐

### **Purpose:** Primary navigation hub - see all shifts at a glance

### **View Modes (Toggle at top):**
```
┌─────────────────────────────────────┐
│  [Month] [Week] [Year]       Dec ▼  │
├─────────────────────────────────────┤
```

---

### **MONTH VIEW (Default):**

```
    Sun   Mon   Tue   Wed   Thu   Fri   Sat
    ───   ───   ───   ───   ───   ───   ───
     1     2     3     4     5     6     7
                             $120  $200  $150
                             6h    8h    7h
     
     8     9    10    11    12    13    14
    $180  $210  ---   $160  $180  ---   ---
    8h    9h          7h    8h
```

### **Day Display (When shift exists):**
- Small **badge** showing total tips (e.g., "$180")
- Small **indicator** showing hours (e.g., "8h")
- Maybe **color intensity** based on income (darker = more $)
- Optional: Icon for shift type (if multi-job support later)

### **Day Display (Future scheduled shifts - from Hot Schedules/Google):**
- **Outlined/lighter color** to show "scheduled but not worked yet"
- Show scheduled hours
- Tap to add notes or pre-fill details

### **Empty Days:**
- Plain, gray, no details

---

### **WEEK VIEW:**
```
┌─────────────────────────────────────┐
│  Mon Dec 16                         │
│  $250 • 8hrs • John's Wedding       │
│  [Photos: 3] [Notes ✓]              │
├─────────────────────────────────────┤
│  Tue Dec 17                         │
│  $180 • 6hrs • Lunch Shift          │
│  [Photos: 1]                        │
├─────────────────────────────────────┤
│  Wed Dec 18                         │
│  No shifts                          │
├─────────────────────────────────────┤
```

- Shows 7 days in vertical list
- More details per day than month view
- Quick tap to see full day details

---

### **YEAR VIEW:**
```
┌─────────────────────────────────────┐
│  2024 Total: $48,500                │
├─────────────────────────────────────┤
│  January    $7,200   [→]            │
│  February   $4,100   [→]            │
│  March      $5,800   [→]            │
│  April      $3,200   [→]            │
│  ...                                │
│  December   $6,000   [→]            │
└─────────────────────────────────────┘
```

- Shows all 12 months as cards
- Total income per month
- Tap to jump to that month in Month View

---

### **TAP A DAY → DETAIL SCREEN:**

Opens a **beautiful full-screen modal** with everything:

```
┌─────────────────────────────────────┐
│  ← December 16, 2024                │
├─────────────────────────────────────┤
│  💰 $250.00                         │
│  Total Tips                         │
├─────────────────────────────────────┤
│  Breakdown                          │
│  Cash Tips:    $120.00              │
│  Credit Tips:  $130.00              │
│  Hours Worked: 8.0 hrs              │
│  Hourly Rate:  $15.00               │
├─────────────────────────────────────┤
│  Event Details                      │
│  "John's Wedding Reception"         │
│  Hostess: Sarah Johnson             │
│  Guest Count: 120                   │
├─────────────────────────────────────┤
│  Photos (3)                         │
│  [📷] [📷] [📷]                      │
├─────────────────────────────────────┤
│  Notes                              │
│  "Great party, bride tipped extra!" │
├─────────────────────────────────────┤
│  [Edit] [Delete]                    │
└─────────────────────────────────────┘
```

### **Elements:**
- **Big income number** at top (Cash App style)
- **Breakdown section** - cash, credit, hours, rate
- **Event details** - party name, hostess, guest count (if entered)
- **Photo gallery** - Tap to view full-screen carousel
- **Notes section** - User's memories/details
- **Edit/Delete buttons** at bottom

---

### **SCROLLING:**
- **Scroll up** = go back in time (Nov 2024, Oct 2024...)
- **Scroll down** = future (Jan 2025, Feb 2025...)
- Infinite scroll both directions
- Fast jump: Tap month/year dropdown at top

---

## 💬 SCREEN 3: CHAT (AI ASSISTANT) - WhatsApp Style

### **Purpose:** Talk to "Biz" AI + Take photos + Voice messages

### **Layout:**
```
┌─────────────────────────────────────┐
│  ← Biz                        [⋮]   │
├─────────────────────────────────────┤
│  [AI Bubble - Left]                 │
│  Hey! How much did you make today?  │
│  10:23 AM                           │
│                                     │
│              [User Bubble - Right]  │
│              I made $180 tonight!   │
│                          10:24 AM   │
│                                     │
│  [AI Bubble - Left]                 │
│  Nice! That's $180 in tips. Want me │
│  to log that for you?               │
│  10:24 AM                           │
├─────────────────────────────────────┤
│  📎  📷  🎤  [Message...]    ➤ Send │
└─────────────────────────────────────┘
```

### **Message Bubbles:**
- **User messages:** Right side, green bubbles (Cash App green)
- **AI messages:** Left side, dark gray bubbles
- **Timestamps** below each message
- **Typing indicator** when AI is thinking

---

### **INPUT BAR (Bottom):**

```
┌─────────────────────────────────────┐
│ 📎  📷  🎤  [Type a message...]  ➤  │
└─────────────────────────────────────┘
```

**Icons:**

1. **📎 Attach** - Opens menu:
   - 📷 Take Photo
   - 🖼️ Choose from Gallery
   - 🎥 Record Video

2. **📷 Quick Camera** - Direct camera shortcut

3. **🎤 Voice** - Hold to record voice message (speech-to-text)

4. **➤ Send** - Send text message

---

### **PHOTO FLOW (When camera is tapped):**

**Step 1: Take/Choose Photo**

**Step 2: Popup appears:**
```
┌─────────────────────────────────────┐
│  What is this image?                │
│                                     │
│  ○ Scan for Tips/Income (AI)        │
│    Receipt, BEO, or Paycheck        │
│                                     │
│  ○ Add to Gallery (No AI)           │
│    Event photos, memories           │
│                                     │
│  [Cancel]              [Continue]   │
└─────────────────────────────────────┘
```

---

### **OPTION 1: "Scan for Tips/Income" (AI Analysis)**

**Flow:**
1. Shows loading: "Analyzing image..."
2. AI extracts data (via Supabase Edge Function)
3. Shows **Review Screen:**

```
┌─────────────────────────────────────┐
│  Review & Confirm                   │
├─────────────────────────────────────┤
│  [Image Preview]                    │
├─────────────────────────────────────┤
│  Date:        Dec 24, 2024          │
│  Cash Tips:   $120.00               │
│  Credit Tips: $130.00               │
│  Hours:       8.0                   │
│  Notes:       John's Wedding        │
├─────────────────────────────────────┤
│  ✏️ Looks good?                      │
│  [Edit Details] [Save Shift]        │
└─────────────────────────────────────┘
```

4. User can **edit** if AI made mistakes
5. Tap **Save Shift** → Creates shift entry + attaches image

---

### **OPTION 2: "Add to Gallery" (No AI)**

**Flow:**
1. Prompts: "Which shift should I attach this to?"
2. Shows list of recent shifts OR "Today" option
3. Saves photo to that shift's gallery
4. No AI analysis, just storage

---

### **VIDEO HANDLING:**
- Can record video from chat
- Saved to shift gallery (no AI analysis)
- Auto-generates thumbnail

---

## 📊 SCREEN 4: STATS (ANALYTICS)

### **Purpose:** Charts, trends, comparisons

### **Layout:**
```
┌─────────────────────────────────────┐
│  Analytics                          │
├─────────────────────────────────────┤
│  This Month                         │
│  $6,000                             │
│  ↑ 15% vs last month                │
├─────────────────────────────────────┤
│  [Bar Chart - Income by Week]      │
│  Week 1: $1,200                     │
│  Week 2: $1,500                     │
│  Week 3: $1,800                     │
│  Week 4: $1,500                     │
├─────────────────────────────────────┤
│  [Line Chart - Hours Worked]       │
│  Trending up                        │
├─────────────────────────────────────┤
│  Top Days                           │
│  Friday: $320 avg                   │
│  Saturday: $290 avg                 │
└─────────────────────────────────────┘
```

### **Charts:**
- Bar chart for income by week/month
- Line chart for hours worked over time
- Comparison: This month vs. last month
- Best days/worst days breakdown

---

## 🎯 KEY FEATURES TO BUILD

### **Phase 1: Core Functionality (Complete)**
- ✅ Dashboard with summary
- ✅ Add shift form (basic)
- ✅ Shift list
- ✅ Calendar screen (basic)
- ✅ AI Assistant (basic)
- ✅ Backend deployed

### **Phase 2: Enhanced Calendar (BUILD THIS FIRST)**
- [ ] Month/Week/Year view toggle
- [ ] Badge showing tips + hours on calendar days
- [ ] Tap day → Detail screen with all info
- [ ] Photo gallery per shift
- [ ] Event metadata fields (party name, hostess, guest count)
- [ ] Future schedule integration (placeholder for Hot Schedules/Google)

### **Phase 3: WhatsApp-Style Chat + Smart Photos**
- [ ] Rebuild chat with WhatsApp styling
- [ ] Input bar with camera/attach/voice buttons
- [ ] Photo flow: "Scan for Tips" vs. "Add to Gallery"
- [ ] Review screen for AI-scanned images
- [ ] Save images to shift objects
- [ ] Voice message support (speech-to-text)

### **Phase 4: Cash App Visual Redesign**
- [ ] Dark theme (black/green)
- [ ] Big bold numbers for income
- [ ] Smooth animations
- [ ] Rounded cards with shadows
- [ ] Modern typography

### **Phase 5: Analytics Charts**
- [ ] Bar/line charts for income trends
- [ ] Week-over-week comparisons
- [ ] Best days analysis

### **Phase 6: Missing Core Features**
- [ ] Start/End time (not just date)
- [ ] Upgrade to Isar/Hive database (from SharedPreferences)
- [ ] Multiple shifts per day support
- [ ] Edit/delete shifts

### **Phase 7: Polish & Launch**
- [ ] App icon
- [ ] Onboarding flow
- [ ] Settings screen
- [ ] Dark mode toggle (optional)
- [ ] Paywall/monetization

---

## 📝 NOTES & DECISIONS

1. **Calendar is the centerpiece** - Most used screen
2. **Chat has camera** - No floating button
3. **Two photo types:** Scan (AI) vs. Gallery (no AI)
4. **Cash App aesthetic** - Bold, modern, green/black
5. **WhatsApp-style chat** - Familiar, easy to use
6. **Smart AI flow** - Review before saving

---

## 🚀 BUILD ORDER (Priority)

1. **Calendar Screen** (with Cash App styling) - Sets visual standard
2. **Day Detail Screen** (full shift details)
3. **WhatsApp Chat + Photo Flow** (rebuild assistant)
4. **Dashboard Redesign** (Cash App style)
5. **Stats Charts** (analytics)
6. **Missing Features** (start/end time, better DB, etc.)
7. **Polish** (icon, onboarding, settings)

---

**This document is the single source of truth for the app's design and functionality.**
