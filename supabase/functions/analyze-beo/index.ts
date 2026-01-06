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

    // BEO Analysis Prompt
    const prompt = `You are an expert event planner analyzing a Banquet Event Order (BEO) contract.

TASK: Extract ALL relevant event details from this ${images.length}-page document.

BEOs can be multi-page and contain:
- Event identity (name, date, type)
- Logistics (setup time, event start/end, breakdown)
- People (guest count, primary contact)
- Financials (total sale, deposit, balance, commission)
- Details (menu, decor, staffing requirements)

EXTRACTION INSTRUCTIONS:
1. **Event Identity:**
   - event_name (string): The event's official name
   - event_date (YYYY-MM-DD): The date of the event
   - event_type (string): 'Wedding', 'Corporate', 'Birthday', 'Other'
   - venue_name (string): Name of the venue
   - venue_address (string): Full venue address

2. **Logistics:**
   - setup_time (HH:MM): When setup begins
   - event_start_time (HH:MM): When the event officially starts
   - event_end_time (HH:MM): When the event officially ends
   - breakdown_time (HH:MM): When breakdown begins

3. **People:**
   - guest_count_expected (number): Expected number of guests
   - guest_count_confirmed (number): Confirmed/final guest count
   - primary_contact_name (string): Main contact person
   - primary_contact_phone (string): Contact phone number
   - primary_contact_email (string): Contact email

4. **Financials:**
   - total_sale_amount (number): Total cost of the event
   - deposit_amount (number): Deposit paid
   - balance_due (number): Remaining balance
   - commission_percentage (number): Commission percentage (if mentioned)
   - commission_amount (number): Commission dollar amount

5. **Additional Details:**
   - menu_items (string): Food and beverage menu
   - decor_notes (string): Decoration requirements
   - staffing_requirements (string): Number of servers, bartenders, etc.
   - special_requests (string): Any special client requests

6. **AI Metadata:**
   - formatted_notes (string): Organize unstructured data (menu, decor, staffing) into clean, readable sections with markdown formatting. Use headers, bullet points, and bold text for clarity.
   - ai_confidence_scores (object): Your confidence (0-1) for each extracted field

RESPONSE FORMAT (JSON only, no markdown):
{
  "event_name": "Smith Wedding",
  "event_date": "2026-06-15",
  "event_type": "Wedding",
  "venue_name": "Grand Ballroom",
  "venue_address": "123 Main St, City, State",
  "setup_time": "14:00",
  "event_start_time": "18:00",
  "event_end_time": "23:00",
  "breakdown_time": "00:00",
  "guest_count_expected": 150,
  "guest_count_confirmed": 142,
  "primary_contact_name": "John Smith",
  "primary_contact_phone": "555-1234",
  "primary_contact_email": "john@example.com",
  "total_sale_amount": 12500.00,
  "deposit_amount": 5000.00,
  "balance_due": 7500.00,
  "commission_percentage": 15.0,
  "commission_amount": 1875.00,
  "menu_items": "Appetizers: Bruschetta, Shrimp Cocktail\\nEntrees: Chicken Marsala, Grilled Salmon\\nDessert: Wedding Cake",
  "decor_notes": "White linens, gold chargers, centerpieces with roses",
  "staffing_requirements": "3 bartenders, 8 servers, 1 captain",
  "special_requests": "Gluten-free options, vegan dessert",
  "formatted_notes": "## Menu\\n- **Appetizers:** Bruschetta, Shrimp Cocktail\\n- **Entrees:** Chicken Marsala, Grilled Salmon\\n- **Dessert:** Wedding Cake\\n\\n## Decor\\nWhite linens, gold chargers, centerpieces with roses\\n\\n## Staffing\\n- 3 Bartenders\\n- 8 Servers\\n- 1 Captain\\n\\n## Special Requests\\nGluten-free options, vegan dessert",
  "ai_confidence_scores": {
    "event_name": 0.98,
    "event_date": 0.95,
    "total_sale_amount": 0.92,
    "guest_count_confirmed": 0.85,
    "menu_items": 0.90
  }
}

IMPORTANT:
- If a field is not visible in the document, use null
- For confidence scores, be honest: 0.9+ = clear text, 0.7-0.9 = partially visible, <0.7 = guessing
- Return ONLY valid JSON, no explanations
- Analyze ALL pages together for complete context`;

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
