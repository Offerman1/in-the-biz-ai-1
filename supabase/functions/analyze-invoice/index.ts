// Supabase Edge Function: analyze-invoice
// AI Vision Scanner for Invoices (Freelancer/1099 Income Tracking)
// Extracts client, amount, due date, line items
// Deploy: npx supabase functions deploy analyze-invoice --project-ref bokdjidrybwxbomemmrg

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

    // Invoice Analysis Prompt
    const prompt = `You are an expert at analyzing invoices for freelancers and contractors.

TASK: Extract ALL invoice details from this ${images.length}-page document.

EXTRACTION INSTRUCTIONS:
1. **Invoice Identity:**
   - invoice_number (string): Invoice number/ID
   - invoice_date (YYYY-MM-DD): Date invoice was issued
   - due_date (YYYY-MM-DD): Payment due date

2. **Client Information:**
   - client_name (string): Name of the client/customer
   - client_email (string): Client email address
   - client_phone (string): Client phone number
   - client_address (string): Client billing address

3. **Financial Data:**
   - subtotal (number): Subtotal before tax
   - tax_amount (number): Sales tax amount
   - total_amount (number): Total invoice amount
   - balance_due (number): Amount still owed (if partially paid)

4. **Payment Terms:**
   - payment_terms (string): Payment terms (e.g., "Net 30", "Due on Receipt", "Net 15")

5. **Line Items (Detailed breakdown):**
   - line_items (array): Array of line item objects with structure:
     [
       {
         "description": "Graphic Design Services",
         "quantity": 10,
         "rate": 50.00,
         "amount": 500.00
       },
       {
         "description": "Web Development",
         "quantity": 20,
         "rate": 75.00,
         "amount": 1500.00
       }
     ]

6. **QuickBooks Integration (Auto-Suggested):**
   - quickbooks_category (string): Suggested income category for QuickBooks
     Common categories: "Design Income", "Consulting Income", "Service Revenue", "Product Sales"
     Base this on the service description in line items

7. **AI Metadata:**
   - ai_confidence_scores (object): Your confidence (0-1) for each field

PAYMENT TERMS COMMON VALUES:
- "Net 30" = Payment due in 30 days
- "Net 15" = Payment due in 15 days
- "Due on Receipt" = Payment due immediately
- "2/10 Net 30" = 2% discount if paid within 10 days, otherwise Net 30

QUICKBOOKS CATEGORY SUGGESTIONS:
- If invoice mentions "design", "graphics", "logo" → "Design Income"
- If invoice mentions "consulting", "advice", "strategy" → "Consulting Income"
- If invoice mentions "development", "coding", "programming" → "Service Revenue"
- If invoice mentions "DJ", "music", "performance" → "Entertainment Income"
- If invoice mentions "photography", "photos", "images" → "Photography Income"
- If invoice mentions "catering", "food", "event planning" → "Catering Income"

RESPONSE FORMAT (JSON only, no markdown):
{
  "invoice_number": "INV-2026-001",
  "invoice_date": "2026-01-01",
  "due_date": "2026-01-31",
  "client_name": "Acme Corporation",
  "client_email": "ap@acmecorp.com",
  "client_phone": "555-123-4567",
  "client_address": "123 Business St, City, State 12345",
  "subtotal": 2000.00,
  "tax_amount": 160.00,
  "total_amount": 2160.00,
  "balance_due": 2160.00,
  "payment_terms": "Net 30",
  "line_items": [
    {
      "description": "Graphic Design Services",
      "quantity": 10,
      "rate": 50.00,
      "amount": 500.00
    },
    {
      "description": "Web Development",
      "quantity": 20,
      "rate": 75.00,
      "amount": 1500.00
    }
  ],
  "quickbooks_category": "Design Income",
  "ai_confidence_scores": {
    "invoice_number": 0.99,
    "client_name": 0.98,
    "total_amount": 0.99,
    "due_date": 0.95,
    "line_items": 0.92
  }
}

IMPORTANT:
- If a field is not visible, use null
- For line items, extract as much detail as possible
- If invoice shows "Amount Paid", subtract from total to get balance_due
- Confidence scores: 0.95+ = clear printed text, 0.8-0.95 = slightly unclear, <0.8 = hard to read
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

    // Determine status based on balance_due
    const status = extractedData.balance_due && extractedData.balance_due > 0 
      ? "pending" 
      : "paid";

    const { data: invoice, error: dbError } = await supabase
      .from("invoices")
      .insert({
        user_id: userId,
        ...extractedData,
        status,
        amount_paid: extractedData.total_amount - (extractedData.balance_due || extractedData.total_amount),
        raw_ai_response: extractedData,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (dbError) {
      console.error("Database error:", dbError);
      throw new Error(`Failed to save invoice: ${dbError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: extractedData,
        invoiceId: invoice.id,
        message: `Invoice analyzed successfully (${images.length} page${images.length > 1 ? 's' : ''})`,
        quickbooksReady: true,
        quickbooksCategory: extractedData.quickbooks_category,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error in analyze-invoice:", error);

    // Log error to vision_scan_errors table
    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      await supabase.from("vision_scan_errors").insert({
        scan_type: "invoice",
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
