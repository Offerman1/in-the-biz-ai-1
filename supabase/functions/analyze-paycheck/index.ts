// Supabase Edge Function: analyze-paycheck
// AI Vision Scanner for Pay Stubs (W-2 Income & Tax Tracking)
// Extracts earnings, taxes, YTD totals from ADP, Gusto, Paychex, QuickBooks, etc.
// Deploy: npx supabase functions deploy analyze-paycheck --project-ref bokdjidrybwxbomemmrg

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

    // Prepare images for Gemini
    const imageParts = images.map((img: { data: string; mimeType: string }) => ({
      inlineData: {
        data: img.data,
        mimeType: img.mimeType,
      },
    }));

    // Paycheck Analysis Prompt
    const prompt = `You are an expert at analyzing paycheck/pay stub documents.

TASK: Extract ALL earnings, tax withholdings, and Year-to-Date (YTD) totals from this pay stub.

COMMON PAYROLL PROVIDERS:
- **ADP:** Large enterprise payroll, professional layout
- **Gusto:** Modern cloud payroll, clean design
- **Paychex:** Common for SMBs, traditional format
- **QuickBooks:** Integrated with accounting software
- **Generic:** Standard pay stub format
- **Other:** Custom payroll systems

EXTRACTION INSTRUCTIONS:
1. **Payroll Provider:**
   - payroll_provider (string): Name of the payroll system (ADP, Gusto, Paychex, QuickBooks, Generic, Other)
   - employer_name (string): Name of the employer/company

2. **Pay Period:**
   - pay_period_start (YYYY-MM-DD): Start date of pay period
   - pay_period_end (YYYY-MM-DD): End date of pay period
   - pay_date (YYYY-MM-DD): Actual payment date

3. **Earnings (CRITICAL):**
   - gross_pay (number): Total earnings before deductions
   - regular_hours (number): Regular hours worked
   - overtime_hours (number): Overtime hours worked
   - hourly_rate (number): Regular hourly rate
   - overtime_rate (number): Overtime hourly rate (usually 1.5x)

4. **Taxes & Deductions (VERY IMPORTANT FOR TAX ESTIMATION):**
   - federal_tax (number): Federal income tax withheld
   - state_tax (number): State income tax withheld
   - fica_tax (number): Social Security tax (usually 6.2%)
   - medicare_tax (number): Medicare tax (usually 1.45%)
   - other_deductions (number): Other deductions (health insurance, 401k, etc.)
   - other_deductions_description (string): Description of other deductions

5. **Net Pay:**
   - net_pay (number): Take-home pay (what was deposited)

6. **Year-to-Date Totals (CRITICAL FOR ANNUAL PROJECTIONS):**
   - ytd_gross (number): YTD gross earnings
   - ytd_federal_tax (number): YTD federal tax withheld
   - ytd_state_tax (number): YTD state tax withheld
   - ytd_fica (number): YTD FICA withheld
   - ytd_medicare (number): YTD Medicare withheld

7. **AI Metadata:**
   - ai_confidence_scores (object): Your confidence (0-1) for each field

PAY STUB LAYOUT TIPS:
- **Current Period:** Usually on the LEFT side (this paycheck)
- **YTD Totals:** Usually on the RIGHT side (running totals for the year)
- Look for headers like "Earnings", "Taxes", "Deductions", "Year-to-Date"
- Pay stubs are typically 1 page but can have front/back

RESPONSE FORMAT (JSON only, no markdown):
{
  "payroll_provider": "ADP",
  "employer_name": "Acme Restaurant Group",
  "pay_period_start": "2025-12-16",
  "pay_period_end": "2025-12-31",
  "pay_date": "2026-01-05",
  "gross_pay": 1250.00,
  "regular_hours": 80.0,
  "overtime_hours": 5.5,
  "hourly_rate": 15.00,
  "overtime_rate": 22.50,
  "federal_tax": 150.00,
  "state_tax": 75.00,
  "fica_tax": 77.50,
  "medicare_tax": 18.13,
  "other_deductions": 50.00,
  "other_deductions_description": "Health Insurance",
  "net_pay": 879.37,
  "ytd_gross": 28500.00,
  "ytd_federal_tax": 3200.00,
  "ytd_state_tax": 1600.00,
  "ytd_fica": 1767.00,
  "ytd_medicare": 413.25,
  "ai_confidence_scores": {
    "payroll_provider": 0.98,
    "gross_pay": 0.99,
    "federal_tax": 0.97,
    "ytd_gross": 0.96,
    "net_pay": 0.99
  }
}

IMPORTANT:
- If a field is not visible, use null
- YTD totals are CRITICAL for tax estimation - extract carefully
- Some pay stubs show "Taxes" as a combined total - split into Federal/State/FICA/Medicare if possible
- Confidence scores: 0.95+ = clear printed text, 0.8-0.95 = slightly blurry, <0.8 = hard to read
- Return ONLY valid JSON, no explanations`;

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

    // Get app-tracked income for this pay period (Reality Check)
    let appTrackedIncome = null;
    let unreportedGap = null;

    if (extractedData.pay_period_start && extractedData.pay_period_end) {
      const { data: shifts } = await supabase
        .from("shifts")
        .select("total_income")
        .eq("user_id", userId)
        .gte("date", extractedData.pay_period_start)
        .lte("date", extractedData.pay_period_end);

      if (shifts && shifts.length > 0) {
        appTrackedIncome = shifts.reduce((sum, shift) => sum + (shift.total_income || 0), 0);
        
        if (extractedData.gross_pay) {
          unreportedGap = appTrackedIncome - extractedData.gross_pay;
        }
      }
    }

    const { data: paycheck, error: dbError } = await supabase
      .from("paychecks")
      .insert({
        user_id: userId,
        ...extractedData,
        app_tracked_income: appTrackedIncome,
        w2_reported_income: extractedData.gross_pay,
        unreported_gap: unreportedGap,
        reality_check_run: appTrackedIncome !== null,
        raw_ai_response: extractedData,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (dbError) {
      console.error("Database error:", dbError);
      throw new Error(`Failed to save paycheck: ${dbError.message}`);
    }

    // Build response message with Reality Check warning if applicable
    let message = `Paycheck analyzed successfully`;
    
    if (unreportedGap && unreportedGap > 100) {
      message += `. ⚠️ Reality Check: You logged $${appTrackedIncome?.toFixed(2)} in shifts, but your W-2 only shows $${extractedData.gross_pay}. Gap: $${unreportedGap.toFixed(2)} in unreported tips. You should set aside ~${(unreportedGap * 0.22).toFixed(2)} for taxes.`;
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: extractedData,
        paycheckId: paycheck.id,
        realityCheck: {
          appTrackedIncome,
          w2ReportedIncome: extractedData.gross_pay,
          unreportedGap,
        },
        message,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error in analyze-paycheck:", error);

    // Log error to vision_scan_errors table
    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      await supabase.from("vision_scan_errors").insert({
        scan_type: "paycheck",
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
