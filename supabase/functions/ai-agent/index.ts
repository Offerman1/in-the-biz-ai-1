// AI Agent Edge Function - Handles all AI function calling
// This is the brain that connects the AI to your app's data
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleGenerativeAI, FunctionCallingMode } from "https://esm.sh/@google/generative-ai";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(Deno.env.get("GEMINI_API_KEY") || "");

// Get the model with function calling
const model = genAI.getGenerativeModel({
  model: "gemini-2.0-flash",
  generationConfig: {
    temperature: 0.7,
    topP: 0.95,
    topK: 40,
    maxOutputTokens: 8192,
  },
});

// ============================================
// FUNCTION DECLARATIONS
// ============================================
const functionDeclarations = [
  // ============================================
  // SHIFT MANAGEMENT
  // ============================================
  {
    name: "add_shift",
    description: "Create a new shift/work session. Use this when the user says they worked, made money, had tips, completed deliveries, performed a gig, etc.",
    parameters: {
      type: "object",
      properties: {
        job_id: { type: "string", description: "UUID of the job. If user has one job, auto-select it. If multiple, ask which one." },
        date: { type: "string", description: "Date in YYYY-MM-DD format. Parse 'today', 'yesterday', 'last Monday' etc." },
        // Core earnings
        cash_tips: { type: "number", description: "Cash tips earned" },
        credit_tips: { type: "number", description: "Credit card tips" },
        hourly_rate: { type: "number", description: "Hourly wage rate" },
        hours_worked: { type: "number", description: "Hours worked (can calculate from start/end time)" },
        start_time: { type: "string", description: "Shift start time in HH:MM format" },
        end_time: { type: "string", description: "Shift end time in HH:MM format" },
        flat_rate: { type: "number", description: "Flat rate payment for the shift" },
        commission: { type: "number", description: "Commission earned" },
        overtime_hours: { type: "number", description: "Overtime hours worked" },
        // Tipout
        sales_amount: { type: "number", description: "Total sales amount (for tip % calculation)" },
        tipout_percent: { type: "number", description: "Tipout percentage given to others" },
        additional_tipout: { type: "number", description: "Extra tipout amount in dollars" },
        additional_tipout_note: { type: "string", description: "Who received the tipout (e.g., 'Busser', 'Bar')" },
        // Event/Catering
        event_name: { type: "string", description: "Name of the event or party" },
        event_cost: { type: "number", description: "Event cost/booking fee" },
        hostess: { type: "string", description: "Hostess or event coordinator name" },
        guest_count: { type: "integer", description: "Number of guests at the event" },
        // General
        location: { type: "string", description: "Work location or venue name" },
        client_name: { type: "string", description: "Client or customer name" },
        project_name: { type: "string", description: "Project or booking name" },
        mileage: { type: "number", description: "Miles driven for work" },
        notes: { type: "string", description: "Additional notes about the shift" },
        // Rideshare & Delivery
        rides_count: { type: "integer", description: "Number of rides or deliveries completed" },
        deliveries_count: { type: "integer", description: "Number of deliveries completed" },
        dead_miles: { type: "number", description: "Miles driven without passenger/delivery" },
        fuel_cost: { type: "number", description: "Fuel expenses for this shift" },
        tolls_parking: { type: "number", description: "Tolls and parking fees" },
        surge_multiplier: { type: "number", description: "Average surge multiplier (e.g., 1.5, 2.0)" },
        acceptance_rate: { type: "number", description: "Acceptance rate percentage" },
        base_fare: { type: "number", description: "Base fare earnings before tips" },
        // Music & Entertainment
        gig_type: { type: "string", description: "Type of gig (Wedding, Corporate, Bar, Street)" },
        setup_hours: { type: "number", description: "Hours spent setting up" },
        performance_hours: { type: "number", description: "Hours of actual performance" },
        breakdown_hours: { type: "number", description: "Hours spent breaking down/tearing down" },
        equipment_used: { type: "string", description: "Equipment used (PA, lights, etc.)" },
        equipment_rental_cost: { type: "number", description: "Cost of equipment rental" },
        crew_payment: { type: "number", description: "Payment to crew/band members" },
        merch_sales: { type: "number", description: "Merchandise/CD sales" },
        audience_size: { type: "integer", description: "Estimated audience size" },
        // Artist & Crafts
        pieces_created: { type: "integer", description: "Number of pieces created" },
        pieces_sold: { type: "integer", description: "Number of pieces sold" },
        materials_cost: { type: "number", description: "Cost of materials used" },
        sale_price: { type: "number", description: "Average sale price per piece" },
        venue_commission_percent: { type: "number", description: "Venue/gallery commission percentage" },
        // Retail/Sales
        items_sold: { type: "integer", description: "Number of items sold" },
        transactions_count: { type: "integer", description: "Number of transactions/customers" },
        upsells_count: { type: "integer", description: "Number of upsells (warranties, credit cards)" },
        upsells_amount: { type: "number", description: "Total upsells amount" },
        returns_count: { type: "integer", description: "Number of returns processed" },
        returns_amount: { type: "number", description: "Total returns amount" },
        shrink_amount: { type: "number", description: "Shrink/loss amount" },
        department: { type: "string", description: "Department worked in" },
        // Salon/Spa
        service_type: { type: "string", description: "Service type (Cut, Color, Massage, etc.)" },
        services_count: { type: "integer", description: "Number of services performed" },
        product_sales: { type: "number", description: "Product sales amount" },
        repeat_client_percent: { type: "number", description: "Percentage of repeat clients" },
        chair_rental: { type: "number", description: "Chair/booth rental cost" },
        new_clients_count: { type: "integer", description: "Number of new clients" },
        returning_clients_count: { type: "integer", description: "Number of returning clients" },
        walkin_count: { type: "integer", description: "Number of walk-in clients" },
        appointment_count: { type: "integer", description: "Number of appointments" },
        // Hospitality
        room_type: { type: "string", description: "Room type (Standard, Suite, Deluxe)" },
        rooms_cleaned: { type: "integer", description: "Number of rooms cleaned" },
        quality_score: { type: "number", description: "Quality score (1-10)" },
        shift_type: { type: "string", description: "Shift type (Day, Night, Swing, Peak)" },
        room_upgrades: { type: "integer", description: "Number of room upgrades sold" },
        guests_checked_in: { type: "integer", description: "Number of guests checked in" },
        cars_parked: { type: "integer", description: "Number of cars parked (valet)" },
        // Healthcare
        patient_count: { type: "integer", description: "Number of patients seen" },
        shift_differential: { type: "number", description: "Night/weekend shift differential bonus" },
        on_call_hours: { type: "number", description: "On-call hours" },
        procedures_count: { type: "integer", description: "Number of procedures performed" },
        specialization: { type: "string", description: "Specialization or department" },
        // Fitness
        sessions_count: { type: "integer", description: "Number of sessions/classes taught" },
        session_type: { type: "string", description: "Session type (1-on-1, Group, Online)" },
        class_size: { type: "integer", description: "Class size / number of students" },
        retention_rate: { type: "number", description: "Client retention rate percentage" },
        cancellations_count: { type: "integer", description: "Number of cancellations/no-shows" },
        package_sales: { type: "number", description: "Package sales amount" },
        supplement_sales: { type: "number", description: "Supplement/product sales" },
        // Construction/Trades
        labor_cost: { type: "number", description: "Labor/crew cost" },
        subcontractor_cost: { type: "number", description: "Subcontractor cost" },
        square_footage: { type: "number", description: "Square footage completed" },
        weather_delay_hours: { type: "number", description: "Weather delay hours" },
        // Freelancer
        revisions_count: { type: "integer", description: "Number of revisions/rounds" },
        client_type: { type: "string", description: "Client type (Startup, SMB, Enterprise)" },
        expenses: { type: "number", description: "Business expenses (software, travel, etc.)" },
        billable_hours: { type: "number", description: "Billable hours (may differ from total hours)" },
        // Restaurant Additional
        table_section: { type: "string", description: "Table section (Bar, Patio, Section A)" },
        cash_sales: { type: "number", description: "Cash sales amount" },
        card_sales: { type: "number", description: "Card sales amount" },
      },
      required: ["job_id", "date"],
    },
  },
  {
    name: "edit_shift",
    description: "Edit an existing shift. First get the shift ID, then update the fields.",
    parameters: {
      type: "object",
      properties: {
        shift_id: { type: "string", description: "UUID of the shift to edit" },
        updates: {
          type: "object",
          description: "Fields to update (same structure as add_shift)",
        },
      },
      required: ["shift_id", "updates"],
    },
  },
  {
    name: "delete_shift",
    description: "Delete a shift. Always confirm before deleting.",
    parameters: {
      type: "object",
      properties: {
        shift_id: { type: "string", description: "UUID of the shift to delete" },
        confirm: { type: "boolean", description: "User has confirmed deletion" },
      },
      required: ["shift_id"],
    },
  },
  {
    name: "get_shifts",
    description: "Get shifts for a date range or specific date. Use for queries like 'how much did I make this week'.",
    parameters: {
      type: "object",
      properties: {
        start_date: { type: "string", description: "Start date YYYY-MM-DD" },
        end_date: { type: "string", description: "End date YYYY-MM-DD" },
        job_id: { type: "string", description: "Filter by specific job" },
        limit: { type: "integer", description: "Max number of shifts to return" },
      },
    },
  },
  // ============================================
  // JOB MANAGEMENT
  // ============================================
  {
    name: "add_job",
    description: "Create a new job. Use when user says 'I started a new job', 'add my bartending job', etc.",
    parameters: {
      type: "object",
      properties: {
        name: { type: "string", description: "Job title (e.g., 'Bartender at Murphy's')" },
        industry: { type: "string", description: "Industry category", enum: ["restaurant", "rideshare", "music", "artist", "retail", "salon", "hospitality", "healthcare", "fitness", "construction", "freelancer", "other"] },
        hourly_rate: { type: "number", description: "Hourly wage rate" },
        color: { type: "string", description: "Hex color code (default: #00D632)" },
        is_default: { type: "boolean", description: "Set as default job" },
      },
      required: ["name"],
    },
  },
  {
    name: "get_jobs",
    description: "Get all user's jobs.",
    parameters: {
      type: "object",
      properties: {
        include_deleted: { type: "boolean", description: "Include soft-deleted jobs" },
      },
    },
  },
  {
    name: "set_default_job",
    description: "Set a job as the default for new shifts.",
    parameters: {
      type: "object",
      properties: {
        job_id: { type: "string", description: "UUID of the job to set as default" },
      },
      required: ["job_id"],
    },
  },
  // ============================================
  // GOAL MANAGEMENT
  // ============================================
  {
    name: "set_goal",
    description: "Create or update an income goal. Use when user says 'set my weekly goal', 'I want to make $X this month'.",
    parameters: {
      type: "object",
      properties: {
        type: { type: "string", description: "Goal type", enum: ["daily", "weekly", "monthly", "yearly"] },
        amount: { type: "number", description: "Target income amount" },
        job_id: { type: "string", description: "Job-specific goal (null = overall)" },
      },
      required: ["type", "amount"],
    },
  },
  {
    name: "get_goals",
    description: "Get all goals with current progress.",
    parameters: {
      type: "object",
      properties: {},
    },
  },
  // ============================================
  // ANALYTICS & QUERIES
  // ============================================
  {
    name: "get_income_summary",
    description: "Get income summary for a period. Use for 'how much did I make', 'what are my earnings'.",
    parameters: {
      type: "object",
      properties: {
        period: { type: "string", description: "Time period", enum: ["today", "week", "month", "year", "all_time"] },
        job_id: { type: "string", description: "Filter by specific job" },
      },
      required: ["period"],
    },
  },
  {
    name: "get_best_days",
    description: "Get the best earning days of the week.",
    parameters: {
      type: "object",
      properties: {
        limit: { type: "integer", description: "Number of days to return (default 5)" },
      },
    },
  },
  {
    name: "get_tax_estimate",
    description: "Get estimated tax liability for the year.",
    parameters: {
      type: "object",
      properties: {},
    },
  },
  // ============================================
  // SETTINGS
  // ============================================
  {
    name: "change_theme",
    description: "Change the app color theme. Use when user says 'change theme', 'make it blue', 'switch to light mode'.",
    parameters: {
      type: "object",
      properties: {
        theme_name: { 
          type: "string", 
          description: "Theme name", 
          enum: ["finance_green", "midnight_blue", "purple_reign", "ocean_breeze", "sunset_glow", "forest_night", "paypal_blue", "finance_pro", "light_mode", "finance_light", "soft_purple"] 
        },
      },
      required: ["theme_name"],
    },
  },
];

