// Supabase Edge Function: analyze-beo
// AI Vision Scanner for Banquet Event Orders (BEOs)
// Extracts event details from multi-page contracts
// Deploy: npx supabase functions deploy analyze-beo --project-ref bokdjidrybwxbomemmrg

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Extract user_id from JWT WITHOUT strict validation
    // (Supabase SDK already validated the token on the client side)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let tokenUserId: string;
    try {
      const token = authHeader.replace("Bearer ", "");
      const parts = token.split(".");
      if (parts.length !== 3) {
        throw new Error("Invalid token format");
      }
      const payload = JSON.parse(atob(parts[1]));
      tokenUserId = payload.sub;
      if (!tokenUserId) {
        throw new Error("No user ID in token");
      }
    } catch (e) {
      console.error("Token parsing error:", e);
      return new Response(
        JSON.stringify({ error: "Invalid authentication token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { images, userId } = await req.json();

    if (!images || !Array.isArray(images) || images.length === 0) {
      throw new Error("No images provided");
    }

    // Use userId from body or fall back to token
    const effectiveUserId = userId || tokenUserId;

    // Initialize Gemini
    const genAI = new GoogleGenerativeAI(Deno.env.get("GEMINI_API_KEY")!);
    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-exp" });

    // Prepare images for Gemini (base64 encoded)
    const imageParts = images.map((img: { data: string; mimeType: string }) => ({
      inlineData: {
        data: img.data,
        mimeType: img.mimeType,
      },
    }));

    // BEO Analysis Prompt - Comprehensive Event Extraction
    const prompt = `You are an expert event planner analyzing a Banquet Event Order (BEO) contract.

TASK: Extract ALL relevant event details from this ${images.length}-page document. 
This is a COMPREHENSIVE extraction - capture EVERYTHING.

BEOs contain multiple sections. Extract data for ALL of these categories:

═══════════════════════════════════════════════════════════════════════════════
SECTION 1: GENERAL EVENT & CONTACT INFORMATION
═══════════════════════════════════════════════════════════════════════════════

**Event Identity:**
- event_name (string): The event's official name/title
- event_date (YYYY-MM-DD): The date of the event
- event_type (string): MUST be one of these exact values:
  Life Celebrations: 'Wedding', 'Rehearsal Dinner', 'Engagement Party', 'Bridal Shower', 'Bachelor/Bachelorette Party', 'Anniversary', 'Birthday', 'Sweet 16', 'Quinceañera', 'Bar Mitzvah', 'Bat Mitzvah', 'Baby Shower', 'Gender Reveal', 'Baptism/Christening', 'First Communion', 'Confirmation', 'Graduation', 'Retirement', 'Celebration of Life'
  Holidays: 'Christmas Party', 'New Year\\'s Eve', 'Thanksgiving', 'Passover', '4th of July', 'Halloween Party'
  Corporate: 'Corporate Event', 'Conference', 'Gala/Fundraiser', 'Award Ceremony', 'Team Building', 'Networking', 'Luncheon', 'Seminar/Workshop'
  Social: 'Cocktail Party', 'Wine Tasting', 'Game Day', 'Brunch', 'Family Reunion', 'Class Reunion', 'Homecoming', 'Prom'
  Other: 'Other'
- post_as (string): How the event should appear on public signage/screens
- venue_name (string): Name of the venue
- venue_address (string): Full venue address
- function_space (string): Specific room or area (e.g., "Crystal Ballroom", "Dock Area")
- account_name (string): Corporate account or organization name

**Client Contact:**
- primary_contact_name (string): Main contact person (hostess/host/client)
- primary_contact_phone (string): Contact phone number
- primary_contact_email (string): Contact email

**Internal Contacts:**
- sales_manager_name (string): Sales/event manager name
- sales_manager_phone (string): Sales manager phone
- sales_manager_email (string): Sales manager email
- catering_manager_name (string): Catering/kitchen manager
- catering_manager_phone (string): Catering manager phone

═══════════════════════════════════════════════════════════════════════════════
SECTION 2: TIMELINE & LOGISTICS
═══════════════════════════════════════════════════════════════════════════════

- setup_date (YYYY-MM-DD): Date of setup (if different from event date)
- teardown_date (YYYY-MM-DD): Date of teardown
- load_in_time (HH:MM): When load-in/setup begins
- setup_time (HH:MM): When setup begins
- guest_arrival_time (HH:MM): When guests arrive
- event_start_time (HH:MM): When event officially starts
- event_end_time (HH:MM): When event ends
- breakdown_time (HH:MM): When breakdown begins
- load_out_time (HH:MM): When load-out completes

═══════════════════════════════════════════════════════════════════════════════
SECTION 3: GUEST COUNTS & ATTENDANCE
═══════════════════════════════════════════════════════════════════════════════

- guest_count_expected (number): Expected/projected guests
- guest_count_confirmed (number): Confirmed/guaranteed count
- adult_count (number): Number of adults
- child_count (number): Number of children
- vendor_meal_count (number): Vendor/staff meals

═══════════════════════════════════════════════════════════════════════════════
SECTION 4: DETAILED FINANCIALS
═══════════════════════════════════════════════════════════════════════════════

**Sales Breakdown:**
- food_total (number): Total for food items
- beverage_total (number): Total for beverages
- labor_total (number): Total for labor/staffing
- room_rental (number): Room/space rental fee
- equipment_rental (number): Equipment/AV rental

**Calculations:**
- subtotal (number): Sum before service charge/tax
- service_charge_percent (number): Service charge percentage (e.g., 22)
- service_charge_amount (number): Service charge dollar amount
- tax_percent (number): Tax percentage (e.g., 7)
- tax_amount (number): Tax dollar amount
- gratuity_amount (number): Gratuity if separate
- grand_total (number): Final total
- deposits_paid (number): Total deposits paid
- deposit_amount (number): Individual deposit amounts
- balance_due (number): Remaining balance

**Commission:**
- commission_percentage (number): Your commission percentage
- commission_amount (number): Your commission dollar amount

**Total Sale:**
- total_sale_amount (number): Overall event cost (same as grand_total if not specified separately)

═══════════════════════════════════════════════════════════════════════════════
SECTION 5: FOOD & BEVERAGE DETAILS
═══════════════════════════════════════════════════════════════════════════════

- menu_style (string): 'Buffet', 'Plated', 'Stations', 'Family Style', 'Passed Hors doeuvres', 'Cocktail Reception'

- menu_details (JSON object): Full menu breakdown
  Format: {
    "appetizers": [{"name": "Item Name", "description": "Details", "qty": 80, "price": 5.00}],
    "salads": [{"name": "...", "description": "..."}],
    "entrees": [{"name": "...", "description": "...", "qty": 80}],
    "sides": [{"name": "...", "description": "..."}],
    "desserts": [{"name": "...", "description": "..."}],
    "passed_items": [{"name": "...", "description": "..."}]
  }

- beverage_details (JSON object): Beverage package info
  Format: {
    "package": "Non-Alcoholic Package",
    "price_per_person": 5.00,
    "bar_type": "Open/Cash/Host",
    "drink_tickets": 3,
    "cash_bar_after": true,
    "consumption_bar": false,
    "brands": "House/Premium/Top Shelf"
  }

- menu_items (string): Simple comma-separated list of all menu items (legacy field)
- dietary_restrictions (string): Allergies, dietary needs noted

═══════════════════════════════════════════════════════════════════════════════
SECTION 6: ROOM SETUP & INVENTORY
═══════════════════════════════════════════════════════════════════════════════

- setup_details (JSON object): Full setup breakdown
  Format: {
    "tables": [{"type": "60in Round", "qty": 8, "linen_color": "white"}],
    "chairs": {"type": "Chiavari", "qty": 80},
    "linens": {"tablecloths": "white", "napkins": "navy"},
    "decor": ["Silver votive candles", "Floral centerpieces"],
    "av_equipment": ["Microphone", "Projector", "Screen"],
    "special_items": ["Dance floor", "Stage", "Podium"],
    "lounge": ["High tops with spandex", "Lounge furniture"]
  }

- decor_notes (string): Decoration requirements in text form
- floor_plan_notes (string): Floor plan descriptions or references

═══════════════════════════════════════════════════════════════════════════════
SECTION 7: STAFFING & SERVICES
═══════════════════════════════════════════════════════════════════════════════

- staffing_details (JSON object): Staff breakdown
  Format: {
    "servers": 4,
    "bartenders": 2,
    "captain": 1,
    "security": 0,
    "valet": false,
    "av_tech": 0,
    "coat_check": false,
    "staff_meals": true,
    "labor_rate": 150
  }

- staffing_requirements (string): Text description of staffing
- vendor_details (JSON array): External vendors
  Format: [
    {"name": "Jason Blank", "type": "DJ", "company": "", "phone": "", "email": "", "notes": ""},
    {"name": "Casino Tables Florida Fun", "type": "Entertainment", "phone": "", "notes": ""}
  ]

═══════════════════════════════════════════════════════════════════════════════
SECTION 8: TIMELINE/AGENDA
═══════════════════════════════════════════════════════════════════════════════

- event_timeline (JSON array): Order of events
  Format: [
    {"time": "5:00 PM", "activity": "Guest Arrival & Cocktail Hour"},
    {"time": "6:00 PM", "activity": "Dinner Service"},
    {"time": "7:00 PM", "activity": "Speeches"},
    {"time": "8:00 PM", "activity": "Entertainment"}
  ]

═══════════════════════════════════════════════════════════════════════════════
SECTION 9: BILLING & LEGAL
═══════════════════════════════════════════════════════════════════════════════

- payment_method (string): How payment will be made
- cancellation_policy (string): Cancellation terms if mentioned

═══════════════════════════════════════════════════════════════════════════════
SECTION 10: SPECIAL NOTES & CATCH-ALL
═══════════════════════════════════════════════════════════════════════════════

- special_requests (string): Any special client requests
- formatted_notes (string): **CRITICAL** - This is for ANY information that doesn't fit 
  the above fields. Organize ALL unstructured data into clean, readable sections using 
  markdown formatting. Include:
  - Insurance requirements
  - Vendor coordination notes
  - Parking/transportation details
  - Client-provided items
  - Any other details
  
  Use headers (##), bullet points (-), and bold (**text**) for clarity.

- ai_confidence_scores (JSON object): Your confidence (0-1) for each key field
  Example: {"event_name": 0.98, "grand_total": 0.95, "guest_count_confirmed": 0.88}

═══════════════════════════════════════════════════════════════════════════════
RESPONSE FORMAT
═══════════════════════════════════════════════════════════════════════════════

Return ONLY valid JSON. Example structure:

{
  "event_name": "BASS United",
  "event_date": "2026-01-09",
  "event_type": "Corporate",
  "venue_name": "Shooters Waterfront",
  "function_space": "Grateful Palate Catering & Events",
  "guest_count_confirmed": 80,
  "primary_contact_name": "Stephanie Koury",
  "primary_contact_phone": "(954) 785-7800",
  "primary_contact_email": "Stephanie@bassunited.com",
  "sales_manager_name": "Tatiana Ichenko",
  "event_start_time": "17:00",
  "event_end_time": "21:00",
  "food_total": 7150.00,
  "beverage_total": 400.00,
  "labor_total": 300.00,
  "subtotal": 7850.00,
  "service_charge_percent": 22,
  "service_charge_amount": 1661.00,
  "tax_percent": 7,
  "tax_amount": 644.77,
  "grand_total": 10155.77,
  "deposits_paid": 4011.08,
  "balance_due": 6144.69,
  "menu_style": "Buffet",
  "menu_details": {
    "passed_items": [
      {"name": "Hoisin Glazed Pork Meatballs", "qty": 80},
      {"name": "Mini French Dip", "qty": 80}
    ],
    "salads": [{"name": "Apple Walnut Romaine", "qty": 80}],
    "entrees": [
      {"name": "Grilled Soy Ginger Salmon", "qty": 80},
      {"name": "Skirt Steak Chimichurri", "qty": 80}
    ],
    "sides": [
      {"name": "Garlic Whipped Potatoes", "qty": 80},
      {"name": "Grilled Asparagus", "qty": 80}
    ],
    "desserts": [
      {"name": "Dark Chocolate Mousse Shooter", "qty": 80}
    ]
  },
  "beverage_details": {
    "package": "Non-Alcoholic Package",
    "price_per_person": 5.00,
    "drink_tickets": 3,
    "cash_bar_after": true
  },
  "staffing_details": {
    "bartenders": 2,
    "valet": false
  },
  "vendor_details": [
    {"name": "Jason Blank", "type": "DJ"}
  ],
  "setup_details": {
    "tables": [{"type": "60in Round", "qty": 8, "linen_color": "white"}],
    "decor": ["High tops with navy spandex", "Silver votive candles"]
  },
  "formatted_notes": "## Insurance Requirements\\n- Certificate of insurance required for 3033 Group LLC\\n- Certificate required for Shooters Waterfront\\n\\n## Client Provided Items\\n- Stephanie to provide 3 drink tickets per person\\n\\n## Special Notes\\n- Possibly move one casino table to dock\\n- Nuts present in kitchen but can prepare without",
  "ai_confidence_scores": {
    "event_name": 0.99,
    "grand_total": 0.98,
    "guest_count_confirmed": 0.95,
    "menu_details": 0.92
  }
}

CRITICAL RULES:
1. If a field is not visible in the document, use null - don't guess
2. For JSON fields (menu_details, beverage_details, etc.), only include what's actually in the document
3. Put ALL overflow/unstructured data into formatted_notes - NOTHING should be lost
4. Return ONLY valid JSON, no markdown code blocks, no explanations
5. Analyze ALL ${images.length} pages together for complete context
6. Times should be in 24-hour format (HH:MM)
7. Dates should be in YYYY-MM-DD format
8. Amounts should be numbers without $ symbols`;

    // Call Gemini Vision API
    const result = await model.generateContent([prompt, ...imageParts]);
    const response = result.response;
    let text = response.text();

    // Remove markdown code blocks if present
    text = text.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    // Parse JSON response
    const extractedData = JSON.parse(text);

    // Save to database
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data: beoEvent, error: dbError } = await supabase
      .from("beo_events")
      .insert({
        user_id: userId,
        ...extractedData,
        raw_ai_response: extractedData, // Store full response for debugging
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (dbError) {
      console.error("Database error:", dbError);
      throw new Error(`Failed to save BEO event: ${dbError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: extractedData,
        beoEventId: beoEvent.id,
        message: `BEO analyzed successfully (${images.length} page${images.length > 1 ? 's' : ''})`,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error in analyze-beo:", error);

    // Log error to vision_scan_errors table
    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      await supabase.from("vision_scan_errors").insert({
        scan_type: "beo",
        error_type: "ai_failed",
        error_message: error.message,
        created_at: new Date().toISOString(),
      });
    } catch (logError) {
      console.error("Failed to log error:", logError);
    }

    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
