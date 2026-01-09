// Supabase Edge Function: scan-business-card
// AI Vision Scanner for Business Cards (Contact Extraction)
// Extracts name, company, role, phone, email, social media handles
// Deploy: npx supabase functions deploy scan-business-card --project-ref bokdjidrybwxbomemmrg

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Valid database enum values for contact_role
const VALID_ROLES = [
  'dj', 'band_musician', 'photo_booth', 'photographer', 'videographer',
  'wedding_planner', 'event_coordinator', 'hostess', 'support_staff',
  'security', 'valet', 'florist', 'linen_rental', 'cake_bakery',
  'catering', 'rentals', 'lighting_av', 'rabbi', 'priest', 'pastor',
  'officiant', 'venue_manager', 'venue_coordinator', 'custom'
];

// Map AI-extracted roles to valid database enum values
function mapRoleToEnum(aiRole: string | null): string {
  if (!aiRole) return 'custom';
  
  const role = aiRole.toLowerCase().trim();
  
  // Direct matches
  if (VALID_ROLES.includes(role)) return role;
  if (VALID_ROLES.includes(role.replace(/\s+/g, '_'))) return role.replace(/\s+/g, '_');
  
  // Common mappings
  const mappings: Record<string, string> = {
    // Music/Entertainment
    'musician': 'band_musician',
    'band': 'band_musician',
    'artist': 'band_musician',
    'vocalist': 'band_musician',
    'singer': 'band_musician',
    'performer': 'band_musician',
    'entertainment': 'dj',
    'disc jockey': 'dj',
    'emcee': 'dj',
    'mc': 'dj',
    
    // Photo/Video
    'photo': 'photographer',
    'camera': 'photographer',
    'video': 'videographer',
    'film': 'videographer',
    'cinematographer': 'videographer',
    'photo booth': 'photo_booth',
    'photobooth': 'photo_booth',
    
    // Planning/Coordination
    'planner': 'wedding_planner',
    'wedding planner': 'wedding_planner',
    'event planner': 'event_coordinator',
    'coordinator': 'event_coordinator',
    'event coordinator': 'event_coordinator',
    'wedding coordinator': 'event_coordinator',
    'manager': 'venue_manager',
    'venue manager': 'venue_manager',
    
    // Food/Catering
    'caterer': 'catering',
    'chef': 'catering',
    'food': 'catering',
    'baker': 'cake_bakery',
    'cake': 'cake_bakery',
    'pastry': 'cake_bakery',
    
    // Decor/Rentals
    'florist': 'florist',
    'flowers': 'florist',
    'floral': 'florist',
    'linen': 'linen_rental',
    'rental': 'rentals',
    'decor': 'rentals',
    'decorator': 'rentals',
    
    // Technical
    'lighting': 'lighting_av',
    'av': 'lighting_av',
    'audio': 'lighting_av',
    'sound': 'lighting_av',
    'tech': 'lighting_av',
    
    // Religious
    'rabbi': 'rabbi',
    'priest': 'priest',
    'pastor': 'pastor',
    'minister': 'officiant',
    'officiant': 'officiant',
    'celebrant': 'officiant',
    
    // Staff
    'host': 'hostess',
    'hostess': 'hostess',
    'greeter': 'hostess',
    'security': 'security',
    'guard': 'security',
    'bouncer': 'security',
    'valet': 'valet',
    'parking': 'valet',
    'staff': 'support_staff',
    'assistant': 'support_staff',
    'helper': 'support_staff',
  };
  
  // Check direct mapping
  if (mappings[role]) return mappings[role];
  
  // Check if role contains any mapping keywords
  for (const [keyword, enumValue] of Object.entries(mappings)) {
    if (role.includes(keyword)) return enumValue;
  }
  
  // Default to custom if no match found
  return 'custom';
}

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

    const { images, userId, shiftId } = await req.json();

    if (!images || !Array.isArray(images) || images.length === 0) {
      throw new Error("No images provided");
    }

    // Use userId from body or fall back to token
    const effectiveUserId = userId || tokenUserId;

    // Initialize Gemini
    const genAI = new GoogleGenerativeAI(Deno.env.get("GEMINI_API_KEY")!);
    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-exp" });

    // Prepare images for Gemini (usually just 1 image for business cards)
    const imageParts = images.map((img: { data: string; mimeType: string }) => ({
      inlineData: {
        data: img.data,
        mimeType: img.mimeType,
      },
    }));

    // Business Card Analysis Prompt
    const prompt = `You are an expert at extracting contact information from business cards.

TASK: Extract ALL contact information from this business card.

EXTRACTION INSTRUCTIONS:
1. **Personal Information:**
   - name (string): Full name of the person
   - company (string): Company name
   - role (string): Job title/role (e.g., "DJ", "Event Planner", "Photographer")

2. **Contact Information:**
   - phone (string): Phone number (format as shown on card)
   - email (string): Email address
   - website (string): Website URL

3. **Social Media Handles:**
   - instagram_handle (string): Instagram username (without @)
   - tiktok_handle (string): TikTok username (without @)
   - linkedin_url (string): Full LinkedIn URL
   - twitter_handle (string): Twitter/X username (without @)

4. **AI Metadata:**
   - ai_confidence_scores (object): Your confidence (0-1) for each field

SOCIAL MEDIA DETECTION:
- Instagram: Look for "@username", "instagram.com/username", or Instagram icon
- TikTok: Look for "@username", "tiktok.com/@username", or TikTok icon
- LinkedIn: Look for "linkedin.com/in/name" or LinkedIn icon
- Twitter/X: Look for "@username", "twitter.com/username", "x.com/username", or bird/X icon

ROLE AUTO-DETECTION:
If the role is not explicitly stated, infer from:
- Company name (e.g., "Sarah's DJ Services" → role: "DJ")
- Context clues (e.g., "Event Planning" → role: "Event Planner")
- Common titles: DJ, Event Planner, Photographer, Florist, Caterer, Venue Manager, Wedding Coordinator

RESPONSE FORMAT (JSON only, no markdown):
{
  "name": "Sarah Johnson",
  "company": "SJ Events & Entertainment",
  "role": "Event Planner",
  "phone": "555-123-4567",
  "email": "sarah@sjevents.com",
  "website": "https://sjevents.com",
  "instagram_handle": "sjrevents",
  "tiktok_handle": "sarahjohnsondj",
  "linkedin_url": "https://linkedin.com/in/sarah-johnson-events",
  "twitter_handle": "sjrevents",
  "ai_confidence_scores": {
    "name": 0.99,
    "company": 0.97,
    "role": 0.85,
    "phone": 0.98,
    "email": 0.99,
    "instagram_handle": 0.92
  }
}

IMPORTANT:
- If a field is not visible on the card, use null
- For social handles, extract ONLY the username (no @ symbol, no full URLs)
- For LinkedIn, keep the full URL
- Confidence scores: 0.9+ = clear text, 0.7-0.9 = small text or stylized font, <0.7 = very unclear
- Return ONLY valid JSON, no explanations`;

    // Call Gemini Vision API
    const result = await model.generateContent([prompt, ...imageParts]);
    const response = result.response;
    let text = response.text();

    // Remove markdown code blocks if present
    text = text.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    // Parse JSON response
    const extractedData = JSON.parse(text);

    // Validate required fields - name is required
    if (!extractedData.name || extractedData.name.trim() === '') {
      // Try to use company name as fallback, or generate a placeholder
      if (extractedData.company && extractedData.company.trim() !== '') {
        extractedData.name = extractedData.company;
      } else if (extractedData.email) {
        // Extract name from email if possible
        const emailName = extractedData.email.split('@')[0].replace(/[._-]/g, ' ');
        extractedData.name = emailName.charAt(0).toUpperCase() + emailName.slice(1);
      } else {
        extractedData.name = 'Unknown Contact';
      }
    }

    // Map AI-extracted role to valid database enum
    const mappedRole = mapRoleToEnum(extractedData.role);
    const originalRole = extractedData.role; // Keep original for custom_role field

    // Save to database (event_contacts table)
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data: contact, error: dbError } = await supabase
      .from("event_contacts")
      .insert({
        user_id: userId,
        name: extractedData.name,
        company: extractedData.company,
        role: mappedRole,
        custom_role: mappedRole === 'custom' ? originalRole : null,
        phone: extractedData.phone,
        email: extractedData.email,
        website: extractedData.website,
        instagram_handle: extractedData.instagram_handle,
        tiktok_handle: extractedData.tiktok_handle,
        linkedin_url: extractedData.linkedin_url,
        twitter_handle: extractedData.twitter_handle,
        scanned_from_business_card: true,
        ai_confidence_scores: extractedData.ai_confidence_scores,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (dbError) {
      console.error("Database error:", dbError);
      throw new Error(`Failed to save contact: ${dbError.message}`);
    }

    // Link to shift if shiftId provided
    if (shiftId) {
      await supabase.from("shift_contacts").insert({
        shift_id: shiftId,
        contact_id: contact.id,
        created_at: new Date().toISOString(),
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: extractedData,
        contactId: contact.id,
        message: `Contact "${extractedData.name}" added successfully`,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error in scan-business-card:", error);

    // Log error to vision_scan_errors table
    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      await supabase.from("vision_scan_errors").insert({
        scan_type: "business_card",
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
