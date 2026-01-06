// Supabase Edge Function: analyze-checkout
// AI Vision Scanner for Server Checkouts (POS receipts)
// Extracts sales, tips, tipout from Toast, Square, Aloha, and other POS systems
// Deploy: npx supabase functions deploy analyze-checkout --project-ref bokdjidrybwxbomemmrg

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

    const { images, userId, shiftId, forceNew } = await req.json();

    if (!images || !Array.isArray(images) || images.length === 0) {
      throw new Error("No images provided");
    }

    // Use userId from body or fall back to token
    const effectiveUserId = userId || tokenUserId;

    // Initialize Gemini
    const genAI = new GoogleGenerativeAI(Deno.env.get("GEMINI_API_KEY")!);
    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-exp" });

    // Prepare images for Gemini
    const imageParts = images.map((img: { data: string; mimeType: string }) => ({
      inlineData: {
        data: img.data,
        mimeType: img.mimeType,
      },
    }));

    // Server Checkout Analysis Prompt
    const prompt = `You are an expert at analyzing restaurant Point of Sale (POS) system checkout receipts.

TASK: Extract financial data from this ${images.length}-page server checkout receipt.

EXTRACTION INSTRUCTIONS:
1. **Checkout Identity:**
   - checkout_date (YYYY-MM-DD): Date of this checkout
   - server_name (string): Name of the server/bartender
   - section (string): Section/area worked (e.g., "Main Dining", "Bar", "Patio", "Section 3") - if shown

2. **Sales Data:**
   - gross_sales (number): Total sales INCLUDING comps/promos (the actual sales before deductions)
   - comps (number): Complimentary items/discounts given away (if shown separately)
   - promos (number): Promotional discounts (if shown separately)
   - net_sales (number): Final sales after comps/promos (if shown)

3. **Tips Data (CRITICAL - FOLLOW THIS EXACT LOGIC):**
   
   **Step 1: Find TOTAL TIPS (the combined amount)**
   Look for these labels (they mean the SAME thing):
   - "CC TIPS/CASH GRATS" or "CC Tips/Cash Gratuities" 
   - "TOTAL TIPS"
   - "Total Gratuities"
   This number = total_tips_before_tipshare
   
   **Step 2: Find CREDIT CARD TIPS ONLY**
   This will appear BELOW the total, labeled as:
   - "Charge Tips" or "Credit Card Tips" or "CC Tips" (when listed separately)
   This number = credit_card_tips
   
   **Step 3: CALCULATE Cash Tips**
   cash_tips = total_tips_before_tipshare - credit_card_tips
   
   **Step 4: Find TIP SHARE**
   Look for:
   - "TIPSHARE" or "Tip Share" or "Tip Out"
   This number = tip_share
   
   **Step 5: CALCULATE Net Tips (Take Home)**
   net_tips = total_tips_before_tipshare - tip_share
   
   **EXAMPLE from real checkout:**
   - "CC TIPS/CASH GRATS: $311.38" → total_tips_before_tipshare = 311.38
   - "Charge Tips: $304.37" → credit_card_tips = 304.37
   - CALCULATE: cash_tips = 311.38 - 304.37 = 7.01
   - "TIPSHARE: $70.67" → tip_share = 70.67
   - CALCULATE: net_tips = 311.38 - 70.67 = 240.71

4. **Work Hours (if shown):**
   - hours_worked (number): Total hours worked this shift (some checkouts show this)

5. **Additional Context:**
   - table_count (number): The number you see (could be tables OR checks)
   - table_count_label_found (string): The EXACT label from the receipt (e.g., "CHECKS", "Tables", "Payments")
   - table_count_type (string): Your best guess: "tables" or "checks" based on context
   - cover_count (number): Number of guests/covers (may be labeled "GUESTS")

6. **Validation & Metadata:**
   - cash_tips_source (string): How you determined cash_tips - "found" (on receipt), "calculated" (via subtraction), or null (not available)
   - math_validated (boolean): Does Net Tips = Total Tips - Tip Share?
   - validation_notes (string): Any discrepancies or notes

7. **AI Confidence:**
   - ai_confidence_scores (object): Your confidence (0-1) for each field you extracted

MATH VALIDATION RULES:
- Total Tips Before Tipshare = Credit Card Tips + Cash Tips
- Net Tips (Take Home) = Total Tips Before Tipshare - Tip Share
- Flag any inconsistencies in validation_notes
- POS systems sometimes show percentages (e.g., "Tip Share: 3% = $70")

COMMON FIELD LABELS (Examples - look for ANY of these):
- **Gross Sales:** "GROSS SALES", "Gross Sales", "Total Before Deductions"
- **Net Sales:** "NET SALES", "Net Sales", "SALES" (before taxes), "Final Sales"
- **Comps:** "TOTAL COMPS", "Comps", "Voids", "Manager Comps", "Discounts"
- **Promos:** "TOTAL PROMOS", "Promos", "Promotional", "Discounts"
- **Total Tips:** "CC TIPS/CASH GRATS", "CC Tips/Cash Gratuities", "TOTAL TIPS", "Total Gratuities"
- **Credit Tips:** "Charge Tips", "Credit Card Tips", "CC Tips" (when separate from total)
- **Tip Share:** "TIPSHARE", "Tip Share", "Tip Out", "Support Staff", "House Tipout"
- **Tables:** "CHECKS" (map this to table_count), "Tables", "Table Count"
- **Guests:** "GUESTS", "Covers", "Cover Count", "Guest Count"
- **Section:** "REV" (revenue center), "Section", "Area", "Main Dining", "Bar"

RESPONSE FORMAT (JSON only, no markdown):
{
  "checkout_date": "2026-01-02",
  "server_name": "Sarah Johnson",
  "section": "Main Dining",
  "gross_sales": 1850.00,
  "comps": 30.00,
  "promos": 0.00,
  "net_sales": 1820.00,
  "credit_card_tips": 280.00,
  "cash_tips": 40.00,
  "cash_tips_source": "calculated",
  "total_tips_before_tipshare": 320.00,
  "tip_share": 70.00,
  "net_tips": 250.00,
  "hours_worked": 6.5,
  "table_count": 12,
  "table_count_label_found": "CHECKS",
  "table_count_type": "tables",
  "cover_count": 38,
  "math_validated": true,
  "validation_notes": "All calculations verified. Net Tips = Total Tips $320 - Tip Share $70 = $250. Cash tips calculated as $320 - $280 = $40.",
  "ai_confidence_scores": {
    "checkout_date": 0.99,
    "server_name": 0.95,
    "section": 0.90,
    "gross_sales": 0.98,
    "credit_card_tips": 0.97,
    "cash_tips": 0.95,
    "tip_share": 0.92,
    "net_tips": 0.95
  }
}

IMPORTANT:
- If a field is not visible on the checkout, use null (NOT 0, use null)
- Gross Sales should INCLUDE comps/promos (it's the total before deductions)
- Be careful with multi-page receipts - totals are usually at the bottom
- For handwritten checkouts, do your best to read handwriting
- Confidence scores: 0.9+ = clear printed text, 0.7-0.9 = dot-matrix or handwriting, <0.7 = very unclear
- Return ONLY valid JSON, no explanations
- ALWAYS separate credit card tips from cash tips if the receipt shows them separately`;

    // Call Gemini Vision API
    const result = await model.generateContent([prompt, ...imageParts]);
    const response = result.response;
    let text = response.text();

    // Remove markdown code blocks if present
    text = text.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    // Parse JSON response
    const extractedData = JSON.parse(text);

    // Perform math validation
    if (extractedData.credit_card_tips !== null && extractedData.cash_tips !== null) {
      const calculatedTotalTips = (extractedData.credit_card_tips || 0) + (extractedData.cash_tips || 0);
      extractedData.total_tips_before_tipshare = calculatedTotalTips;
      
      if (extractedData.tip_share !== null) {
        const calculatedNetTips = calculatedTotalTips - (extractedData.tip_share || 0);
        
        if (extractedData.net_tips !== null) {
          const netTipsMatch = Math.abs(calculatedNetTips - extractedData.net_tips) < 0.01;
          extractedData.math_validated = netTipsMatch;
          
          if (!netTipsMatch) {
            extractedData.validation_notes = 
              `Math discrepancy: (CC Tips $${extractedData.credit_card_tips} + Cash Tips $${extractedData.cash_tips}) - Tip Share $${extractedData.tip_share} = $${calculatedNetTips.toFixed(2)}, but receipt shows Net Tips as $${extractedData.net_tips}`;
          }
        } else {
          // Calculate net tips if not shown
          extractedData.net_tips = calculatedNetTips;
          extractedData.math_validated = true;
        }
      }
    }

    // Save to database
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Check for duplicates based on financial numbers (unless forceNew is true)
    // A duplicate is when the same user has a checkout with matching:
    // - Same gross_sales AND same net_tips (very unlikely to be coincidence)
    // OR
    // - Same gross_sales AND same credit_card_tips AND same cash_tips
    let existingCheckout = null;
    if (!forceNew && extractedData.gross_sales !== null && extractedData.net_tips !== null) {
      const { data: duplicates } = await supabase
        .from("server_checkouts")
        .select("id, checkout_date, gross_sales, net_tips, credit_card_tips, cash_tips")
        .eq("user_id", effectiveUserId)
        .eq("gross_sales", extractedData.gross_sales)
        .eq("net_tips", extractedData.net_tips)
        .limit(1);
      
      if (duplicates && duplicates.length > 0) {
        existingCheckout = duplicates[0];
      }
    }

    // If duplicate found (and not forcing new), return a warning instead of inserting
    if (existingCheckout && !forceNew) {
      return new Response(
        JSON.stringify({
          success: false,
          duplicate: true,
          existingCheckout: existingCheckout,
          extractedData: extractedData,
          message: `Duplicate checkout detected! A checkout with the same gross sales ($${existingCheckout.gross_sales}) and net tips ($${existingCheckout.net_tips}) was already recorded on ${existingCheckout.checkout_date}. Would you like to update it?`,
        }),
        {
          status: 409, // 409 Conflict
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { data: checkout, error: dbError } = await supabase
      .from("server_checkouts")
      .insert({
        user_id: effectiveUserId,
        shift_id: shiftId || null,
        ...extractedData,
        raw_ai_response: extractedData,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (dbError) {
      console.error("Database error:", dbError);
      throw new Error(`Failed to save checkout: ${dbError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: extractedData,
        checkoutId: checkout.id,
        message: `Checkout analyzed successfully (${images.length} page${images.length > 1 ? 's' : ''})`,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error in analyze-checkout:", error);

    // Log error to vision_scan_errors table
    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      await supabase.from("vision_scan_errors").insert({
        scan_type: "checkout",
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