// ============================================
// MAIN HANDLER
// ============================================
serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get auth from request
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("No authorization header");
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get user from auth token
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    
    if (authError || !user) {
      throw new Error("Invalid auth token");
    }

    const userId = user.id;

    // Parse request body
    const { message, history } = await req.json();

    // Build context for AI
    const context = await buildUserContext(supabase, userId);

    // Create chat with function calling
    const chat = model.startChat({
      tools: [{ functionDeclarations }],
      toolConfig: { functionCallingConfig: { mode: FunctionCallingMode.AUTO } },
    });

    // Build system prompt
    const systemPrompt = `You are ITB, a friendly AI assistant for a tips and income tracking app called "In The Biz".
You help workers across many industries track their earnings, set goals, and understand their finances.

CURRENT USER CONTEXT:
${context}

IMPORTANT RULES:
1. When the user wants to log a shift, ALWAYS use the add_shift function
2. If they have multiple jobs and don't specify which, ASK which job
3. Parse dates naturally: "today" = today, "yesterday" = yesterday, "the 22nd" = December 22nd (or closest past date)
4. Parse times: "worked 5pm to 11pm" means 6 hours
5. When reporting income, include helpful breakdowns (tips vs hourly, daily averages, etc.)
6. Be encouraging and supportive about their earnings!
7. For themes, match common descriptions: "dark blue" = midnight_blue, "purple" = purple_reign, "light" = light_mode
8. Use emojis appropriately 💰🎉📊

INDUSTRY-SPECIFIC FIELDS:
- Restaurant/Bar: tips, sales, tipout, guest count, event details
- Rideshare/Delivery: rides count, mileage, dead miles, fuel cost, surge multiplier, base fare
- Music/Entertainment: gig type, setup/performance/breakdown hours, equipment, crew payment, merch sales
- Artist/Crafts: pieces created/sold, materials cost, venue commission
- Retail: items sold, transactions, upsells, returns, shrink
- Salon/Spa: service type, services count, product sales, chair rental, new/returning clients
- Hospitality: room type, rooms cleaned, quality score, room upgrades, cars parked
- Healthcare: patient count, shift differential, on-call hours, procedures
- Fitness: sessions, class size, cancellations, package/supplement sales
- Construction: labor cost, subcontractor cost, square footage, weather delays
- Freelancer: billable hours, revisions, client type, expenses`;

    // Send message with system context
    const fullMessage = `${systemPrompt}\n\nUSER: ${message}`;
    const result = await chat.sendMessage(fullMessage);
    
    let functionsExecuted = 0;
    let reply = "";

    // Check for function calls
    const response = result.response;
    const functionCalls = response.functionCalls();
    
    if (functionCalls && functionCalls.length > 0) {
      // Execute each function call
      const functionResults = [];
      
      for (const call of functionCalls) {
        console.log(`[AI Agent] Executing function: ${call.name}`);
        const fnResult = await executeFunction(supabase, userId, call.name, call.args);
        functionResults.push({
          name: call.name,
          response: fnResult,
        });
        functionsExecuted++;
      }

      // Send function results back to AI for natural language response
      const resultMessage = await chat.sendMessage(functionResults.map(r => ({
        functionResponse: {
          name: r.name,
          response: r.response,
        }
      })));

      reply = resultMessage.response.text();
    } else {
      // No function calls, just return text response
      reply = response.text();
    }

    return new Response(
      JSON.stringify({
        success: true,
        reply,
        functionsExecuted,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("[AI Agent] Error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// ============================================
// CONTEXT BUILDER
// ============================================
async function buildUserContext(supabase: any, userId: string): Promise<string> {
  try {
    // Get jobs
    const { data: jobs } = await supabase
      .from("jobs")
      .select("*")
      .eq("user_id", userId)
      .is("deleted_at", null);

    // Get recent shifts
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const { data: recentShifts } = await supabase
      .from("shifts")
      .select("*")
      .eq("user_id", userId)
      .gte("date", thirtyDaysAgo.toISOString().split("T")[0])
      .order("date", { ascending: false })
      .limit(20);

    // Get goals
    const { data: goals } = await supabase
      .from("goals")
      .select("*")
      .eq("user_id", userId)
      .eq("is_active", true);

    // Get settings
    const { data: settings } = await supabase
      .from("user_settings")
      .select("*")
      .eq("user_id", userId)
      .single();

    // Build context string
    let context = `TODAY: ${new Date().toISOString().split("T")[0]}\n`;
    
    // Jobs
    context += `\nJOBS (${jobs?.length || 0}):\n`;
    if (jobs && jobs.length > 0) {
      for (const job of jobs) {
        context += `- ${job.name} (ID: ${job.id}) ${job.is_default ? "[DEFAULT]" : ""} - $${job.hourly_rate || 0}/hr, Industry: ${job.industry || "general"}\n`;
      }
    } else {
      context += "- No jobs created yet\n";
    }

    // Recent earnings
    if (recentShifts && recentShifts.length > 0) {
      const totalEarnings = recentShifts.reduce((sum: number, s: any) => {
        return sum + (s.cash_tips || 0) + (s.credit_tips || 0) + ((s.hourly_rate || 0) * (s.hours_worked || 0)) + (s.flat_rate || 0) + (s.commission || 0);
      }, 0);
      
      context += `\nRECENT EARNINGS (Last 30 days):\n`;
      context += `- Total: $${totalEarnings.toFixed(2)} from ${recentShifts.length} shifts\n`;
      
      // Last 3 shifts
      context += `\nLAST 3 SHIFTS:\n`;
      for (const shift of recentShifts.slice(0, 3)) {
        const income = (shift.cash_tips || 0) + (shift.credit_tips || 0) + ((shift.hourly_rate || 0) * (shift.hours_worked || 0)) + (shift.flat_rate || 0);
        context += `- ${shift.date}: $${income.toFixed(2)}\n`;
      }
    }

    // Goals
    context += `\nGOALS:\n`;
    if (goals && goals.length > 0) {
      for (const goal of goals) {
        context += `- ${goal.type}: $${goal.target_amount}\n`;
      }
    } else {
      context += "- No active goals\n";
    }

    // Theme
    context += `\nCURRENT THEME: ${settings?.theme || "finance_green"}\n`;

    return context;
  } catch (e) {
    console.error("Error building context:", e);
    return "Unable to load user context.";
  }
}

// ============================================
// FUNCTION EXECUTOR
// ============================================
async function executeFunction(supabase: any, userId: string, functionName: string, args: any): Promise<any> {
  console.log(`[Executor] ${functionName} with args:`, JSON.stringify(args));

  switch (functionName) {
    // ============================================
    // SHIFT FUNCTIONS
    // ============================================
    case "add_shift": {
      const shiftData = {
        user_id: userId,
        job_id: args.job_id,
        date: args.date,
        cash_tips: args.cash_tips || 0,
        credit_tips: args.credit_tips || 0,
        hourly_rate: args.hourly_rate || 0,
        hours_worked: args.hours_worked || 0,
        start_time: args.start_time || null,
        end_time: args.end_time || null,
        flat_rate: args.flat_rate || null,
        commission: args.commission || null,
        overtime_hours: args.overtime_hours || null,
        sales_amount: args.sales_amount || null,
        tipout_percent: args.tipout_percent || null,
        additional_tipout: args.additional_tipout || null,
        additional_tipout_note: args.additional_tipout_note || null,
        event_name: args.event_name || null,
        event_cost: args.event_cost || null,
        hostess: args.hostess || null,
        guest_count: args.guest_count || null,
        location: args.location || null,
        client_name: args.client_name || null,
        project_name: args.project_name || null,
        mileage: args.mileage || null,
        notes: args.notes || null,
        // Rideshare & Delivery
        rides_count: args.rides_count || null,
        deliveries_count: args.deliveries_count || null,
        dead_miles: args.dead_miles || null,
        fuel_cost: args.fuel_cost || null,
        tolls_parking: args.tolls_parking || null,
        surge_multiplier: args.surge_multiplier || null,
        acceptance_rate: args.acceptance_rate || null,
        base_fare: args.base_fare || null,
        // Music & Entertainment
        gig_type: args.gig_type || null,
        setup_hours: args.setup_hours || null,
        performance_hours: args.performance_hours || null,
        breakdown_hours: args.breakdown_hours || null,
        equipment_used: args.equipment_used || null,
        equipment_rental_cost: args.equipment_rental_cost || null,
        crew_payment: args.crew_payment || null,
        merch_sales: args.merch_sales || null,
        audience_size: args.audience_size || null,
        // Artist & Crafts
        pieces_created: args.pieces_created || null,
        pieces_sold: args.pieces_sold || null,
        materials_cost: args.materials_cost || null,
        sale_price: args.sale_price || null,
        venue_commission_percent: args.venue_commission_percent || null,
        // Retail/Sales
        items_sold: args.items_sold || null,
        transactions_count: args.transactions_count || null,
        upsells_count: args.upsells_count || null,
        upsells_amount: args.upsells_amount || null,
        returns_count: args.returns_count || null,
        returns_amount: args.returns_amount || null,
        shrink_amount: args.shrink_amount || null,
        department: args.department || null,
        // Salon/Spa
        service_type: args.service_type || null,
        services_count: args.services_count || null,
        product_sales: args.product_sales || null,
        repeat_client_percent: args.repeat_client_percent || null,
        chair_rental: args.chair_rental || null,
        new_clients_count: args.new_clients_count || null,
        returning_clients_count: args.returning_clients_count || null,
        walkin_count: args.walkin_count || null,
        appointment_count: args.appointment_count || null,
        // Hospitality
        room_type: args.room_type || null,
        rooms_cleaned: args.rooms_cleaned || null,
        quality_score: args.quality_score || null,
        shift_type: args.shift_type || null,
        room_upgrades: args.room_upgrades || null,
        guests_checked_in: args.guests_checked_in || null,
        cars_parked: args.cars_parked || null,
        // Healthcare
        patient_count: args.patient_count || null,
        shift_differential: args.shift_differential || null,
        on_call_hours: args.on_call_hours || null,
        procedures_count: args.procedures_count || null,
        specialization: args.specialization || null,
        // Fitness
        sessions_count: args.sessions_count || null,
        session_type: args.session_type || null,
        class_size: args.class_size || null,
        retention_rate: args.retention_rate || null,
        cancellations_count: args.cancellations_count || null,
        package_sales: args.package_sales || null,
        supplement_sales: args.supplement_sales || null,
        // Construction/Trades
        labor_cost: args.labor_cost || null,
        subcontractor_cost: args.subcontractor_cost || null,
        square_footage: args.square_footage || null,
        weather_delay_hours: args.weather_delay_hours || null,
        // Freelancer
        revisions_count: args.revisions_count || null,
        client_type: args.client_type || null,
        expenses: args.expenses || null,
        billable_hours: args.billable_hours || null,
        // Restaurant Additional
        table_section: args.table_section || null,
        cash_sales: args.cash_sales || null,
        card_sales: args.card_sales || null,
      };

      const { data, error } = await supabase
        .from("shifts")
        .insert(shiftData)
        .select()
        .single();

      if (error) throw error;
      
      return {
        success: true,
        message: `Shift created for ${args.date}`,
        shift: data,
      };
    }

    case "edit_shift": {
      const { data, error } = await supabase
        .from("shifts")
        .update(args.updates)
        .eq("id", args.shift_id)
        .eq("user_id", userId)
        .select()
        .single();

      if (error) throw error;
      
      return {
        success: true,
        message: "Shift updated",
        shift: data,
      };
    }

    case "delete_shift": {
      if (!args.confirm) {
        // Get shift details first
        const { data: shift } = await supabase
          .from("shifts")
          .select("*")
          .eq("id", args.shift_id)
          .eq("user_id", userId)
          .single();

        const income = (shift?.cash_tips || 0) + (shift?.credit_tips || 0) + 
                      ((shift?.hourly_rate || 0) * (shift?.hours_worked || 0));

        return {
          success: false,
          requiresConfirmation: true,
          message: `Are you sure you want to delete the shift from ${shift?.date}? This will remove $${income.toFixed(2)} from your records.`,
          shift,
        };
      }

      const { error } = await supabase
        .from("shifts")
        .delete()
        .eq("id", args.shift_id)
        .eq("user_id", userId);

      if (error) throw error;
      
      return {
        success: true,
        message: "Shift deleted",
      };
    }

    case "get_shifts": {
      let query = supabase
        .from("shifts")
        .select("*")
        .eq("user_id", userId)
        .order("date", { ascending: false });

      if (args.start_date) {
        query = query.gte("date", args.start_date);
      }
      if (args.end_date) {
        query = query.lte("date", args.end_date);
      }
      if (args.job_id) {
        query = query.eq("job_id", args.job_id);
      }
      if (args.limit) {
        query = query.limit(args.limit);
      }

      const { data, error } = await query;
      if (error) throw error;
      
      return {
        success: true,
        shifts: data,
        count: data?.length || 0,
      };
    }

    // ============================================
    // JOB FUNCTIONS
    // ============================================
    case "add_job": {
      // Map industry to template
      const industryTemplates: { [key: string]: string } = {
        "restaurant": "restaurant",
        "rideshare": "rideshareDelivery",
        "music": "musicEntertainment",
        "artist": "artistCrafts",
        "retail": "retail",
        "salon": "salonSpa",
        "hospitality": "hospitality",
        "healthcare": "healthcare",
        "fitness": "fitness",
        "construction": "construction",
        "freelancer": "freelancer",
        "other": "restaurant",
      };

      const template = industryTemplates[args.industry || "other"] || "restaurant";

      const { data, error } = await supabase
        .from("jobs")
        .insert({
          user_id: userId,
          name: args.name,
          industry: args.industry || "other",
          hourly_rate: args.hourly_rate || 0,
          color: args.color || "#00D632",
          is_default: args.is_default || false,
          template: template,
        })
        .select()
        .single();

      if (error) throw error;
      
      // If setting as default, unset other defaults
      if (args.is_default) {
        await supabase
          .from("jobs")
          .update({ is_default: false })
          .eq("user_id", userId)
          .neq("id", data.id);
      }
      
      return {
        success: true,
        message: `Job "${args.name}" created!`,
        job: data,
      };
    }

    case "get_jobs": {
      let query = supabase
        .from("jobs")
        .select("*")
        .eq("user_id", userId);

      if (!args.include_deleted) {
        query = query.is("deleted_at", null);
      }

      const { data, error } = await query;
      if (error) throw error;
      
      return {
        success: true,
        jobs: data,
        count: data?.length || 0,
      };
    }

    case "set_default_job": {
      // Unset all defaults first
      await supabase
        .from("jobs")
        .update({ is_default: false })
        .eq("user_id", userId);

      // Set new default
      const { data, error } = await supabase
        .from("jobs")
        .update({ is_default: true })
        .eq("id", args.job_id)
        .eq("user_id", userId)
        .select()
        .single();

      if (error) throw error;
      
      return {
        success: true,
        message: `"${data.name}" is now your default job`,
        job: data,
      };
    }

    // ============================================
    // GOAL FUNCTIONS
    // ============================================
    case "set_goal": {
      // Check if goal of this type exists
      const { data: existing } = await supabase
        .from("goals")
        .select("*")
        .eq("user_id", userId)
        .eq("type", args.type)
        .eq("is_active", true)
        .single();

      if (existing) {
        // Update existing goal
        const { data, error } = await supabase
          .from("goals")
          .update({ target_amount: args.amount })
          .eq("id", existing.id)
          .select()
          .single();

        if (error) throw error;
        
        return {
          success: true,
          message: `${args.type} goal updated to $${args.amount}`,
          goal: data,
        };
      } else {
        // Create new goal
        const { data, error } = await supabase
          .from("goals")
          .insert({
            user_id: userId,
            type: args.type,
            target_amount: args.amount,
            job_id: args.job_id || null,
            is_active: true,
          })
          .select()
          .single();

        if (error) throw error;
        
        return {
          success: true,
          message: `${args.type} goal set to $${args.amount}`,
          goal: data,
        };
      }
    }

    case "get_goals": {
      const { data, error } = await supabase
        .from("goals")
        .select("*")
        .eq("user_id", userId)
        .eq("is_active", true);

      if (error) throw error;
      
      return {
        success: true,
        goals: data,
      };
    }

    // ============================================
    // ANALYTICS FUNCTIONS
    // ============================================
    case "get_income_summary": {
      let startDate: Date;
      const now = new Date();

      switch (args.period) {
        case "today":
          startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
          break;
        case "week":
          const dayOfWeek = now.getDay();
          startDate = new Date(now);
          startDate.setDate(now.getDate() - dayOfWeek);
          break;
        case "month":
          startDate = new Date(now.getFullYear(), now.getMonth(), 1);
          break;
        case "year":
          startDate = new Date(now.getFullYear(), 0, 1);
          break;
        case "all_time":
        default:
          startDate = new Date(2000, 0, 1);
      }

      let query = supabase
        .from("shifts")
        .select("*")
        .eq("user_id", userId)
        .gte("date", startDate.toISOString().split("T")[0]);

      if (args.job_id) {
        query = query.eq("job_id", args.job_id);
      }

      const { data: shifts, error } = await query;
      if (error) throw error;

      // Calculate totals
      let totalIncome = 0;
      let totalTips = 0;
      let totalHours = 0;

      for (const shift of (shifts || [])) {
        const tips = (shift.cash_tips || 0) + (shift.credit_tips || 0);
        const hourly = (shift.hourly_rate || 0) * (shift.hours_worked || 0);
        const flat = shift.flat_rate || 0;
        const comm = shift.commission || 0;
        
        totalTips += tips;
        totalHours += shift.hours_worked || 0;
        totalIncome += tips + hourly + flat + comm;
      }

      return {
        success: true,
        period: args.period,
        totalIncome,
        totalTips,
        totalHours,
        shiftCount: shifts?.length || 0,
        averagePerShift: shifts?.length ? totalIncome / shifts.length : 0,
        averagePerHour: totalHours > 0 ? totalIncome / totalHours : 0,
      };
    }

    case "get_best_days": {
      const { data: shifts, error } = await supabase
        .from("shifts")
        .select("*")
        .eq("user_id", userId);

      if (error) throw error;

      // Group by day of week
      const dayTotals: { [key: number]: number[] } = {};
      const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

      for (const shift of (shifts || [])) {
        const date = new Date(shift.date);
        const dayOfWeek = date.getDay();
        const income = (shift.cash_tips || 0) + (shift.credit_tips || 0) + 
                      ((shift.hourly_rate || 0) * (shift.hours_worked || 0)) +
                      (shift.flat_rate || 0) + (shift.commission || 0);
        
        if (!dayTotals[dayOfWeek]) {
          dayTotals[dayOfWeek] = [];
        }
        dayTotals[dayOfWeek].push(income);
      }

      // Calculate averages
      const dayAverages = Object.entries(dayTotals).map(([day, amounts]) => ({
        day: dayNames[parseInt(day)],
        avgIncome: amounts.reduce((a, b) => a + b, 0) / amounts.length,
        shiftCount: amounts.length,
      }));

      dayAverages.sort((a, b) => b.avgIncome - a.avgIncome);

      return {
        success: true,
        bestDays: dayAverages.slice(0, args.limit || 5),
      };
    }

    case "get_tax_estimate": {
      // Get year's income
      const yearStart = new Date(new Date().getFullYear(), 0, 1);
      const { data: shifts, error } = await supabase
        .from("shifts")
        .select("*")
        .eq("user_id", userId)
        .gte("date", yearStart.toISOString().split("T")[0]);

      if (error) throw error;

      let totalIncome = 0;
      for (const shift of (shifts || [])) {
        totalIncome += (shift.cash_tips || 0) + (shift.credit_tips || 0) + 
                      ((shift.hourly_rate || 0) * (shift.hours_worked || 0)) +
                      (shift.flat_rate || 0) + (shift.commission || 0);
      }

      // Simple tax estimate (simplified for demo)
      const selfEmploymentTax = totalIncome * 0.153; // 15.3% SE tax
      const taxableIncome = totalIncome - (selfEmploymentTax * 0.5); // Half SE tax is deductible
      
      // Simplified federal tax brackets
      let federalTax = 0;
      if (taxableIncome > 11600) {
        federalTax += Math.min(taxableIncome - 11600, 47150 - 11600) * 0.12;
      }
      if (taxableIncome > 47150) {
        federalTax += Math.min(taxableIncome - 47150, 100525 - 47150) * 0.22;
      }

      return {
        success: true,
        totalIncome,
        selfEmploymentTax: selfEmploymentTax.toFixed(2),
        estimatedFederalTax: federalTax.toFixed(2),
        totalEstimatedTax: (selfEmploymentTax + federalTax).toFixed(2),
        effectiveRate: totalIncome > 0 ? (((selfEmploymentTax + federalTax) / totalIncome) * 100).toFixed(1) : 0,
        quarterlyPayment: ((selfEmploymentTax + federalTax) / 4).toFixed(2),
      };
    }

    // ============================================
    // SETTINGS FUNCTIONS
    // ============================================
    case "change_theme": {
      const { error } = await supabase
        .from("user_settings")
        .upsert({
          user_id: userId,
          theme: args.theme_name,
        });

      if (error) throw error;
      
      return {
        success: true,
        message: `Theme changed to "${args.theme_name.replace(/_/g, " ")}"`,
        theme: args.theme_name,
      };
    }

    default:
      return {
        success: false,
        error: `Unknown function: ${functionName}`,
      };
  }
}
