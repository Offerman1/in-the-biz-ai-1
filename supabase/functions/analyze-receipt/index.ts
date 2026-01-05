// Supabase Edge Function: analyze-receipt
// AI Vision Scanner for Receipts (Expense Tracking for 1099 Contractors)
// Extracts vendor, amount, date, expense category for tax deductions
// Deploy: npx supabase functions deploy analyze-receipt --project-ref bokdjidrybwxbomemmrg

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

    // Receipt Analysis Prompt
    const prompt = `You are an expert at analyzing receipts for expense tracking and tax deductions.

TASK: Extract ALL expense details from this receipt image.

EXTRACTION INSTRUCTIONS:

1. **Receipt Identity:**
   - vendor_name (string): Store/business name
   - receipt_number (string): Receipt/transaction number if visible
   - receipt_date (YYYY-MM-DD): Date of purchase
   - receipt_time (HH:MM): Time of purchase if visible

2. **Financial Data:**
   - subtotal (number): Subtotal before tax
   - tax_amount (number): Sales tax amount
   - tip_amount (number): Tip if applicable (restaurants)
   - total_amount (number): Total amount paid
   - currency (string): Currency code (USD, EUR, GBP, etc.) - detect from symbols

3. **Payment Method:**
   - payment_method (string): Cash, Credit Card, Debit Card, Check, Venmo, PayPal, etc.
   - card_last_four (string): Last 4 digits if visible (e.g., "Visa ****1234" → "1234")

4. **Line Items (Detailed breakdown):**
   - line_items (array): Array of items purchased
     [
       {
         "description": "Item name",
         "quantity": 1,
         "unit_price": 10.00,
         "amount": 10.00
       }
     ]

5. **Expense Categorization (CRITICAL FOR TAX DEDUCTIONS):**
   - expense_category (string): One of these IRS Schedule C categories:
     * "Materials" - Raw materials, supplies for products
     * "Equipment" - Tools, machinery, equipment purchases
     * "Travel" - Gas, parking, tolls, airfare, hotels
     * "Meals" - Restaurant meals (50% deductible for business)
     * "Supplies" - Office supplies, cleaning supplies
     * "Marketing" - Advertising, printing, promotional items
     * "Utilities" - Phone, internet, electricity for business
     * "Insurance" - Business insurance premiums
     * "Professional Services" - Legal, accounting, consulting
     * "Software" - Software subscriptions, apps
     * "Vehicle" - Car repairs, maintenance, parts
     * "Office" - Office rent, furniture, equipment
     * "Other" - Miscellaneous business expenses

6. **Tax Deductibility Analysis:**
   - is_tax_deductible (boolean): Is this likely a business expense?
   - deduction_percentage (number): What percentage is deductible?
     * Meals = 50%
     * Vehicle (if mixed use) = percentage of business use
     * Most business expenses = 100%
   - deduction_notes (string): Any notes about deductibility

7. **QuickBooks Integration:**
   - quickbooks_category (string): Suggested QuickBooks expense account
     Common mappings:
     * Materials → "Cost of Goods Sold"
     * Equipment → "Equipment Rental/Purchase"
     * Travel → "Travel Expenses"
     * Meals → "Meals and Entertainment"
     * Supplies → "Office Supplies"
     * Marketing → "Advertising"
     * Vehicle → "Car and Truck Expenses"

8. **AI Metadata:**
   - ai_confidence_scores (object): Confidence (0-1) for each extracted field
   - extraction_notes (string): Any issues or uncertainties

COMMON RECEIPT FORMATS:
- **Retail stores:** Walmart, Target, Home Depot, Lowes - clear line items
- **Restaurants:** Itemized food, tax, tip line
- **Gas stations:** Gallons, price per gallon, total
- **Online orders:** Order number, shipping address visible
- **Handwritten:** May need extra parsing

CURRENCY DETECTION:
- $ → USD (default for US receipts)
- € → EUR
- £ → GBP
- ¥ → JPY or CNY (context dependent)
- ₹ → INR
- Look for explicit "USD", "EUR" etc. on receipt

RESPONSE FORMAT (JSON only, no markdown):
{
  "vendor_name": "Home Depot",
  "receipt_number": "1234-5678-9012",
  "receipt_date": "2026-01-05",
  "receipt_time": "14:30",
  "subtotal": 89.97,
  "tax_amount": 7.20,
  "tip_amount": null,
  "total_amount": 97.17,
  "currency": "USD",
  "payment_method": "Credit Card",
  "card_last_four": "1234",
  "line_items": [
    {"description": "2x4 Lumber 8ft (10 pack)", "quantity": 1, "unit_price": 45.00, "amount": 45.00},
    {"description": "Wood Screws #8 x 2in", "quantity": 2, "unit_price": 12.99, "amount": 25.98},
    {"description": "Paint - Interior White 1gal", "quantity": 1, "unit_price": 18.99, "amount": 18.99}
  ],
  "expense_category": "Materials",
  "is_tax_deductible": true,
  "deduction_percentage": 100,
  "deduction_notes": "Construction materials for client project",
  "quickbooks_category": "Cost of Goods Sold - Materials",
  "ai_confidence_scores": {
    "vendor_name": 0.98,
    "total_amount": 0.99,
    "expense_category": 0.85,
    "line_items": 0.92
  },
  "extraction_notes": "Clear receipt, all fields visible"
}

IMPORTANT:
- Return ONLY valid JSON, no markdown code blocks
- Use null for fields that cannot be extracted
- Always provide expense_category - default to "Other" if uncertain
- Flag low confidence extractions in ai_confidence_scores`;

    // Call Gemini API
    const result = await model.generateContent([prompt, ...imageParts]);
    const response = await result.response;
    let text = response.text();

    // Clean up response (remove markdown if present)
    text = text.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    // Parse JSON
    let extractedData;
    try {
      extractedData = JSON.parse(text);
    } catch (parseError) {
      console.error("Failed to parse AI response:", text);
      throw new Error("AI response was not valid JSON");
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Store receipt in database
    const receiptData = {
      user_id: userId,
      shift_id: shiftId || null,
      receipt_date: extractedData.receipt_date,
      vendor_name: extractedData.vendor_name || "Unknown Vendor",
      receipt_number: extractedData.receipt_number,
      subtotal: extractedData.subtotal,
      tax_amount: extractedData.tax_amount,
      total_amount: extractedData.total_amount || 0,
      currency: extractedData.currency || "USD",
      payment_method: extractedData.payment_method,
      expense_category: extractedData.expense_category || "Other",
      quickbooks_category: extractedData.quickbooks_category,
      is_tax_deductible: extractedData.is_tax_deductible ?? true,
      line_items: extractedData.line_items,
      ai_confidence_scores: extractedData.ai_confidence_scores,
      raw_ai_response: extractedData,
    };

    const { data: savedReceipt, error: insertError } = await supabase
      .from("receipts")
      .insert(receiptData)
      .select()
      .single();

    if (insertError) {
      console.error("Database insert error:", insertError);
      // Still return the extracted data even if save fails
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: extractedData,
        receipt_id: savedReceipt?.id || null,
        deduction_summary: {
          category: extractedData.expense_category,
          amount: extractedData.total_amount,
          deductible_percentage: extractedData.deduction_percentage || 100,
          deductible_amount:
            (extractedData.total_amount || 0) *
            ((extractedData.deduction_percentage || 100) / 100),
        },
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Receipt analysis error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
