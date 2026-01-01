// Function Declarations for AI Agent
// All 55 functions the AI can call to perform actions

export const functionDeclarations = [
  // ============================================
  // SHIFT MANAGEMENT (12 functions)
  // ============================================
  {
    name: "add_shift",
    description: "Create a new shift record with earnings, tips, hours, and event details. If user mentions specific amounts, use those. If user has only one job, auto-apply it. IMPORTANT: Extract ALL information from the user's message including start/end times.",
    parameters: {
      type: "object",
      properties: {
        date: {
          type: "string",
          description: "Date in YYYY-MM-DD format or natural language like 'today', 'yesterday', 'last Tuesday', 'the 22nd'",
        },
        cashTips: {
          type: "number",
          description: "Cash tips earned in dollars",
        },
        creditTips: {
          type: "number",
          description: "Credit card tips earned in dollars",
        },
        hourlyRate: {
          type: "number",
          description: "Hourly wage rate in dollars (override)",
        },
        hoursWorked: {
          type: "number",
          description: "Number of hours worked (can be decimal like 8.5). Calculate from start/end times if provided.",
        },
        overtimeHours: {
          type: "number",
          description: "Overtime hours worked",
        },
        startTime: {
          type: "string",
          description: "Start time of shift (e.g., '2:00 PM', '14:00', '2pm'). ALWAYS extract this if user mentions it.",
        },
        endTime: {
          type: "string",
          description: "End time of shift (e.g., '11:00 PM', '23:00', '11pm'). ALWAYS extract this if user mentions it.",
        },
        eventName: {
          type: "string",
          description: "Name of event or party (e.g., 'Smith Wedding', 'Corporate Holiday Party')",
        },
        guestCount: {
          type: "number",
          description: "Number of guests served",
        },
        notes: {
          type: "string",
          description: "Additional notes about the shift",
        },
        jobId: {
          type: "string",
          description: "Job UUID. Set to null to auto-detect from user's jobs. If user has multiple jobs, ask which one.",
        },
        location: {
          type: "string",
          description: "Work location or venue name",
        },
        clientName: {
          type: "string",
          description: "Client name (for freelance/contract work)",
        },
        projectName: {
          type: "string",
          description: "Project name",
        },
        hostess: {
          type: "string",
          description: "Hostess name",
        },
        salesAmount: {
          type: "number",
          description: "Total sales amount in dollars",
        },
        tipoutPercent: {
          type: "number",
          description: "Tip out percentage",
        },
        additionalTipout: {
          type: "number",
          description: "Additional tip out amount in dollars",
        },
        additionalTipoutNote: {
          type: "string",
          description: "Note explaining additional tip out",
        },
        commission: {
          type: "number",
          description: "Commission earned in dollars",
        },
        mileage: {
          type: "number",
          description: "Miles driven for work",
        },
        flatRate: {
          type: "number",
          description: "Flat rate pay in dollars",
        },
        eventCost: {
          type: "number",
          description: "Event cost in dollars",
        },
      },
      required: ["date"],
    },
  },

  {
    name: "edit_shift",
    description: "Modify an existing shift by date. Can update any field.",
    parameters: {
      type: "object",
      properties: {
        date: {
          type: "string",
          description: "Date of the shift to edit (YYYY-MM-DD or natural language)",
        },
        updates: {
          type: "object",
          description: "Object containing fields to update (e.g., {cashTips: 60, notes: 'Busy night'})",
        },
      },
      required: ["date", "updates"],
    },
  },

  {
    name: "delete_shift",
    description: "Remove a single shift. Always confirm before deleting.",
    parameters: {
      type: "object",
      properties: {
        date: {
          type: "string",
          description: "Date of shift to delete",
        },
        confirmed: {
          type: "boolean",
          description: "Set to true only after user confirms deletion",
        },
      },
      required: ["date"],
    },
  },

  {
    name: "bulk_edit_shifts",
    description: `Edit multiple shifts at once based on a date range or other criteria. 
    
IMPORTANT WORKFLOW:
1. First call this with confirmed=false to get a PREVIEW of how many shifts will be affected
2. Tell the user: "I found X shifts that match. Here's what I'll change: [details]. Should I proceed?"
3. Only call again with confirmed=true AFTER user says yes/confirms

NEVER execute bulk edits without user confirmation first.`,
    parameters: {
      type: "object",
      properties: {
        startDate: {
          type: "string",
          description: "Start date for range (YYYY-MM-DD). Use for 'before X date' = beginning of time to X",
        },
        endDate: {
          type: "string",
          description: "End date for range (YYYY-MM-DD). Use for 'after X date' = X to today",
        },
        jobId: {
          type: "string",
          description: "Optional: only affect shifts for this job",
        },
        jobName: {
          type: "string",
          description: "Optional: job name to filter by (will be matched against user's jobs)",
        },
        updates: {
          type: "object",
          description: "Fields to update on all matching shifts",
          properties: {
            cashTips: { type: "number", description: "Cash tips amount" },
            creditTips: { type: "number", description: "Credit tips amount" },
            hourlyRate: { type: "number", description: "Hourly rate override" },
            hoursWorked: { type: "number", description: "Hours worked" },
            overtimeHours: { type: "number", description: "Overtime hours" },
            startTime: { type: "string", description: "Start time (HH:MM format)" },
            endTime: { type: "string", description: "End time (HH:MM format)" },
            notes: { type: "string", description: "Notes/comments" },
            eventName: { type: "string", description: "Event or party name" },
            guestCount: { type: "number", description: "Number of guests" },
            location: { type: "string", description: "Work location" },
            clientName: { type: "string", description: "Client name" },
            projectName: { type: "string", description: "Project name" },
            hostess: { type: "string", description: "Hostess name" },
            salesAmount: { type: "number", description: "Total sales amount" },
            tipoutPercent: { type: "number", description: "Tip out percentage" },
            additionalTipout: { type: "number", description: "Additional tip out amount" },
            additionalTipoutNote: { type: "string", description: "Note for additional tip out" },
            commission: { type: "number", description: "Commission earned" },
            mileage: { type: "number", description: "Miles driven" },
            flatRate: { type: "number", description: "Flat rate pay" },
            eventCost: { type: "number", description: "Event cost" },
          },
        },
        confirmed: {
          type: "boolean",
          description: "Set to false for preview, true only after user confirms",
        },
      },
      required: ["updates"],
    },
  },

  {
    name: "bulk_delete_shifts",
    description: "Delete multiple shifts. ALWAYS requires explicit confirmation.",
    parameters: {
      type: "object",
      properties: {
        query: {
          type: "object",
          description: "Query to select shifts to delete",
        },
        confirmed: {
          type: "boolean",
          description: "MUST be true - always confirm bulk deletes",
        },
      },
      required: ["query", "confirmed"],
    },
  },

  {
    name: "search_shifts",
    description: "Find shifts matching specific criteria",
    parameters: {
      type: "object",
      properties: {
        query: {
          type: "object",
          description: "Search criteria: dateRange, jobId, eventName, minAmount, maxAmount, hasNotes, hasPhotos",
        },
      },
      required: ["query"],
    },
  },

  {
    name: "get_shift_details",
    description: "Get complete details of a specific shift",
    parameters: {
      type: "object",
      properties: {
        date: {
          type: "string",
          description: "Date of shift",
        },
        jobId: {
          type: "string",
          description: "Optional: specify job if multiple shifts on same date",
        },
      },
      required: ["date"],
    },
  },

  {
    name: "attach_photo_to_shift",
    description: "Link an existing photo to a shift",
    parameters: {
      type: "object",
      properties: {
        shiftDate: { type: "string" },
        photoId: { type: "string" },
      },
      required: ["shiftDate", "photoId"],
    },
  },

  {
    name: "remove_photo_from_shift",
    description: "Unlink photo from shift (doesn't delete the photo)",
    parameters: {
      type: "object",
      properties: {
        shiftDate: { type: "string" },
        photoId: { type: "string" },
      },
      required: ["shiftDate", "photoId"],
    },
  },

  {
    name: "get_shift_photos",
    description: "Retrieve all photos attached to a shift",
    parameters: {
      type: "object",
      properties: {
        shiftDate: { type: "string" },
      },
      required: ["shiftDate"],
    },
  },

  {
    name: "calculate_shift_total",
    description: "Recalculate totals for a shift after edits",
    parameters: {
      type: "object",
      properties: {
        shiftDate: { type: "string" },
      },
      required: ["shiftDate"],
    },
  },

  {
    name: "duplicate_shift",
    description: "Copy a shift to another date",
    parameters: {
      type: "object",
      properties: {
        sourceDate: { type: "string" },
        targetDate: { type: "string" },
        copyPhotos: { type: "boolean", description: "Default false" },
      },
      required: ["sourceDate", "targetDate"],
    },
  },

  // ============================================
  // EVENT CONTACTS / VENDOR DIRECTORY (6 functions)
  // ============================================
  {
    name: "add_event_contact",
    description: "Add a contact for an event vendor, staff member, or professional you worked with. Use when user mentions names/roles like 'The DJ was Billy', 'wedding planner Sarah', 'photographer's email was...', 'valet guys Jim and Bob', etc.",
    parameters: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "Contact's full name (e.g., 'Billy', 'Sarah Johnson', 'Jim and Bob')",
        },
        role: {
          type: "string",
          description: "Role/profession from the predefined list. Use 'custom' if not in list.",
          enum: [
            "dj",
            "band_musician",
            "photo_booth",
            "photographer",
            "videographer",
            "wedding_planner",
            "event_coordinator",
            "hostess",
            "support_staff",
            "security",
            "valet",
            "florist",
            "linen_rental",
            "cake_bakery",
            "catering",
            "rentals",
            "lighting_av",
            "rabbi",
            "priest",
            "pastor",
            "officiant",
            "venue_manager",
            "venue_coordinator",
            "custom",
          ],
        },
        customRole: {
          type: "string",
          description: "Custom role description when role='custom' (e.g., 'Ice Sculpture Artist')",
        },
        company: {
          type: "string",
          description: "Company/business name (e.g., 'Elite Valet Services', 'Bloom Florists')",
        },
        phone: {
          type: "string",
          description: "Phone number",
        },
        email: {
          type: "string",
          description: "Email address",
        },
        website: {
          type: "string",
          description: "Website URL",
        },
        notes: {
          type: "string",
          description: "Additional notes or details",
        },
        shiftId: {
          type: "string",
          description: "Optional: Link to a specific shift/event UUID",
        },
        instagram: { type: "string", description: "Instagram handle (without @)" },
        tiktok: { type: "string", description: "TikTok handle (without @)" },
        facebook: { type: "string", description: "Facebook profile URL or username" },
        twitter: { type: "string", description: "Twitter/X handle (without @)" },
        linkedin: { type: "string", description: "LinkedIn profile URL" },
        youtube: { type: "string", description: "YouTube channel URL" },
        snapchat: { type: "string", description: "Snapchat username" },
        pinterest: { type: "string", description: "Pinterest username" },
      },
      required: ["name"],
    },
  },

  {
    name: "edit_event_contact",
    description: "Update an existing event contact's information",
    parameters: {
      type: "object",
      properties: {
        contactId: {
          type: "string",
          description: "Contact UUID (if known)",
        },
        name: {
          type: "string",
          description: "Contact name to search for (if contactId not known)",
        },
        updates: {
          type: "object",
          description: "Fields to update (same as add_event_contact properties)",
        },
      },
      required: ["updates"],
    },
  },

  {
    name: "delete_event_contact",
    description: "Delete an event contact",
    parameters: {
      type: "object",
      properties: {
        contactId: { type: "string" },
        name: { type: "string" },
        confirmed: {
          type: "boolean",
          description: "Must be true after user confirms deletion",
        },
      },
      required: ["confirmed"],
    },
  },

  {
    name: "search_contacts",
    description: "Search for event contacts by name, role, or company",
    parameters: {
      type: "object",
      properties: {
        query: { type: "string", description: "Search term (name, company, notes)" },
        role: { type: "string", description: "Filter by role" },
        company: { type: "string", description: "Filter by company name" },
      },
      required: [],
    },
  },

  {
    name: "get_contacts_for_shift",
    description: "Get all contacts associated with a specific shift/event",
    parameters: {
      type: "object",
      properties: {
        shiftId: { type: "string", description: "Shift UUID" },
        date: { type: "string", description: "Or shift date (YYYY-MM-DD)" },
      },
      required: [],
    },
  },

  {
    name: "set_contact_favorite",
    description: "Mark a contact as favorite or remove from favorites",
    parameters: {
      type: "object",
      properties: {
        contactId: { type: "string" },
        name: { type: "string" },
        isFavorite: { type: "boolean" },
      },
      required: ["isFavorite"],
    },
  },

  // ============================================
  // JOB MANAGEMENT (10 functions)
  // ============================================
  {
    name: "add_job",
    description: "Create a new job. Automatically infer industry from job title (bartender→Food Service, barber→Beauty, etc.)",
    parameters: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "Job title (e.g., 'Bartender', 'Server', 'Barber')",
        },
        industry: {
          type: "string",
          description: "Industry category - will be auto-detected from name if not provided",
          enum: [
            "Food Service",
            "Beauty & Personal Care",
            "Events",
            "Hospitality",
            "Rideshare",
            "Delivery",
            "Other Services",
          ],
        },
        hourlyRate: {
          type: "number",
          description: "Hourly wage in dollars",
        },
        color: {
          type: "string",
          description: "Hex color code (default: theme primary green)",
        },
        isDefault: {
          type: "boolean",
          description: "Set as default job for new shifts",
        },
        template: {
          type: "string",
          enum: ["restaurant", "barbershop", "events", "custom"],
          description: "Job template type",
        },
      },
      required: ["name"],
    },
  },

  {
    name: "edit_job",
    description: "Modify job details",
    parameters: {
      type: "object",
      properties: {
        jobId: { type: "string" },
        updates: { type: "object", description: "Fields to update" },
      },
      required: ["jobId", "updates"],
    },
  },

  {
    name: "delete_job",
    description: "Remove a job. Ask user if they want to delete associated shifts too.",
    parameters: {
      type: "object",
      properties: {
        jobId: { type: "string" },
        deleteShifts: {
          type: "boolean",
          description: "If true, delete all shifts for this job. If false, soft-delete shifts.",
        },
        confirmed: { type: "boolean" },
      },
      required: ["jobId"],
    },
  },

  {
    name: "set_default_job",
    description: "Mark a job as the default for new shifts",
    parameters: {
      type: "object",
      properties: {
        jobId: { type: "string" },
      },
      required: ["jobId"],
    },
  },

  {
    name: "end_job",
    description: "Mark job as inactive/ended but keep all data",
    parameters: {
      type: "object",
      properties: {
        jobId: { type: "string" },
        endDate: { type: "string", description: "When job ended (default today)" },
      },
      required: ["jobId"],
    },
  },

  {
    name: "restore_job",
    description: "Reactivate an ended job",
    parameters: {
      type: "object",
      properties: {
        jobId: { type: "string" },
      },
      required: ["jobId"],
    },
  },

  {
    name: "get_jobs",
    description: "List all user's jobs with stats",
    parameters: {
      type: "object",
      properties: {
        includeEnded: { type: "boolean", description: "Include inactive jobs" },
        includeDeleted: { type: "boolean", description: "Include soft-deleted jobs" },
      },
    },
  },

  {
    name: "get_job_stats",
    description: "Get detailed statistics for a specific job",
    parameters: {
      type: "object",
      properties: {
        jobId: { type: "string" },
        period: {
          type: "string",
          enum: ["week", "month", "year", "all_time"],
          description: "Time period for stats",
        },
      },
      required: ["jobId"],
    },
  },

  {
    name: "compare_jobs",
    description: "Compare earnings between multiple jobs",
    parameters: {
      type: "object",
      properties: {
        jobIds: {
          type: "array",
          items: { type: "string" },
          description: "Array of job UUIDs to compare",
        },
        period: { type: "string", description: "Time period" },
      },
      required: ["jobIds"],
    },
  },

  {
    name: "set_job_hourly_rate",
    description: "Update hourly rate for a job",
    parameters: {
      type: "object",
      properties: {
        jobId: { type: "string" },
        newRate: { type: "number" },
        effectiveDate: {
          type: "string",
          description: "When rate takes effect (default today)",
        },
        updatePastShifts: {
          type: "boolean",
          description: "Apply new rate to past shifts",
        },
      },
      required: ["jobId", "newRate"],
    },
  },

  // ============================================
  // GOAL MANAGEMENT (8 functions)
  // ============================================
  {
    name: "set_daily_goal",
    description: "Create or update daily income goal",
    parameters: {
      type: "object",
      properties: {
        amount: { type: "number", description: "Target daily income in dollars" },
        jobId: {
          type: "string",
          description: "Specific job (null = overall daily goal)",
        },
        targetHours: { type: "number", description: "Optional hours target" },
      },
      required: ["amount"],
    },
  },

  {
    name: "set_weekly_goal",
    description: "Create or update weekly income goal",
    parameters: {
      type: "object",
      properties: {
        amount: { type: "number" },
        jobId: { type: "string" },
        targetHours: { type: "number" },
      },
      required: ["amount"],
    },
  },

  {
    name: "set_monthly_goal",
    description: "Create or update monthly income goal",
    parameters: {
      type: "object",
      properties: {
        amount: { type: "number" },
        jobId: { type: "string" },
        targetHours: { type: "number" },
      },
      required: ["amount"],
    },
  },

  {
    name: "set_yearly_goal",
    description: "Create or update yearly income goal",
    parameters: {
      type: "object",
      properties: {
        amount: { type: "number" },
        jobId: { type: "string" },
        targetHours: { type: "number" },
      },
      required: ["amount"],
    },
  },

  {
    name: "edit_goal",
    description: "Modify existing goal",
    parameters: {
      type: "object",
      properties: {
        goalId: { type: "string" },
        updates: { type: "object" },
      },
      required: ["goalId", "updates"],
    },
  },

  {
    name: "delete_goal",
    description: "Remove a goal",
    parameters: {
      type: "object",
      properties: {
        goalId: { type: "string" },
      },
      required: ["goalId"],
    },
  },

  {
    name: "get_goals",
    description: "List all goals with current progress",
    parameters: {
      type: "object",
      properties: {
        includeCompleted: { type: "boolean" },
      },
    },
  },

  {
    name: "get_goal_progress",
    description: "Check progress on a specific goal",
    parameters: {
      type: "object",
      properties: {
        goalId: { type: "string" },
      },
      required: ["goalId"],
    },
  },

  // ============================================
  // THEME & APPEARANCE (4 functions)
  // ============================================
  {
    name: "change_theme",
    description: "Switch app theme/color scheme. Parse natural language: 'light mode'→'light_mode', 'dark mode'→'finance_green'",
    parameters: {
      type: "object",
      properties: {
        theme: {
          type: "string",
          enum: [
            "light_mode",
            "finance_green",
            "midnight_blue",
            "purple_reign",
            "ocean_breeze",
            "sunset_glow",
            "forest_night",
            "paypal_blue",
            "finance_pro",
            "light_blue",
            "soft_purple",
          ],
          description: "Theme name",
        },
      },
      required: ["theme"],
    },
  },

  {
    name: "get_available_themes",
    description: "List all available themes",
    parameters: { type: "object" },
  },

  {
    name: "preview_theme",
    description: "Show theme colors without applying",
    parameters: {
      type: "object",
      properties: {
        theme: { type: "string" },
      },
      required: ["theme"],
    },
  },

  {
    name: "revert_theme",
    description: "Undo last theme change",
    parameters: { type: "object" },
  },

  // ============================================
  // NOTIFICATIONS (5 functions)
  // ============================================
  {
    name: "toggle_notifications",
    description: "Turn all notifications on or off",
    parameters: {
      type: "object",
      properties: {
        enabled: { type: "boolean" },
      },
      required: ["enabled"],
    },
  },

  {
    name: "set_shift_reminders",
    description: "Configure shift reminder notifications",
    parameters: {
      type: "object",
      properties: {
        enabled: { type: "boolean" },
        reminderTime: {
          type: "string",
          enum: ["morning", "evening", "both"],
        },
        daysBeforeShift: { type: "number" },
      },
      required: ["enabled"],
    },
  },

  {
    name: "set_goal_reminders",
    description: "Configure goal progress notifications",
    parameters: {
      type: "object",
      properties: {
        enabled: { type: "boolean" },
        frequency: {
          type: "string",
          enum: ["daily", "weekly", "monthly"],
        },
      },
      required: ["enabled"],
    },
  },

  {
    name: "set_quiet_hours",
    description: "Set times when notifications are silenced",
    parameters: {
      type: "object",
      properties: {
        enabled: { type: "boolean" },
        startTime: { type: "string", description: "HH:MM format" },
        endTime: { type: "string", description: "HH:MM format" },
      },
      required: ["enabled"],
    },
  },

  {
    name: "get_notification_settings",
    description: "Retrieve current notification preferences",
    parameters: { type: "object" },
  },

  // ============================================
  // SETTINGS & PREFERENCES (8 functions)
  // ============================================
  {
    name: "update_tax_settings",
    description: "Modify tax estimation settings",
    parameters: {
      type: "object",
      properties: {
        filingStatus: {
          type: "string",
          enum: ["single", "married_joint", "married_separate", "head_of_household"],
        },
        dependents: { type: "number" },
        additionalIncome: { type: "number" },
        deductions: { type: "number" },
        isSelfEmployed: { type: "boolean" },
      },
    },
  },

  {
    name: "set_currency_format",
    description: "Change currency display",
    parameters: {
      type: "object",
      properties: {
        currencyCode: { type: "string", description: "USD, EUR, GBP, etc." },
        showCents: { type: "boolean" },
      },
      required: ["currencyCode"],
    },
  },

  {
    name: "set_date_format",
    description: "Change date display format",
    parameters: {
      type: "object",
      properties: {
        format: {
          type: "string",
          enum: ["MM/DD/YYYY", "DD/MM/YYYY", "YYYY-MM-DD"],
        },
      },
      required: ["format"],
    },
  },

  {
    name: "set_week_start_day",
    description: "Set which day starts the week",
    parameters: {
      type: "object",
      properties: {
        day: { type: "string", enum: ["sunday", "monday"] },
      },
      required: ["day"],
    },
  },

  {
    name: "export_data_csv",
    description: "Generate CSV export of all data",
    parameters: {
      type: "object",
      properties: {
        dateRange: { type: "object", description: "Optional filter" },
        includePhotos: { type: "boolean" },
      },
    },
  },

  {
    name: "export_data_pdf",
    description: "Generate PDF report",
    parameters: {
      type: "object",
      properties: {
        dateRange: { type: "object" },
        reportType: {
          type: "string",
          enum: ["summary", "detailed", "tax_ready"],
        },
      },
    },
  },

  {
    name: "clear_chat_history",
    description: "Delete all chat messages. Confirm first.",
    parameters: {
      type: "object",
      properties: {
        confirmed: { type: "boolean" },
      },
    },
  },

  {
    name: "get_user_settings",
    description: "Retrieve all current settings",
    parameters: { type: "object" },
  },

  // ============================================
  // ANALYTICS & QUERIES (8 functions)
  // ============================================
  {
    name: "get_income_summary",
    description: "Get total income for a time period",
    parameters: {
      type: "object",
      properties: {
        period: {
          type: "string",
          enum: ["today", "week", "month", "year", "custom"],
        },
        dateRange: {
          type: "object",
          description: "Required if period=custom: {start, end}",
        },
        jobId: { type: "string", description: "Optional: filter by job" },
      },
      required: ["period"],
    },
  },

  {
    name: "compare_periods",
    description: "Compare income across two time periods",
    parameters: {
      type: "object",
      properties: {
        period1: {
          type: "object",
          description: "{period: 'month', year: 2025, month: 11}",
        },
        period2: {
          type: "object",
          description: "{period: 'month', year: 2025, month: 12}",
        },
      },
      required: ["period1", "period2"],
    },
  },

  {
    name: "get_best_days",
    description: "Find highest-earning days of the week",
    parameters: {
      type: "object",
      properties: {
        limit: { type: "number", description: "Number of days to return (default 5)" },
        jobId: { type: "string" },
      },
    },
  },

  {
    name: "get_worst_days",
    description: "Find lowest-earning days of the week",
    parameters: {
      type: "object",
      properties: {
        limit: { type: "number" },
        jobId: { type: "string" },
      },
    },
  },

  {
    name: "get_tax_estimate",
    description: "Calculate federal tax estimate for the year",
    parameters: {
      type: "object",
      properties: {
        year: { type: "number", description: "Tax year (default current year)" },
      },
    },
  },

  {
    name: "get_projected_year_end",
    description: "Project year-end income based on current pace",
    parameters: {
      type: "object",
      properties: {
        year: { type: "number" },
      },
    },
  },

  {
    name: "get_year_over_year",
    description: "Compare this year to last year",
    parameters: { type: "object" },
  },

  {
    name: "get_event_earnings",
    description: "Total earnings from a specific event/party",
    parameters: {
      type: "object",
      properties: {
        eventName: { type: "string" },
      },
      required: ["eventName"],
    },
  },
];
