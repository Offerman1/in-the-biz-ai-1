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
    const { images, userId, shiftId } = await req.json();

    if (!images || !Array.isArray(images) || images.length === 0) {
      throw new Error("No images provided");
    }

    if (!userId) {
      throw new Error("User ID required");
    }

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

COMMON POS SYSTEMS:
- **Toast:** Modern cloud POS, clean format, usually has "Toast" logo at top
- **Square:** Clean modern design, "Square" branding, simple layout
- **Aloha/Micros:** Legacy system, often dot-matrix font, dense text
- **Clover:** Modern tablet-based, clean interface
- **TouchBistro:** iPad-based, professional layout
- **Lightspeed:** Cloud POS, modern design
- **Handwritten:** Manual calculations on paper

EXTRACTION INSTRUCTIONS:
1. **POS System Detection:**
   - pos_system (string): Name of the POS system (Toast, Square, Aloha, Handwritten, Other)
   - pos_system_confidence (0-1): How confident are you in this identification?

2. **Checkout Identity:**
   - checkout_date (YYYY-MM-DD): Date of this checkout
   - server_name (string): Name of the server/bartender

3. **Financial Data (THE MOST IMPORTANT PART):**
   - total_sales (number): Gross sales before any deductions
   - net_sales (number): Sales after discounts/voids (if shown)
   - gross_tips (number): Total tips before tipout
   - tipout_amount (number): Dollar amount tipped out to support staff
   - tipout_percentage (number): Percentage tipped out (if shown)
   - net_tips (number): Take-home tips (Gross Tips - Tipout)

4. **Context:**
   - table_count (number): Number of tables served
   - cover_count (number): Number of guests/covers

5. **Validation:**
   - math_validated (boolean): Does Net Tips = Gross Tips - Tipout?
   - validation_notes (string): Any discrepancies or notes

6. **AI Metadata:**
   - ai_confidence_scores (object): Your confidence (0-1) for each field

MATH VALIDATION RULES:
- If you see Gross Tips and Tipout, calculate: Net Tips = Gross Tips - Tipout
- Flag any inconsistencies in validation_notes
- POS systems sometimes show percentages (e.g., "Tipout: 3% = $45")

COMMON FIELD LABELS (by POS):
- **Toast:** "Net Sales", "Tip Total", "Tip Out", "Total Tips"
- **Square:** "Total Sales", "Tips", "Tip Share"
- **Aloha:** "Total Sales", "Tips", "Tip Out"
- Receipts can be LONG (3+ feet) - data may span multiple pages

RESPONSE FORMAT (JSON only, no markdown):
{
  "pos_system": "Toast",
  "pos_system_confidence": 0.95,
  "checkout_date": "2026-01-02",
  "server_name": "Sarah Johnson",
  "total_sales": 1850.00,
  "net_sales": 1820.00,
  "gross_tips": 320.00,
  "tipout_amount": 54.60,
  "tipout_percentage": 3.0,
  "net_tips": 265.40,
  "table_count": 12,
  "cover_count": 38,
  "math_validated": true,
  "validation_notes": "All calculations verified. Net Tips = Gross Tips - Tipout (320 - 54.60 = 265.40)",
  "ai_confidence_scores": {
    "pos_system": 0.95,
    "total_sales": 0.98,
    "gross_tips": 0.97,
    "tipout_amount": 0.92,
    "net_tips": 0.95
  }
}

IMPORTANT:
- If a field is not visible, use null
- Be careful with multi-page receipts - totals are usually at the bottom
- For handwritten checkouts, do your best to read handwriting
- Confidence scores: 0.9+ = clear printed text, 0.7-0.9 = dot-matrix or handwriting, <0.7 = very unclear
- Return ONLY valid JSON, no explanations`;

    // Call Gemini Vision API
    const result = await model.generateContent([prompt, ...imageParts]);
    const response = result.response;
    let text = response.text();

    // Remove markdown code blocks if present
    text = text.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    // Parse JSON response
    const extractedData = JSON.parse(text);

    // Perform math validation if we have the data
    if (extractedData.gross_tips && extractedData.tipout_amount) {
      const calculatedNetTips = extractedData.gross_tips - extractedData.tipout_amount;
      const netTipsMatch = extractedData.net_tips 
        ? Math.abs(calculatedNetTips - extractedData.net_tips) < 0.01
        : false;
      
      extractedData.math_validated = netTipsMatch;
      
      if (!netTipsMatch && extractedData.net_tips) {
        extractedData.validation_notes = 
          `Math discrepancy: Gross Tips ($${extractedData.gross_tips}) - Tipout ($${extractedData.tipout_amount}) = $${calculatedNetTips.toFixed(2)}, but receipt shows Net Tips as $${extractedData.net_tips}`;
      }
    }

    // Save to database
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data: checkout, error: dbError } = await supabase
      .from("server_checkouts")
      .insert({
        user_id: userId,
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
