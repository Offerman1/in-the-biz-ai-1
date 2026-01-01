# AI Function Calling Implementation Guide
**Project:** In The Biz AI - Tips & Income Tracker  
**Feature:** Full AI Agent with Function Calling (All Actions)  
**Model:** Google Gemini 3 Flash Preview (`gemini-3-flash-preview`)  
**Date Created:** December 29, 2025  
**Status:** ✅ FULLY IMPLEMENTED & DEPLOYED

**📍 Current Progress:** All phases complete! AI agent deployed with 55+ functions and 50+ industry-specific fields.

---

## 📋 Table of Contents
1. [Overview](#overview)
2. [Google Gemini 3 Function Calling Capabilities](#google-gemini-3-function-calling-capabilities)
3. [Architecture](#architecture)
4. [Complete Action List](#complete-action-list)
5. [Implementation Checklist](#implementation-checklist)
6. [Smart Context Detection](#smart-context-detection)
7. [Security & Validation](#security--validation)
8. [Testing Strategy](#testing-strategy)

---

## 📖 Overview

### What We're Building
A fully autonomous AI agent that can perform **EVERY** action a user can do in the app through natural language commands. The AI will:
- Execute database operations (CRUD on shifts, jobs, goals)
- Modify app settings (themes, notifications, preferences)
- Query analytics and provide insights
- Handle multi-step workflows intelligently
- Ask clarifying questions when needed
- Confirm destructive actions before executing

### Why Function Calling?
Instead of the AI just answering questions, it can now **take actions** in the app. When a user says "I made $50 today", the AI doesn't just respond - it actually creates a shift record in the database.

### Technology Stack
- **AI Model:** Gemini 3 Flash Preview (already deployed in the app)
- **Backend:** Supabase Edge Functions (TypeScript/Deno)
- **Frontend:** Flutter (Dart)
- **Database:** PostgreSQL (Supabase)
- **API Endpoint:** `https://bokdjidrybwxbomemmrg.supabase.co/functions/v1/ai-agent`

---

## 🤖 Google Gemini 3 Function Calling Capabilities

### Official Documentation Reference
**Source:** https://ai.google.dev/gemini-api/docs/function-calling

### Key Capabilities We're Using

#### 1. Native Function Calling
Gemini 3 has built-in support for function calling. You define functions using JSON schema, and the AI decides when to call them.

**How It Works:**
1. Define function declarations (name, description, parameters)
2. Send user message + function declarations to Gemini
3. Gemini analyzes the message and decides if it should call a function
4. If yes, Gemini returns a `functionCall` object with the function name and arguments
5. Your code executes the function
6. Send the result back to Gemini
7. Gemini generates a natural language response to the user

#### 2. Parallel Function Calling
Gemini 3 can call **multiple functions at once** when they're independent.

**Example:**
- User: "Add a shift for $400 and set my weekly goal to $1500"
- Gemini calls: `add_shift()` + `set_goal()` simultaneously

#### 3. Compositional (Sequential) Function Calling
Gemini 3 can **chain functions** where one function's output feeds into the next.

**Example:**
- User: "Get my highest-earning job and set it as default"
- Step 1: Gemini calls `get_jobs()` → receives list of jobs with earnings
- Step 2: Gemini calls `set_default_job(jobId)` using the top job's ID from step 1

#### 4. Thought Signatures (Gemini 3 Feature)
Gemini 3 uses internal "thinking" to reason through complex requests. This improves accuracy when deciding which functions to call and what parameters to use. The SDK handles this automatically.

#### 5. Multimodal Function Responses
Gemini 3 can receive **images, PDFs, and documents** as function responses, not just text/JSON.

**Example Use Case:**
- User: "Show me the receipt from December 22nd"
- AI calls: `get_receipt_image(date: "2025-12-22")`
- You return: The actual image file
- AI analyzes the image and responds: "Here's your receipt - you made $320 that day"

#### 6. Function Calling Modes
- **AUTO (Default):** AI decides whether to call a function or just chat
- **ANY:** AI must call a function (guaranteed function execution)
- **NONE:** Disable function calling temporarily
- **VALIDATED:** Ensures function schema compliance

### Supported Models
| Model | Function Calling | Parallel Calls | Sequential Calls | Multimodal Responses |
|-------|-----------------|----------------|------------------|---------------------|
| Gemini 3 Flash Preview | ✅ | ✅ | ✅ | ✅ |
| Gemini 3 Pro | ✅ | ✅ | ✅ | ✅ |
| Gemini 2.5 Flash | ✅ | ✅ | ✅ | ❌ |
| Gemini 2.5 Pro | ✅ | ✅ | ✅ | ❌ |

**We're using Gemini 3 Flash Preview** - it has all the features we need.

---

## 🏗️ Architecture

### File Structure
```
supabase/functions/ai-agent/
  ├── index.ts                    # Main edge function handler
  ├── function-declarations.ts    # All 50+ function definitions
  ├── executors/
  │   ├── shift-executor.ts       # Execute shift-related functions
  │   ├── job-executor.ts         # Execute job-related functions
  │   ├── goal-executor.ts        # Execute goal-related functions
  │   ├── settings-executor.ts    # Execute settings functions
  │   └── analytics-executor.ts   # Execute query functions
  ├── utils/
  │   ├── context-builder.ts      # Build user context for AI
  │   ├── date-parser.ts          # Parse natural language dates
  │   ├── job-detector.ts         # Auto-detect which job to use
  │   └── validators.ts           # Validate inputs before execution

lib/services/
  ├── ai_agent_service.dart       # Flutter service to call AI agent
  └── ai_actions_service.dart     # Enhanced with new capabilities
```

### Request Flow
```
1. User types message in chat
   ↓
2. Flutter sends to Edge Function: /ai-agent
   ↓
3. Edge Function:
   - Loads user context (jobs, shifts, goals, settings)
   - Sends message + context + function declarations to Gemini 3
   ↓
4. Gemini 3 analyzes and decides:
   - Option A: Just chat (no function needed)
   - Option B: Call one function
   - Option C: Call multiple functions (parallel)
   - Option D: Call functions sequentially (compositional)
   ↓
5. Edge Function executes requested functions:
   - Validates inputs
   - Checks permissions (Row Level Security)
   - Executes database operations
   - Handles errors gracefully
   ↓
6. Edge Function sends results back to Gemini 3
   ↓
7. Gemini 3 generates natural language response
   ↓
8. Flutter displays response to user
```

---

## 📝 Complete Action List

### Shift Management (12 Functions)

#### 1. `add_shift`
**Description:** Create a new shift record  
**Parameters:**
- `date` (string, required) - Date in YYYY-MM-DD or natural language ("today", "yesterday", "last Tuesday")
- `cashTips` (number) - Cash tips earned
- `creditTips` (number) - Credit card tips
- `tipOuts` (number) - Amount tipped out to others
- `hourlyRate` (number) - Hourly wage rate
- `hoursWorked` (number) - Hours worked
- `eventName` (string) - Event or party name
- `guestCount` (number) - Number of guests served
- `notes` (string) - Additional notes
- `jobId` (string) - Job UUID (null = auto-detect)

**Smart Behavior:**
- If user has 1 job, auto-apply it
- If user has 2+ jobs, ask which one
- Parse natural dates ("the 22nd" → calculate actual date)
- Follow up: "Want to add event name?" if not provided

#### 2. `edit_shift`
**Description:** Modify an existing shift  
**Parameters:**
- `date` (string, required) - Which shift to edit
- `updates` (object, required) - Fields to update (any combination of add_shift fields)

**Smart Behavior:**
- If multiple shifts on same date, ask which one (morning/evening)
- Show before/after values for confirmation

#### 3. `delete_shift`
**Description:** Remove a single shift  
**Parameters:**
- `date` (string, required) - Which shift to delete
- `confirmationRequired` (boolean) - Default true

**Smart Behavior:**
- Require confirmation by default
- Show shift details before deleting

#### 4. `bulk_edit_shifts`
**Description:** Edit multiple shifts at once  
**Parameters:**
- `query` (object, required):
  - `dateRange` (object) - { start: "2025-01-01", end: "2025-12-31" }
  - `jobId` (string) - Filter by specific job
  - `condition` (string) - "all_past", "all_future", "specific_range"
- `updates` (object, required) - Fields to update
- `confirmationRequired` (boolean) - Default true

**Smart Behavior:**
- Show count of affected shifts
- Require explicit confirmation if > 10 shifts
- Show sample of what will change

#### 5. `bulk_delete_shifts`
**Description:** Delete multiple shifts at once  
**Parameters:**
- `query` (object, required) - Same as bulk_edit_shifts
- `confirmationRequired` (boolean) - Default true, CANNOT be false for bulk deletes

**Smart Behavior:**
- Always require confirmation (safety measure)
- Show total income that will be lost

#### 6. `search_shifts`
**Description:** Find shifts matching criteria  
**Parameters:**
- `query` (object):
  - `dateRange` (object)
  - `jobId` (string)
  - `eventName` (string)
  - `minAmount` (number)
  - `maxAmount` (number)
  - `hasNotes` (boolean)
  - `hasPhotos` (boolean)

**Returns:** List of matching shifts with details

#### 7. `get_shift_details`
**Description:** Get full details of a specific shift  
**Parameters:**
- `date` (string, required)
- `jobId` (string) - If multiple shifts on same date

**Returns:** Complete shift record including photos, notes, calculations

#### 8. `attach_photo_to_shift`
**Description:** Link existing photo to a shift  
**Parameters:**
- `shiftDate` (string, required)
- `photoId` (string, required)

#### 9. `remove_photo_from_shift`
**Description:** Unlink photo from shift (doesn't delete photo)  
**Parameters:**
- `shiftDate` (string, required)
- `photoId` (string, required)

#### 10. `get_shift_photos`
**Description:** Retrieve all photos for a shift  
**Parameters:**
- `shiftDate` (string, required)

**Returns:** Array of photo URLs

#### 11. `calculate_shift_total`
**Description:** Recalculate totals for a shift (useful after edits)  
**Parameters:**
- `shiftDate` (string, required)

**Returns:** Updated totals

#### 12. `duplicate_shift`
**Description:** Copy a shift to another date  
**Parameters:**
- `sourceDate` (string, required)
- `targetDate` (string, required)
- `copyPhotos` (boolean) - Default false

---

### Job Management (10 Functions)

#### 13. `add_job`
**Description:** Create a new job  
**Parameters:**
- `name` (string, required) - Job title
- `industry` (string) - Auto-detected from name, or manual override
- `hourlyRate` (number) - Hourly wage
- `color` (string) - Hex color code (default: theme primary)
- `isDefault` (boolean) - Set as default job
- `template` (string) - "restaurant", "barbershop", "events", "custom"

**Smart Behavior:**
- Infer industry from job title:
  - "bartender", "server", "waiter" → "Food Service"
  - "barber", "hairstylist" → "Beauty & Personal Care"
  - "wedding planner", "caterer" → "Events"
- If isDefault=true, unset other defaults

#### 14. `edit_job`
**Description:** Modify job details  
**Parameters:**
- `jobId` (string, required)
- `updates` (object, required) - Fields to update

#### 15. `delete_job`
**Description:** Remove a job  
**Parameters:**
- `jobId` (string, required)
- `deleteShifts` (boolean) - Default false (soft delete shifts instead)
- `confirmationRequired` (boolean) - Default true

**Smart Behavior:**
- Show shift count and total income from this job
- Offer to keep shifts or delete them

#### 16. `set_default_job`
**Description:** Mark a job as the default  
**Parameters:**
- `jobId` (string, required)

**Smart Behavior:**
- Unset previous default automatically

#### 17. `end_job`
**Description:** Mark job as inactive (ended) but keep data  
**Parameters:**
- `jobId` (string, required)
- `endDate` (string) - When job ended (default: today)

**Smart Behavior:**
- Job becomes hidden from selectors
- Historical data and stats remain intact

#### 18. `restore_job`
**Description:** Reactivate an ended job  
**Parameters:**
- `jobId` (string, required)

#### 19. `get_jobs`
**Description:** List all jobs  
**Parameters:**
- `includeEnded` (boolean) - Default false
- `includeDeleted` (boolean) - Default false

**Returns:** Array of jobs with stats

#### 20. `get_job_stats`
**Description:** Get detailed stats for a job  
**Parameters:**
- `jobId` (string, required)
- `period` (string) - "week", "month", "year", "all_time"

**Returns:** Total income, hours, avg/hour, shift count, best days

#### 21. `compare_jobs`
**Description:** Compare earnings between jobs  
**Parameters:**
- `jobIds` (array of strings) - Jobs to compare
- `period` (string) - Time period

**Returns:** Comparison table with totals and averages

#### 22. `set_job_hourly_rate`
**Description:** Update hourly rate for a job  
**Parameters:**
- `jobId` (string, required)
- `newRate` (number, required)
- `effectiveDate` (string) - When rate takes effect (default: today)
- `updatePastShifts` (boolean) - Default false

**Smart Behavior:**
- Ask if user wants to update past shifts with new rate

---

### Goal Management (8 Functions)

#### 23. `set_daily_goal`
**Description:** Create or update daily income goal  
**Parameters:**
- `amount` (number, required)
- `jobId` (string) - Null = overall daily goal
- `targetHours` (number) - Optional hours target

#### 24. `set_weekly_goal`
**Description:** Create or update weekly income goal  
**Parameters:**
- `amount` (number, required)
- `jobId` (string)
- `targetHours` (number)

#### 25. `set_monthly_goal`
**Description:** Create or update monthly income goal  
**Parameters:**
- `amount` (number, required)
- `jobId` (string)
- `targetHours` (number)

#### 26. `set_yearly_goal`
**Description:** Create or update yearly income goal  
**Parameters:**
- `amount` (number, required)
- `jobId` (string)
- `targetHours` (number)

#### 27. `edit_goal`
**Description:** Modify existing goal  
**Parameters:**
- `goalId` (string, required)
- `updates` (object, required) - Amount, targetHours, jobId

#### 28. `delete_goal`
**Description:** Remove a goal  
**Parameters:**
- `goalId` (string, required)

#### 29. `get_goals`
**Description:** List all goals with progress  
**Parameters:**
- `includeCompleted` (boolean) - Default true

**Returns:** Goals with current progress, percentage complete, remaining amount

#### 30. `get_goal_progress`
**Description:** Check progress on a specific goal  
**Parameters:**
- `goalId` (string, required)

**Returns:** Detailed progress including daily pace needed

---

### Theme & Appearance (4 Functions)

#### 31. `change_theme`
**Description:** Switch app theme/color scheme  
**Parameters:**
- `theme` (string, required) - Theme name or mode
  - Valid values: "light_mode", "finance_green", "midnight_blue", "purple_reign", "ocean_breeze", "sunset_glow", "forest_night", "paypal_blue", "finance_pro", "light_blue", "soft_purple"

**Smart Behavior:**
- Parse natural language: "light mode" → "light_mode"
- "dark mode" → "finance_green" (default dark theme)
- Show before/after preview

#### 32. `get_available_themes`
**Description:** List all theme options  
**Returns:** Array of theme names with descriptions

#### 33. `preview_theme`
**Description:** Show theme colors without applying  
**Parameters:**
- `theme` (string, required)

**Returns:** Color palette preview

#### 34. `revert_theme`
**Description:** Undo last theme change  
**Uses:** `previous_theme_id` from user_preferences table

---

### Notifications (5 Functions)

#### 35. `toggle_notifications`
**Description:** Turn notifications on/off globally  
**Parameters:**
- `enabled` (boolean, required)

#### 36. `set_shift_reminders`
**Description:** Configure shift reminder notifications  
**Parameters:**
- `enabled` (boolean, required)
- `reminderTime` (string) - "morning", "evening", "both"
- `daysBeforeShift` (number) - How many days in advance

#### 37. `set_goal_reminders`
**Description:** Configure goal progress notifications  
**Parameters:**
- `enabled` (boolean, required)
- `frequency` (string) - "daily", "weekly", "monthly"

#### 38. `set_quiet_hours`
**Description:** Set times when notifications are silenced  
**Parameters:**
- `enabled` (boolean, required)
- `startTime` (string) - "HH:MM" format
- `endTime` (string) - "HH:MM" format

#### 39. `get_notification_settings`
**Description:** Retrieve current notification preferences  
**Returns:** All notification settings

---

### Settings & Preferences (8 Functions)

#### 40. `update_tax_settings`
**Description:** Modify tax estimation settings  
**Parameters:**
- `filingStatus` (string) - "single", "married_joint", "married_separate", "head_of_household"
- `dependents` (number)
- `additionalIncome` (number) - Income from other sources
- `deductions` (number) - Standard or itemized
- `isSelfEmployed` (boolean)

#### 41. `set_currency_format`
**Description:** Change currency display  
**Parameters:**
- `currencyCode` (string) - "USD", "EUR", "GBP", etc.
- `showCents` (boolean) - Default true

#### 42. `set_date_format`
**Description:** Change date display format  
**Parameters:**
- `format` (string) - "MM/DD/YYYY", "DD/MM/YYYY", "YYYY-MM-DD"

#### 43. `set_week_start_day`
**Description:** Set which day starts the week  
**Parameters:**
- `day` (string) - "sunday", "monday"

#### 44. `export_data_csv`
**Description:** Generate CSV export of all data  
**Parameters:**
- `dateRange` (object) - Optional filter
- `includePhotos` (boolean) - Default false

**Returns:** Download link

#### 45. `export_data_pdf`
**Description:** Generate PDF report  
**Parameters:**
- `dateRange` (object) - Optional filter
- `reportType` (string) - "summary", "detailed", "tax_ready"

**Returns:** Download link

#### 46. `clear_chat_history`
**Description:** Delete all chat messages  
**Parameters:**
- `confirmationRequired` (boolean) - Default true

#### 47. `get_user_settings`
**Description:** Retrieve all current settings  
**Returns:** Complete settings object

---

### Analytics & Queries (8 Functions)

#### 48. `get_income_summary`
**Description:** Get income for a time period  
**Parameters:**
- `period` (string, required) - "today", "week", "month", "year", "custom"
- `dateRange` (object) - Required if period="custom"
- `jobId` (string) - Optional filter by job

**Returns:** Total income, tips, hours, avg/hour, shift count

#### 49. `compare_periods`
**Description:** Compare income across time periods  
**Parameters:**
- `period1` (object) - { period: "month", year: 2025, month: 11 }
- `period2` (object) - { period: "month", year: 2025, month: 12 }

**Returns:** Comparison with difference and percentage change

#### 50. `get_best_days`
**Description:** Find highest-earning days of the week  
**Parameters:**
- `limit` (number) - Default 5
- `jobId` (string) - Optional filter

**Returns:** Days ranked by average earnings

#### 51. `get_worst_days`
**Description:** Find lowest-earning days  
**Parameters:**
- `limit` (number) - Default 5
- `jobId` (string)

**Returns:** Days ranked by average earnings (ascending)

#### 52. `get_tax_estimate`
**Description:** Calculate federal tax estimate  
**Parameters:**
- `year` (number) - Default current year

**Returns:** Federal tax, self-employment tax, total tax owed, effective rate

#### 53. `get_projected_year_end`
**Description:** Project year-end income based on current pace  
**Parameters:**
- `year` (number) - Default current year

**Returns:** Projected total, projected tax, pace analysis

#### 54. `get_year_over_year`
**Description:** Compare this year to last year  
**Returns:** Growth/decline percentage, difference in dollars

#### 55. `get_event_earnings`
**Description:** Total earnings from a specific event/party name  
**Parameters:**
- `eventName` (string, required)

**Returns:** Total income, shift count, date range

---

## ✅ Implementation Checklist

### Phase 1: Foundation (Edge Function Setup)
- [ ] Create `supabase/functions/ai-agent/index.ts` base file
- [ ] Set up Gemini 3 Flash Preview model initialization
- [ ] Implement conversation history management
- [ ] Add CORS headers and authentication
- [ ] Test basic chat without functions (sanity check)

### Phase 2: Function Declarations (Define All 55 Functions)
- [ ] Create `function-declarations.ts` file
- [ ] Define Shift Management functions (1-12)
- [ ] Define Job Management functions (13-22)
- [ ] Define Goal Management functions (23-30)
- [ ] Define Theme & Appearance functions (31-34)
- [ ] Define Notifications functions (35-39)
- [ ] Define Settings functions (40-47)
- [ ] Define Analytics functions (48-55)
- [ ] Validate all function schemas (required fields, types, enums)

### Phase 3: Executors (Implement Function Logic)
- [ ] Create `executors/shift-executor.ts`
  - [ ] Implement add_shift
  - [ ] Implement edit_shift
  - [ ] Implement delete_shift
  - [ ] Implement bulk_edit_shifts
  - [ ] Implement bulk_delete_shifts
  - [ ] Implement search_shifts
  - [ ] Implement get_shift_details
  - [ ] Implement attach_photo_to_shift
  - [ ] Implement remove_photo_from_shift
  - [ ] Implement get_shift_photos
  - [ ] Implement calculate_shift_total
  - [ ] Implement duplicate_shift

- [ ] Create `executors/job-executor.ts`
  - [ ] Implement add_job (with industry inference)
  - [ ] Implement edit_job
  - [ ] Implement delete_job
  - [ ] Implement set_default_job
  - [ ] Implement end_job
  - [ ] Implement restore_job
  - [ ] Implement get_jobs
  - [ ] Implement get_job_stats
  - [ ] Implement compare_jobs
  - [ ] Implement set_job_hourly_rate

- [ ] Create `executors/goal-executor.ts`
  - [ ] Implement set_daily_goal
  - [ ] Implement set_weekly_goal
  - [ ] Implement set_monthly_goal
  - [ ] Implement set_yearly_goal
  - [ ] Implement edit_goal
  - [ ] Implement delete_goal
  - [ ] Implement get_goals
  - [ ] Implement get_goal_progress

- [ ] Create `executors/settings-executor.ts`
  - [ ] Implement change_theme
  - [ ] Implement get_available_themes
  - [ ] Implement preview_theme
  - [ ] Implement revert_theme
  - [ ] Implement toggle_notifications
  - [ ] Implement set_shift_reminders
  - [ ] Implement set_goal_reminders
  - [ ] Implement set_quiet_hours
  - [ ] Implement get_notification_settings
  - [ ] Implement update_tax_settings
  - [ ] Implement set_currency_format
  - [ ] Implement set_date_format
  - [ ] Implement set_week_start_day
  - [ ] Implement export_data_csv
  - [ ] Implement export_data_pdf
  - [ ] Implement clear_chat_history
  - [ ] Implement get_user_settings

- [ ] Create `executors/analytics-executor.ts`
  - [ ] Implement get_income_summary
  - [ ] Implement compare_periods
  - [ ] Implement get_best_days
  - [ ] Implement get_worst_days
  - [ ] Implement get_tax_estimate
  - [ ] Implement get_projected_year_end
  - [ ] Implement get_year_over_year
  - [ ] Implement get_event_earnings

### Phase 4: Utilities (Smart Features)
- [ ] Create `utils/context-builder.ts`
  - [ ] Build user context (jobs, recent shifts, goals, settings)
  - [ ] Optimize context size (keep under 100K tokens)

- [ ] Create `utils/date-parser.ts`
  - [ ] Parse "today", "yesterday", "tomorrow"
  - [ ] Parse "last Tuesday", "next Friday"
  - [ ] Parse "the 22nd" (infer month/year)
  - [ ] Parse relative dates ("3 days ago", "2 weeks from now")

- [ ] Create `utils/job-detector.ts`
  - [ ] Auto-detect single job scenarios
  - [ ] Generate clarifying questions for multiple jobs
  - [ ] Match job mentions in messages

- [ ] Create `utils/validators.ts`
  - [ ] Validate date formats
  - [ ] Validate numeric ranges
  - [ ] Validate enum values
  - [ ] Sanitize inputs (prevent injection)

- [ ] Create `utils/industry-inference.ts`
  - [ ] Map job titles to industries
  - [ ] Keywords database (bartender → Food Service, etc.)

### Phase 5: Main Handler (Orchestration)
- [ ] Implement function call detection
- [ ] Implement function execution routing
- [ ] Implement parallel function calling support
- [ ] Implement sequential function calling support
- [ ] Implement error handling for each function
- [ ] Implement confirmation flow for destructive actions
- [ ] Implement multi-turn conversation state management
- [ ] Add logging for debugging

### Phase 6: Flutter Integration
- [ ] Create `lib/services/ai_agent_service.dart`
  - [ ] Method: `sendMessage(String message, List<ChatMessage> history)`
  - [ ] Method: `clearHistory()`
  - [ ] Handle API errors gracefully

- [ ] Update `lib/screens/assistant_screen.dart`
  - [ ] Switch from `chat` endpoint to `ai-agent` endpoint
  - [ ] Add loading states for function executions
  - [ ] Add confirmation dialogs for destructive actions
  - [ ] Add success/error feedback for actions
  - [ ] Update UI to show "AI is adding shift..." messages

- [ ] Update `lib/providers/shift_provider.dart`
  - [ ] Add listener for AI-created shifts (refresh list)

- [ ] Update `lib/providers/theme_provider.dart`
  - [ ] Add listener for AI theme changes

### Phase 7: Database Optimizations
- [ ] Create database indexes for common queries
  - [ ] Index on shifts.date
  - [ ] Index on shifts.job_id
  - [ ] Index on shifts.event_name
  - [ ] Index on goals.type and goals.job_id

- [ ] Add database functions for bulk operations
  - [ ] `bulk_update_shifts(ids[], updates)`
  - [ ] `bulk_delete_shifts(ids[])`

- [ ] Verify Row Level Security policies
  - [ ] Ensure all functions respect user_id filtering
  - [ ] Test with multiple users

### Phase 8: Testing
- [ ] Test each function individually
  - [ ] Test with valid inputs
  - [ ] Test with invalid inputs (expect graceful errors)
  - [ ] Test with edge cases (empty strings, null values)

- [ ] Test multi-turn conversations
  - [ ] Test follow-up questions
  - [ ] Test context retention

- [ ] Test parallel function calling
  - [ ] "Add shift and set goal" (2 functions)
  - [ ] "Add 3 shifts" (should batch)

- [ ] Test sequential function calling
  - [ ] "Get my best job and make it default"
  - [ ] "Compare my jobs and delete the worst one"

- [ ] Test smart features
  - [ ] Job auto-detection (1 job vs. 2+ jobs)
  - [ ] Natural date parsing
  - [ ] Industry inference
  - [ ] Confirmation prompts

- [ ] Test error scenarios
  - [ ] Invalid date
  - [ ] Non-existent job ID
  - [ ] Duplicate goal creation
  - [ ] Database connection failures

- [ ] Test security
  - [ ] User A cannot access User B's data
  - [ ] SQL injection attempts fail
  - [ ] Destructive actions require confirmation

### Phase 9: Deployment
- [ ] Deploy edge function to production
  ```bash
  npx supabase functions deploy ai-agent --project-ref bokdjidrybwxbomemmrg
  ```

- [ ] Test in production environment
  - [ ] Test on Android phone (Seeker)
  - [ ] Test on Android tablet
  - [ ] Test with real user data

- [ ] Monitor performance
  - [ ] Check function execution times
  - [ ] Monitor API costs (Gemini token usage)
  - [ ] Check error rates

### Phase 10: Documentation & Polish
- [ ] Update user-facing documentation
  - [ ] Add examples of AI commands to help screen
  - [ ] Create tutorial for first-time users

- [ ] Add analytics tracking
  - [ ] Track which functions are used most
  - [ ] Track success/error rates per function

- [ ] Optimize prompts
  - [ ] Refine system instructions for better accuracy
  - [ ] Add examples of common user queries

- [ ] Add rate limiting (if needed)
  - [ ] Prevent abuse (e.g., 100 requests/minute)

---

## 🧠 Smart Context Detection

### Job Auto-Detection Logic
```
IF user has 0 jobs:
  → AI suggests creating a job first
  
IF user has 1 job:
  → Automatically apply it to new shifts (no need to ask)
  
IF user has 2+ jobs:
  → Check if job mentioned in message ("my server job", "bartending")
  → If mentioned: Use that job
  → If not mentioned: Ask user "Which job was this for - Server or Bartender?"
```

### Natural Date Parsing Logic
```
"today" → Current date
"yesterday" → Current date - 1 day
"tomorrow" → Current date + 1 day
"last Tuesday" → Calculate previous Tuesday
"next Friday" → Calculate upcoming Friday
"the 22nd" → Current month, day 22 (or previous month if 22nd has passed)
"December 22nd" → 2025-12-22 (or 2024-12-22 if we're in 2026+)
"3 days ago" → Current date - 3 days
"2 weeks from now" → Current date + 14 days
```

### Industry Inference Keywords
```
Food Service: bartender, server, waiter, waitress, barista, chef, cook, host, hostess
Beauty: barber, hairstylist, cosmetologist, nail tech, makeup artist, esthetician
Events: wedding planner, event coordinator, caterer, DJ, photographer
Hospitality: hotel, valet, concierge, bellhop, housekeeper
Rideshare: uber, lyft, driver
Delivery: doordash, uber eats, grubhub, postmates, delivery driver
Other: freelancer, contractor, consultant (default to "Other Services")
```

### Follow-Up Question Logic
```
After adding a shift with minimal info:
- If no event name: "Would you like to add the event name?"
- If no guest count: "How many guests did you serve?"
- If no notes: "Any notes about this shift?"

After setting a goal:
- If only amount provided: "Want to set an hours target too?"

After adding a job:
- If no hourly rate: "What's your hourly rate for this job?"
```

### Confirmation Prompt Logic
```
Destructive actions that REQUIRE confirmation:
- Delete shift (single)
- Delete job
- Bulk delete shifts (ALWAYS, cannot be bypassed)
- Bulk edit > 10 shifts
- Clear chat history

Actions that DON'T need confirmation:
- Add shift
- Edit shift
- Set/edit goals
- Change theme
- Toggle notifications
```

---

## 🔒 Security & Validation

### Row Level Security (RLS)
All database functions must respect RLS policies:
- Every query includes `WHERE user_id = auth.uid()`
- Edge function extracts user ID from JWT token
- Supabase enforces RLS at database level (double protection)

### Input Validation
Before executing any function:
1. **Type check:** Ensure parameters match expected types
2. **Range check:** Numbers within acceptable ranges (e.g., hourly rate 0-500)
3. **Format check:** Dates in valid format, UUIDs are valid UUIDs
4. **Sanitization:** Strip HTML, prevent SQL injection
5. **Business logic:** Can't delete a job that doesn't exist

### Error Handling
Every function executor should:
1. **Try-catch** all database operations
2. **Return structured errors** (not raw SQL errors)
3. **Provide actionable messages** ("Shift not found on that date" instead of "No rows returned")
4. **Log errors** for debugging (but don't expose to user)

### Rate Limiting
Implement in edge function:
- Max 60 requests per minute per user
- If exceeded: Return 429 error with retry-after header

---

## 🧪 Testing Strategy

### Unit Tests (Each Function)
Test each of the 55 functions individually with:
- Valid inputs → Expect success
- Invalid inputs → Expect error with helpful message
- Edge cases → Expect graceful handling

### Integration Tests (Multi-Function)
Test workflows that use multiple functions:
- "Add shift and set goal" → Both execute successfully
- "Get jobs, compare them, delete worst" → Sequential execution works

### End-to-End Tests (Full User Flow)
Test real user conversations:
1. User: "I made $50 today"
   - AI calls: add_shift(date="2025-12-29", total=50)
   - Expected: Shift created, confirmation shown

2. User: "Set a weekly goal of $1000"
   - AI calls: set_weekly_goal(amount=1000)
   - Expected: Goal created, progress shown

3. User: "Switch to light mode"
   - AI calls: change_theme(theme="light_mode")
   - Expected: Theme changes, app restarts

4. User: "Delete all my shifts from 2024"
   - AI calls: bulk_delete_shifts(query={year:2024})
   - Expected: Confirmation prompt, then deletion

### Conversation Context Tests
Test that AI maintains context across turns:
1. User: "I made $50 today"
   - AI: "Got it! Which job?"
2. User: "Server"
   - AI creates shift for server job (remembered the $50)

### Error Recovery Tests
Test that AI handles errors gracefully:
1. User: "Delete my shift from December 50th"
   - Function returns: "Invalid date"
   - AI responds: "December 50th isn't a valid date. Did you mean December 5th?"

---

## 📊 Success Metrics

### Accuracy Metrics
- **Function call accuracy:** AI chooses correct function ≥ 95% of time
- **Parameter accuracy:** AI provides correct parameters ≥ 90% of time
- **Context retention:** AI remembers previous messages ≥ 90% of time

### User Experience Metrics
- **Confirmation rate:** Users confirm AI actions ≥ 80% of time (means AI understood correctly)
- **Retry rate:** Users need to rephrase < 20% of time
- **Error rate:** Functions fail < 5% of time

### Performance Metrics
- **Response time:** AI responds within 3 seconds for simple queries
- **Function execution time:** Database operations complete within 2 seconds
- **Token usage:** Average conversation uses < 5,000 tokens (cost: ~$0.0025)

---

## 📚 Reference Documentation

### Google Gemini 3 Function Calling
- Official Docs: https://ai.google.dev/gemini-api/docs/function-calling
- Supported Models: https://ai.google.dev/gemini-api/docs/models
- Thinking Models: https://ai.google.dev/gemini-api/docs/thinking
- Thought Signatures: https://ai.google.dev/gemini-api/docs/thought-signatures
- Best Practices: See "Best practices" section in function calling docs

### Supabase Edge Functions
- Docs: https://supabase.com/docs/guides/functions
- Deploy: `npx supabase functions deploy <function-name>`
- Logs: `npx supabase functions logs <function-name>`

### Flutter Integration
- HTTP Requests: Use `http` package
- State Management: Provider pattern (already implemented)
- Error Handling: Try-catch with user-friendly messages

---

## 🎯 Next Steps

After reviewing this document:
1. Review the complete action list - confirm nothing is missing
2. Review the checklist - confirm all tasks are included
3. Begin Phase 1: Foundation (create base edge function)
4. Work through checklist systematically
5. Test each phase before moving to next

**This document is the single source of truth for this implementation.**

---

**Status Legend:**
- [ ] Not Started
- [🟡] In Progress
- [✅] Completed
- [❌] Blocked/Issue

**Last Updated:** December 29, 2025
