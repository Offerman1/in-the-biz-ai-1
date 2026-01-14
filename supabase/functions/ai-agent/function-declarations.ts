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
        // ============================================
        // RIDESHARE & DELIVERY FIELDS
        // ============================================
        ridesCount: {
          type: "number",
          description: "Number of rides completed (Uber, Lyft, etc.)",
        },
        deliveriesCount: {
          type: "number",
          description: "Number of deliveries completed (DoorDash, UberEats, etc.)",
        },
        deadMiles: {
          type: "number",
          description: "Miles driven without a passenger or delivery",
        },
        fuelCost: {
          type: "number",
          description: "Fuel expenses for the shift in dollars",
        },
        tollsParking: {
          type: "number",
          description: "Tolls and parking fees in dollars",
        },
        surgeMultiplier: {
          type: "number",
          description: "Average surge/boost multiplier (e.g., 1.5, 2.0)",
        },
        acceptanceRate: {
          type: "number",
          description: "Percentage of ride/delivery requests accepted (0-100)",
        },
        baseFare: {
          type: "number",
          description: "Total base fares before tips in dollars",
        },
        // ============================================
        // MUSIC & ENTERTAINMENT FIELDS
        // ============================================
        gigType: {
          type: "string",
          description: "Type of performance: wedding, corporate, club, private, etc.",
        },
        setupHours: {
          type: "number",
          description: "Hours spent setting up equipment",
        },
        performanceHours: {
          type: "number",
          description: "Hours performing",
        },
        breakdownHours: {
          type: "number",
          description: "Hours breaking down equipment",
        },
        equipmentUsed: {
          type: "string",
          description: "Equipment used for the gig",
        },
        equipmentRentalCost: {
          type: "number",
          description: "Cost of rented equipment in dollars",
        },
        crewPayment: {
          type: "number",
          description: "Payment to crew members in dollars",
        },
        merchSales: {
          type: "number",
          description: "Merchandise sales revenue in dollars",
        },
        audienceSize: {
          type: "number",
          description: "Estimated audience size",
        },
        // ============================================
        // ARTIST & CRAFTS FIELDS
        // ============================================
        piecesCreated: {
          type: "number",
          description: "Number of pieces/items created",
        },
        piecesSold: {
          type: "number",
          description: "Number of pieces/items sold",
        },
        materialsCost: {
          type: "number",
          description: "Cost of materials used in dollars",
        },
        salePrice: {
          type: "number",
          description: "Total sale price of items in dollars",
        },
        venueCommissionPercent: {
          type: "number",
          description: "Commission percentage taken by venue (0-100)",
        },
        // ============================================
        // RETAIL/SALES FIELDS
        // ============================================
        itemsSold: {
          type: "number",
          description: "Number of items sold",
        },
        transactionsCount: {
          type: "number",
          description: "Number of transactions processed",
        },
        upsellsCount: {
          type: "number",
          description: "Number of successful upsells",
        },
        upsellsAmount: {
          type: "number",
          description: "Revenue from upsells in dollars",
        },
        returnsCount: {
          type: "number",
          description: "Number of returns processed",
        },
        returnsAmount: {
          type: "number",
          description: "Value of returned items in dollars",
        },
        shrinkAmount: {
          type: "number",
          description: "Shrink/loss amount in dollars",
        },
        department: {
          type: "string",
          description: "Department worked in",
        },
        // ============================================
        // SALON/SPA FIELDS
        // ============================================
        serviceType: {
          type: "string",
          description: "Type of service provided (haircut, color, massage, etc.)",
        },
        servicesCount: {
          type: "number",
          description: "Number of services performed",
        },
        productSales: {
          type: "number",
          description: "Product sales revenue in dollars",
        },
        repeatClientPercent: {
          type: "number",
          description: "Percentage of repeat clients (0-100)",
        },
        chairRental: {
          type: "number",
          description: "Chair rental fee paid in dollars",
        },
        newClientsCount: {
          type: "number",
          description: "Number of new clients",
        },
        returningClientsCount: {
          type: "number",
          description: "Number of returning clients",
        },
        walkinCount: {
          type: "number",
          description: "Number of walk-in clients",
        },
        appointmentCount: {
          type: "number",
          description: "Number of scheduled appointments",
        },
        // ============================================
        // HOSPITALITY FIELDS
        // ============================================
        roomType: {
          type: "string",
          description: "Type of room (standard, suite, penthouse, etc.)",
        },
        roomsCleaned: {
          type: "number",
          description: "Number of rooms cleaned (housekeeping)",
        },
        qualityScore: {
          type: "number",
          description: "Quality inspection score (0-100)",
        },
        shiftType: {
          type: "string",
          description: "Shift type: day, swing, night, graveyard",
        },
        roomUpgrades: {
          type: "number",
          description: "Number of room upgrades sold",
        },
        guestsCheckedIn: {
          type: "number",
          description: "Number of guests checked in (front desk)",
        },
        carsParked: {
          type: "number",
          description: "Number of cars parked (valet)",
        },
        // ============================================
        // HEALTHCARE FIELDS
        // ============================================
        patientCount: {
          type: "number",
          description: "Number of patients seen",
        },
        shiftDifferential: {
          type: "number",
          description: "Shift differential pay in dollars (night/weekend premium)",
        },
        onCallHours: {
          type: "number",
          description: "Hours on call",
        },
        proceduresCount: {
          type: "number",
          description: "Number of procedures performed/assisted",
        },
        specialization: {
          type: "string",
          description: "Medical specialization (ER, ICU, OR, etc.)",
        },
        // ============================================
        // FITNESS FIELDS
        // ============================================
        sessionsCount: {
          type: "number",
          description: "Number of training sessions conducted",
        },
        sessionType: {
          type: "string",
          description: "Type of session: personal, group, class",
        },
        classSize: {
          type: "number",
          description: "Average class size for group sessions",
        },
        retentionRate: {
          type: "number",
          description: "Client retention percentage (0-100)",
        },
        cancellationsCount: {
          type: "number",
          description: "Number of client cancellations",
        },
        packageSales: {
          type: "number",
          description: "Package sales revenue in dollars",
        },
        supplementSales: {
          type: "number",
          description: "Supplement/product sales in dollars",
        },
        // ============================================
        // CONSTRUCTION/TRADES FIELDS
        // ============================================
        laborCost: {
          type: "number",
          description: "Labor costs in dollars",
        },
        subcontractorCost: {
          type: "number",
          description: "Subcontractor costs in dollars",
        },
        squareFootage: {
          type: "number",
          description: "Square footage worked",
        },
        weatherDelayHours: {
          type: "number",
          description: "Hours delayed due to weather",
        },
        // ============================================
        // FREELANCER FIELDS
        // ============================================
        revisionsCount: {
          type: "number",
          description: "Number of revisions requested by client",
        },
        clientType: {
          type: "string",
          description: "Client type: new, returning, referral",
        },
        expenses: {
          type: "number",
          description: "Business expenses for the shift in dollars",
        },
        billableHours: {
          type: "number",
          description: "Billable hours worked",
        },
        // ============================================
        // RESTAURANT ADDITIONAL FIELDS
        // ============================================
        tableSection: {
          type: "string",
          description: "Table section worked (e.g., patio, bar, main floor)",
        },
        cashSales: {
          type: "number",
          description: "Cash sales amount in dollars",
        },
        cardSales: {
          type: "number",
          description: "Card sales amount in dollars",
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
          description: "Optional: Link to a specific shift UUID. If user mentions adding contact to a BEO shift, first find the shift linked to the BEO (shifts.beo_event_id) and use that shiftId",
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

  {
    name: "link_contact_to_shift",
    description: "Link an existing contact to a shift. Use this when user says 'add [contact name] to the shift' or 'link [contact] to [shift]'",
    parameters: {
      type: "object",
      properties: {
        contactId: {
          type: "string",
          description: "Contact UUID (if known)"
        },
        contactName: {
          type: "string",
          description: "Contact name to search for (if contactId not known)"
        },
        shiftId: {
          type: "string",
          description: "Shift UUID to link the contact to"
        },
      },
      required: ["shiftId"],
    },
  },

  {
    name: "link_contacts_to_beo_shift",
    description: "Link multiple contacts to the shift that's connected to a BEO event. Use when user says 'add [contacts] to the BEO shift' or 'link staff to the wedding BEO'",
    parameters: {
      type: "object",
      properties: {
        beoEventId: {
          type: "string",
          description: "BEO event UUID"
        },
        contactIds: {
          type: "array",
          items: { type: "string" },
          description: "Array of contact UUIDs to link"
        },
        contactNames: {
          type: "array",
          items: { type: "string" },
          description: "Array of contact names to search and link"
        },
      },
      required: ["beoEventId"],
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
          enum: [
            "restaurant",
            "barbershop",
            "events",
            "rideshare",
            "delivery",
            "salon",
            "hospitality",
            "fitness",
            "healthcare",
            "construction",
            "freelancer",
            "retail",
            "custom",
          ],
          description: "Job template type - determines which fields appear for shift tracking",
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
    description: "Switch app theme/color scheme. Parse natural language: 'light'→'cash_light', 'dark'→'cash_app'",
    parameters: {
      type: "object",
      properties: {
        theme: {
          type: "string",
          enum: [
            "cash_app",
            "midnight_blue",
            "purple_reign",
            "ocean_breeze",
            "sunset_glow",
            "neon_cash",
            "paypal_blue",
            "coinbase_pro",
            "cash_light",
            "light_blue",
            "purple_light",
            "sunset_light",
            "ocean_light",
            "pink_light",
            "slate_light",
            "mint_light",
            "lavender_light",
            "gold_light",
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

  // ============================================
  // FEATURE REQUESTS (1 function)
  // ============================================
  {
    name: "send_feature_request",
    description: "Send a feature request or idea to the development team. Use this when user wants to suggest a feature, report something they wish the app could do, or when you can't fulfill a request and they agree to submit it as a suggestion.",
    parameters: {
      type: "object",
      properties: {
        idea: {
          type: "string",
          description: "The feature idea or request from the user. Be descriptive - include what they want and why.",
        },
        category: {
          type: "string",
          description: "Category of the request: 'new_feature', 'improvement', 'bug_report', 'integration', 'other'",
          enum: ["new_feature", "improvement", "bug_report", "integration", "other"],
        },
      },
      required: ["idea"],
    },
  },

  // ============================================
  // TIME QUERIES (1 function)
  // ============================================
  {
    name: "get_current_time",
    description: "Get the current local time. Use this when user asks 'what time is it?' or similar.",
    parameters: {
      type: "object",
      properties: {},
    },
  },

  // ============================================
  // BEO EVENTS MANAGEMENT (14 functions)
  // ============================================
  {
    name: "get_beo_events",
    description: "List all BEO (Banquet Event Order) events with optional filters.",
    parameters: {
      type: "object",
      properties: {
        upcoming: { type: "boolean", description: "Show only upcoming events" },
        past: { type: "boolean", description: "Show only past events" },
        startDate: { type: "string", description: "Filter from date (YYYY-MM-DD)" },
        endDate: { type: "string", description: "Filter to date (YYYY-MM-DD)" },
        venue: { type: "string", description: "Filter by venue name" },
        clientName: { type: "string", description: "Filter by client/contact name" },
      },
    },
  },

  {
    name: "search_beo_events",
    description: "Search BEO events by name, venue, or client.",
    parameters: {
      type: "object",
      properties: {
        searchTerm: { type: "string", description: "Search query" },
      },
      required: ["searchTerm"],
    },
  },

  {
    name: "get_beo_details",
    description: "Get complete details of a specific BEO event.",
    parameters: {
      type: "object",
      properties: {
        eventId: { type: "string", description: "BEO event UUID" },
      },
      required: ["eventId"],
    },
  },

  {
    name: "get_upcoming_beos",
    description: "Get BEO events happening in the next N days.",
    parameters: {
      type: "object",
      properties: {
        daysAhead: { type: "number", description: "Number of days (default 30)" },
      },
    },
  },

  {
    name: "link_beo_to_shift",
    description: "Associate a BEO event with a shift.",
    parameters: {
      type: "object",
      properties: {
        eventId: { type: "string", description: "BEO event UUID" },
        shiftId: { type: "string", description: "Shift UUID" },
      },
      required: ["eventId", "shiftId"],
    },
  },

  {
    name: "unlink_beo_from_shift",
    description: "Remove BEO event association from a shift.",
    parameters: {
      type: "object",
      properties: {
        shiftId: { type: "string", description: "Shift UUID" },
      },
      required: ["shiftId"],
    },
  },

  {
    name: "edit_beo_event",
    description: "Modify BEO event details.",
    parameters: {
      type: "object",
      properties: {
        eventId: { type: "string", description: "BEO event UUID" },
        updates: { type: "object", description: "Fields to update" },
      },
      required: ["eventId", "updates"],
    },
  },

  {
    name: "delete_beo_event",
    description: "Delete a BEO event (requires confirmation).",
    parameters: {
      type: "object",
      properties: {
        eventId: { type: "string", description: "BEO event UUID" },
        confirmed: { type: "boolean", description: "Must be true after confirmation" },
      },
      required: ["eventId"],
    },
  },

  {
    name: "get_beo_contacts",
    description: "Get all contacts for a BEO event.",
    parameters: {
      type: "object",
      properties: {
        eventId: { type: "string", description: "BEO event UUID" },
      },
      required: ["eventId"],
    },
  },

  {
    name: "get_beos_by_venue",
    description: "Find all BEO events at a specific venue.",
    parameters: {
      type: "object",
      properties: {
        venueName: { type: "string", description: "Venue name" },
      },
      required: ["venueName"],
    },
  },

  {
    name: "get_beos_by_client",
    description: "Find all BEO events for a specific client.",
    parameters: {
      type: "object",
      properties: {
        clientName: { type: "string", description: "Client name" },
      },
      required: ["clientName"],
    },
  },

  {
    name: "get_beo_earnings",
    description: "Calculate expected earnings from a BEO event.",
    parameters: {
      type: "object",
      properties: {
        eventId: { type: "string", description: "BEO event UUID" },
      },
      required: ["eventId"],
    },
  },

  {
    name: "get_beo_timeline",
    description: "Get the event timeline/schedule from a BEO.",
    parameters: {
      type: "object",
      properties: {
        eventId: { type: "string", description: "BEO event UUID" },
      },
      required: ["eventId"],
    },
  },

  // ============================================
  // SERVER CHECKOUTS MANAGEMENT (12 functions)
  // ============================================
  {
    name: "get_checkouts",
    description: "List server checkouts with optional filters.",
    parameters: {
      type: "object",
      properties: {
        startDate: { type: "string", description: "From date (YYYY-MM-DD)" },
        endDate: { type: "string", description: "To date (YYYY-MM-DD)" },
        jobId: { type: "string", description: "Filter by job UUID" },
        minTips: { type: "number", description: "Minimum tips amount" },
        maxTips: { type: "number", description: "Maximum tips amount" },
      },
    },
  },

  {
    name: "search_checkouts",
    description: "Search checkouts by section or notes.",
    parameters: {
      type: "object",
      properties: {
        searchTerm: { type: "string", description: "Search query" },
      },
      required: ["searchTerm"],
    },
  },

  {
    name: "get_checkout_details",
    description: "Get complete details of a server checkout.",
    parameters: {
      type: "object",
      properties: {
        checkoutId: { type: "string", description: "Checkout UUID" },
      },
      required: ["checkoutId"],
    },
  },

  {
    name: "link_checkout_to_shift",
    description: "Associate a checkout with a shift.",
    parameters: {
      type: "object",
      properties: {
        checkoutId: { type: "string", description: "Checkout UUID" },
        shiftId: { type: "string", description: "Shift UUID" },
      },
      required: ["checkoutId", "shiftId"],
    },
  },

  {
    name: "unlink_checkout_from_shift",
    description: "Remove checkout association from a shift.",
    parameters: {
      type: "object",
      properties: {
        shiftId: { type: "string", description: "Shift UUID" },
      },
      required: ["shiftId"],
    },
  },

  {
    name: "edit_checkout",
    description: "Modify checkout details.",
    parameters: {
      type: "object",
      properties: {
        checkoutId: { type: "string", description: "Checkout UUID" },
        updates: { type: "object", description: "Fields to update" },
      },
      required: ["checkoutId", "updates"],
    },
  },

  {
    name: "delete_checkout",
    description: "Delete a checkout (requires confirmation).",
    parameters: {
      type: "object",
      properties: {
        checkoutId: { type: "string", description: "Checkout UUID" },
        confirmed: { type: "boolean", description: "Must be true after confirmation" },
      },
      required: ["checkoutId"],
    },
  },

  {
    name: "get_checkout_stats",
    description: "Get statistics for checkouts in a period.",
    parameters: {
      type: "object",
      properties: {
        startDate: { type: "string", description: "From date (YYYY-MM-DD)" },
        endDate: { type: "string", description: "To date (YYYY-MM-DD)" },
        jobId: { type: "string", description: "Filter by job UUID" },
      },
    },
  },

  {
    name: "compare_checkouts",
    description: "Compare two checkouts side by side.",
    parameters: {
      type: "object",
      properties: {
        checkout1Id: { type: "string", description: "First checkout UUID" },
        checkout2Id: { type: "string", description: "Second checkout UUID" },
      },
      required: ["checkout1Id", "checkout2Id"],
    },
  },

  {
    name: "get_tipshare_breakdown",
    description: "Get detailed tipshare breakdown for a checkout.",
    parameters: {
      type: "object",
      properties: {
        checkoutId: { type: "string", description: "Checkout UUID" },
      },
      required: ["checkoutId"],
    },
  },

  {
    name: "get_section_stats",
    description: "Get statistics for a specific section.",
    parameters: {
      type: "object",
      properties: {
        section: { type: "string", description: "Section name" },
        startDate: { type: "string", description: "From date (YYYY-MM-DD)" },
        endDate: { type: "string", description: "To date (YYYY-MM-DD)" },
      },
      required: ["section"],
    },
  },

  // ============================================
  // PAYCHECKS MANAGEMENT (15 functions)
  // ============================================
  {
    name: "get_paychecks",
    description: "List all paychecks with optional filters.",
    parameters: {
      type: "object",
      properties: {
        startDate: { type: "string", description: "From date (YYYY-MM-DD)" },
        endDate: { type: "string", description: "To date (YYYY-MM-DD)" },
        year: { type: "number", description: "Filter by year" },
        employerName: { type: "string", description: "Filter by employer" },
      },
    },
  },

  {
    name: "search_paychecks",
    description: "Search paychecks by employer or payroll provider.",
    parameters: {
      type: "object",
      properties: {
        searchTerm: { type: "string", description: "Search query" },
      },
      required: ["searchTerm"],
    },
  },

  {
    name: "get_paycheck_details",
    description: "Get complete details of a paycheck.",
    parameters: {
      type: "object",
      properties: {
        paycheckId: { type: "string", description: "Paycheck UUID" },
      },
      required: ["paycheckId"],
    },
  },

  {
    name: "get_upcoming_paycheck",
    description: "Predict the date of the next paycheck.",
    parameters: {
      type: "object",
      properties: {},
    },
  },

  {
    name: "get_ytd_earnings",
    description: "Get year-to-date earnings totals.",
    parameters: {
      type: "object",
      properties: {
        year: { type: "number", description: "Year (default current year)" },
      },
    },
  },

  {
    name: "edit_paycheck",
    description: "Modify paycheck details.",
    parameters: {
      type: "object",
      properties: {
        paycheckId: { type: "string", description: "Paycheck UUID" },
        updates: { type: "object", description: "Fields to update" },
      },
      required: ["paycheckId", "updates"],
    },
  },

  {
    name: "delete_paycheck",
    description: "Delete a paycheck (requires confirmation).",
    parameters: {
      type: "object",
      properties: {
        paycheckId: { type: "string", description: "Paycheck UUID" },
        confirmed: { type: "boolean", description: "Must be true after confirmation" },
      },
      required: ["paycheckId"],
    },
  },

  {
    name: "get_deduction_summary",
    description: "Get summary of all deductions for a year.",
    parameters: {
      type: "object",
      properties: {
        year: { type: "number", description: "Year (default current year)" },
      },
    },
  },

  {
    name: "get_tax_withholding_summary",
    description: "Get summary of tax withholdings for a year.",
    parameters: {
      type: "object",
      properties: {
        year: { type: "number", description: "Year (default current year)" },
      },
    },
  },

  {
    name: "compare_paychecks",
    description: "Compare two paychecks side by side.",
    parameters: {
      type: "object",
      properties: {
        paycheck1Id: { type: "string", description: "First paycheck UUID" },
        paycheck2Id: { type: "string", description: "Second paycheck UUID" },
      },
      required: ["paycheck1Id", "paycheck2Id"],
    },
  },

  {
    name: "get_pay_frequency",
    description: "Determine pay frequency (weekly, bi-weekly, etc).",
    parameters: {
      type: "object",
      properties: {},
    },
  },

  {
    name: "project_annual_salary",
    description: "Project annual salary based on recent paychecks.",
    parameters: {
      type: "object",
      properties: {},
    },
  },

  // ============================================
  // RECEIPTS/EXPENSES MANAGEMENT (12 functions)
  // ============================================
  {
    name: "get_receipts",
    description: "List receipts/expenses with optional filters.",
    parameters: {
      type: "object",
      properties: {
        startDate: { type: "string", description: "From date (YYYY-MM-DD)" },
        endDate: { type: "string", description: "To date (YYYY-MM-DD)" },
        vendor: { type: "string", description: "Filter by vendor name" },
        category: { type: "string", description: "Filter by expense category" },
        minAmount: { type: "number", description: "Minimum amount" },
        maxAmount: { type: "number", description: "Maximum amount" },
        deductibleOnly: { type: "boolean", description: "Only tax deductible" },
      },
    },
  },

  {
    name: "search_receipts",
    description: "Search receipts by vendor, category, or receipt number.",
    parameters: {
      type: "object",
      properties: {
        searchTerm: { type: "string", description: "Search query" },
      },
      required: ["searchTerm"],
    },
  },

  {
    name: "get_receipt_details",
    description: "Get complete details of a receipt.",
    parameters: {
      type: "object",
      properties: {
        receiptId: { type: "string", description: "Receipt UUID" },
      },
      required: ["receiptId"],
    },
  },

  {
    name: "get_expense_summary",
    description: "Get summary of expenses by category.",
    parameters: {
      type: "object",
      properties: {
        startDate: { type: "string", description: "From date (YYYY-MM-DD)" },
        endDate: { type: "string", description: "To date (YYYY-MM-DD)" },
        category: { type: "string", description: "Filter by category" },
      },
    },
  },

  {
    name: "get_deductible_expenses",
    description: "Get all tax-deductible expenses for a year.",
    parameters: {
      type: "object",
      properties: {
        year: { type: "number", description: "Year (default current year)" },
      },
    },
  },

  {
    name: "categorize_receipt",
    description: "Update the expense category of a receipt.",
    parameters: {
      type: "object",
      properties: {
        receiptId: { type: "string", description: "Receipt UUID" },
        category: { type: "string", description: "New expense category" },
      },
      required: ["receiptId", "category"],
    },
  },

  {
    name: "mark_receipt_deductible",
    description: "Mark a receipt as tax deductible or not.",
    parameters: {
      type: "object",
      properties: {
        receiptId: { type: "string", description: "Receipt UUID" },
        isDeductible: { type: "boolean", description: "True if tax deductible" },
      },
      required: ["receiptId", "isDeductible"],
    },
  },

  {
    name: "link_receipt_to_shift",
    description: "Associate a receipt with a shift.",
    parameters: {
      type: "object",
      properties: {
        receiptId: { type: "string", description: "Receipt UUID" },
        shiftId: { type: "string", description: "Shift UUID" },
      },
      required: ["receiptId", "shiftId"],
    },
  },

  {
    name: "edit_receipt",
    description: "Modify receipt details.",
    parameters: {
      type: "object",
      properties: {
        receiptId: { type: "string", description: "Receipt UUID" },
        updates: { type: "object", description: "Fields to update" },
      },
      required: ["receiptId", "updates"],
    },
  },

  {
    name: "delete_receipt",
    description: "Delete a receipt (requires confirmation).",
    parameters: {
      type: "object",
      properties: {
        receiptId: { type: "string", description: "Receipt UUID" },
        confirmed: { type: "boolean", description: "Must be true after confirmation" },
      },
      required: ["receiptId"],
    },
  },

  // ============================================
  // INVOICES MANAGEMENT (14 functions)
  // ============================================
  {
    name: "get_invoices",
    description: "List invoices with optional filters.",
    parameters: {
      type: "object",
      properties: {
        startDate: { type: "string", description: "From date (YYYY-MM-DD)" },
        endDate: { type: "string", description: "To date (YYYY-MM-DD)" },
        client: { type: "string", description: "Filter by client name" },
        status: { type: "string", description: "Filter by status (paid, unpaid, overdue)" },
        minAmount: { type: "number", description: "Minimum amount" },
        maxAmount: { type: "number", description: "Maximum amount" },
      },
    },
  },

  {
    name: "search_invoices",
    description: "Search invoices by client or invoice number.",
    parameters: {
      type: "object",
      properties: {
        searchTerm: { type: "string", description: "Search query" },
      },
      required: ["searchTerm"],
    },
  },

  {
    name: "get_invoice_details",
    description: "Get complete details of an invoice.",
    parameters: {
      type: "object",
      properties: {
        invoiceId: { type: "string", description: "Invoice UUID" },
      },
      required: ["invoiceId"],
    },
  },

  {
    name: "get_unpaid_invoices",
    description: "List all unpaid invoices.",
    parameters: {
      type: "object",
      properties: {},
    },
  },

  {
    name: "get_overdue_invoices",
    description: "List all overdue invoices.",
    parameters: {
      type: "object",
      properties: {},
    },
  },

  {
    name: "get_total_receivables",
    description: "Get total amount owed from unpaid invoices.",
    parameters: {
      type: "object",
      properties: {},
    },
  },

  {
    name: "mark_invoice_paid",
    description: "Record a payment on an invoice.",
    parameters: {
      type: "object",
      properties: {
        invoiceId: { type: "string", description: "Invoice UUID" },
        amountPaid: { type: "number", description: "Payment amount" },
        paidDate: { type: "string", description: "Payment date (YYYY-MM-DD)" },
      },
      required: ["invoiceId", "amountPaid"],
    },
  },

  {
    name: "mark_invoice_overdue",
    description: "Mark an invoice as overdue.",
    parameters: {
      type: "object",
      properties: {
        invoiceId: { type: "string", description: "Invoice UUID" },
      },
      required: ["invoiceId"],
    },
  },

  {
    name: "link_invoice_to_shift",
    description: "Associate an invoice with a shift.",
    parameters: {
      type: "object",
      properties: {
        invoiceId: { type: "string", description: "Invoice UUID" },
        shiftId: { type: "string", description: "Shift UUID" },
      },
      required: ["invoiceId", "shiftId"],
    },
  },

  {
    name: "edit_invoice",
    description: "Modify invoice details.",
    parameters: {
      type: "object",
      properties: {
        invoiceId: { type: "string", description: "Invoice UUID" },
        updates: { type: "object", description: "Fields to update" },
      },
      required: ["invoiceId", "updates"],
    },
  },

  {
    name: "delete_invoice",
    description: "Delete an invoice (requires confirmation).",
    parameters: {
      type: "object",
      properties: {
        invoiceId: { type: "string", description: "Invoice UUID" },
        confirmed: { type: "boolean", description: "Must be true after confirmation" },
      },
      required: ["invoiceId"],
    },
  },
];
