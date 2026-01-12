// Supabase Edge Function: ai-agent
// Full AI agent with function calling - can perform ALL app actions
// Deploy: npx supabase functions deploy ai-agent --project-ref bokdjidrybwxbomemmrg

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";

// Import function declarations and executors
import { functionDeclarations } from "./function-declarations.ts";
import { ShiftExecutor } from "./executors/shift-executor.ts";
import { JobExecutor } from "./executors/job-executor.ts";
import { GoalExecutor } from "./executors/goal-executor.ts";
import { SettingsExecutor } from "./executors/settings-executor.ts";
import { AnalyticsExecutor } from "./executors/analytics-executor.ts";
import { ContactExecutor } from "./executors/contact-executor.ts";
import { UtilityExecutor } from "./executors/utility-executor.ts";

// Import utilities
import { ContextBuilder } from "./utils/context-builder.ts";
import { DateParser } from "./utils/date-parser.ts";
import { JobDetector } from "./utils/job-detector.ts";
import { Validators } from "./utils/validators.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Parse request - including timezone info from client
    const { message, history = [], timeZoneOffset = 0, timeZoneName = 'UTC', localDate = null, localTime = null } = await req.json();

    if (!message) {
      return new Response(
        JSON.stringify({ error: "No message provided" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get API keys from environment
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!geminiApiKey || !supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Extract user_id from JWT WITHOUT validation
    // (Supabase SDK already validated the token on the client side)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let userId: string;
    try {
      const token = authHeader.replace("Bearer ", "");
      const parts = token.split(".");
      if (parts.length !== 3) {
        throw new Error("Invalid token format");
      }
      
      // Decode without validation
      const payload = JSON.parse(atob(parts[1]));
      userId = payload.sub;
      
      if (!userId) {
        throw new Error("No user ID in token");
      }
    } catch (e) {
      console.error("Token parsing error:", e);
      return new Response(
        JSON.stringify({ error: "Invalid authentication token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Create Supabase client with service key
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Initialize executors
    const shiftExecutor = new ShiftExecutor(supabase, userId);
    const jobExecutor = new JobExecutor(supabase, userId);
    const goalExecutor = new GoalExecutor(supabase, userId);
    const settingsExecutor = new SettingsExecutor(supabase, userId);
    const analyticsExecutor = new AnalyticsExecutor(supabase, userId);
    const contactExecutor = new ContactExecutor(supabase, userId);

    // Initialize utilities
    const contextBuilder = new ContextBuilder(supabase, userId);
    const jobDetector = new JobDetector(supabase, userId);

    // Build user context
    const userContext = await contextBuilder.buildContext();

    // Initialize Gemini 3 Flash Preview with function calling
    const genAI = new GoogleGenerativeAI(geminiApiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-3-flash-preview",
    });

    // Build system prompt
    // Use the client's local date if provided, otherwise calculate from timezone offset
    let currentDate: string;
    let currentYear: number;
    let currentTime: string = localTime || "00:00:00";
    
    if (localDate) {
      // Client sent their local date - use it directly
      currentDate = localDate;
      currentYear = parseInt(localDate.split('-')[0]);
    } else {
      // Fallback: calculate user's local time from timezone offset
      const serverNow = new Date();
      const userLocalTime = new Date(serverNow.getTime() + (timeZoneOffset * 60 * 1000) + (serverNow.getTimezoneOffset() * 60 * 1000));
      currentDate = userLocalTime.toISOString().split("T")[0];
      currentYear = userLocalTime.getFullYear();
    }
    
    // Parse current time to determine time of day context
    const timeParts = currentTime.split(':');
    const currentHour = parseInt(timeParts[0]) || 0;
    const currentMinute = parseInt(timeParts[1]) || 0;
    
    // Format time for display (12-hour format)
    const hour12 = currentHour % 12 || 12;
    const ampm = currentHour >= 12 ? 'PM' : 'AM';
    const formattedTime = `${hour12}:${currentMinute.toString().padStart(2, '0')} ${ampm}`;
    
    // Determine time of day context for shift-aware logic
    let timeOfDayContext: string;
    if (currentHour >= 0 && currentHour < 5) {
      timeOfDayContext = `It's late night/early morning (${formattedTime}). If user says "I just finished my shift" or mentions "today", they likely mean a shift that STARTED yesterday evening and just ended now. The shift date should be YESTERDAY (when it started), not today.`;
    } else if (currentHour >= 5 && currentHour < 12) {
      timeOfDayContext = `It's morning (${formattedTime}). User likely means today's date for any shift references.`;
    } else if (currentHour >= 12 && currentHour < 17) {
      timeOfDayContext = `It's afternoon (${formattedTime}). User likely means today's date for any shift references.`;
    } else if (currentHour >= 17 && currentHour < 21) {
      timeOfDayContext = `It's evening (${formattedTime}). User likely means today's date for any shift references.`;
    } else {
      timeOfDayContext = `It's late evening (${formattedTime}). If user says "I just finished my shift", the shift date should be TODAY (when it started), even if it's close to midnight.`;
    }
    
    console.log(`[AI Agent] User timezone: ${timeZoneName}, offset: ${timeZoneOffset} min, local date: ${currentDate}, time: ${currentTime}`);
    
    // Set the user's local date for the DateParser to use when parsing "today", "yesterday", etc.
    DateParser.setUserLocalDate(currentDate);

    // Initialize utility executor with time info (needs to be after time parsing)
    const utilityExecutor = new UtilityExecutor(supabase, userId, formattedTime, timeZoneName);
    
    const systemPrompt = `You are "Biz", an intelligent AI assistant for service industry workers who track tips and income.

**TODAY'S DATE:** ${currentDate}
**CURRENT TIME:** ${formattedTime} (${timeZoneName})
**CURRENT YEAR:** ${currentYear}

**TIME CONTEXT:** ${timeOfDayContext}

${userContext}

**YOUR CAPABILITIES:**
You can perform actions, not just answer questions. You have access to 60+ functions that let you:
- Add, edit, delete shifts
- Manage jobs (add, edit, delete, set default)
- Add/manage event contacts (DJs, photographers, wedding planners, florists, valets, etc.)
- Set and track goals (daily, weekly, monthly, yearly)
- Change themes and settings
- Query analytics and generate reports
- Manage notifications
- Send feature requests to the development team

**CONTACT MANAGEMENT:**
When user mentions vendors, staff, or people they worked with, automatically create contacts:
- "The DJ was Billy" → add_event_contact(name="Billy", role="dj")
- "Wedding planner Sarah, email sarah@weddings.com" → add contact with email
- "Valet guys Jim and Bob from Elite Valet" → add contact with company
- "Photographer's phone was 555-1234" → add contact with phone
Extract ALL details mentioned: names, roles, companies, phone, email, website, social media

**CRITICAL RULES:**

1. **JOB TEMPLATES - MATCH JOB TYPE TO TEMPLATE:**
   When creating a new job, use the CORRECT template so users see relevant fields:
   - Uber/Lyft/DoorDash/Grubhub → template: "rideshare"
   - Hair salon/barbershop/spa → template: "salon"
   - Hotel/valet/concierge/bellhop → template: "hospitality"
   - Personal trainer/fitness class → template: "fitness"
   - Nurse/EMT/medical assistant → template: "healthcare"
   - Carpenter/electrician/construction → template: "construction"
   - Freelancer/consultant/contractor → template: "freelancer"
   - Retail store/cashier → template: "retail"
   - Restaurant/server/bartender → template: "restaurant"
   - Default for anything else → template: "custom"
   
   Example: "User says: 'Add Uber as a job' → add_job(name='Uber', template='rideshare')"

2. **SHIFT TIMING - SMART DATE & TIME HANDLING:**
   - **Shift date = when the shift STARTED, not when it ended**
   - If user says "I just finished my shift" at 2 AM, and shift started at 6 PM yesterday, the shift date is YESTERDAY
   - Use current time (${formattedTime}) as the END time when user says "I just finished"
   - If user provides a start time, calculate hours worked: (end time - start time)
   - Cross-midnight shifts: If start time is PM and current time is AM, shift started YESTERDAY
   - Check user's scheduled shifts to auto-fill start times when possible
   - Example: User at 11:45 PM says "I just made $200" → shift date is TODAY (shift started earlier today)
   - Example: User at 1:30 AM says "I just finished, started at 6 PM" → shift date is YESTERDAY, hours = 7.5

3. **DATES - ALWAYS USE CURRENT YEAR (${currentYear}):**
   - When user says "December 28th" → use ${currentYear}-12-28, NOT any previous year
   - When user says "yesterday", "last week", "the 22nd" → use ${currentYear} unless they explicitly say another year
   - Only use a previous year if user EXPLICITLY says "2024" or "last year"
   - If a date seems ambiguous, ASK the user to confirm before making changes

4. **JOBS - AUTO-SELECT WHEN ONLY ONE EXISTS:**
   - If user has exactly 1 job: ALWAYS use that job's ID for new shifts without asking
   - If user has 2+ jobs: check if job name is mentioned, otherwise ASK which job
   - Never create a shift without a job_id if user has jobs set up

5. **ACTION-THEN-ASK PATTERN:**
   - CREATE the shift/record immediately with the info provided
   - THEN ask follow-up questions for missing optional details
   - Example: "✅ Added $300 shift for today at [JobName]! Did you want to add hours worked, start/end time, or any notes?"

6. **FEATURE REQUESTS & SUGGESTIONS:**
   - If user asks for something you can't do, offer to send the idea to the dev team
   - Say: "I can't do that yet, but would you like me to send this idea to the development team? They review all suggestions!"
   - If user says yes, call send_feature_request with their idea
   - When user says "I'd like to suggest a feature" or similar, engage them:
     * Ask what they'd like to see: "I'd love to hear your idea! What feature would make the app better for you?"
     * After they explain, give a BRIEF feasibility assessment (1-2 sentences):
       - If simple/common request: "That sounds very doable! I'll send this to the team."
       - If medium complexity: "Interesting idea! That would take some work but could be valuable."
       - If complex/major: "That's an ambitious feature that would require significant development, but it's worth exploring!"
     * Always be encouraging and submit the request
     * Thank them for helping improve the app

7. **SCHEDULING APP INTEGRATION (HotSchedules, 7shifts, When I Work, etc.):**
   If user asks about syncing or connecting their scheduling app (HotSchedules, 7shifts, When I Work, Homebase, Sling, etc.):
   
   **YES, WE SUPPORT THIS!** Here's how to explain it:
   
   "Great news! 🎉 You can absolutely sync your scheduling app with In The Biz! Here's how:
   
   **Step 1:** Open your scheduling app (HotSchedules, 7shifts, etc.) and go to Settings
   **Step 2:** Look for 'Calendar Sync' or 'Export to Calendar' option
   **Step 3:** Enable sync to Google Calendar or Apple/iOS Calendar
   **Step 4:** In The Biz automatically imports shifts from your synced calendar!
   
   Most scheduling apps support syncing to Google or Apple Calendar. Once that's set up, go to Settings → Calendar Sync in our app to pull in your shifts automatically.
   
   **App-specific tips:**
   - **HotSchedules:** Menu → Settings → Calendar Sync → Choose Google or Apple Calendar
   - **7shifts:** Profile → Preferences → Calendar Integration
   - **When I Work:** Settings → Calendar Sync
   - **Homebase:** Settings → Integrations → Calendar
   
   Your shifts will appear on your calendar, and we'll import them for you!"
   
   Never say we CAN'T do this - we absolutely can through calendar sync!

8. **CONFIRMATIONS FOR AMBIGUITY:**
   - If a date could match multiple shifts (e.g., user worked Dec 28 in both 2024 and 2025), ASK which one
   - If editing/deleting, confirm the exact shift details before proceeding

**RESPONSE STYLE:**
- Conversational and supportive
- Confirm actions with specifics: "✅ Added shift for December 28, ${currentYear} at [JobName]! Total: $220."
- Always mention the year in confirmations to avoid confusion
- Ask clarifying questions when needed
- Use emojis sparingly: 💰 💵 📈 🎯

**IMPORTANT:** When calling functions, use dates in YYYY-MM-DD format with the CURRENT YEAR (${currentYear}) by default.`;

    // Convert history for Gemini
    const conversationHistory = history.map((msg: any) => ({
      role: msg.isUser ? "user" : "model",
      parts: [{ text: msg.text }],
    }));

    // Add current message
    conversationHistory.push({
      role: "user",
      parts: [{ text: message }],
    });

    // Call Gemini with function declarations
    const result = await model.generateContent({
      contents: conversationHistory,
      tools: [{ functionDeclarations }],
      generationConfig: {
        maxOutputTokens: 2000,
        temperature: 1.0,
      },
      systemInstruction: systemPrompt,
    });

    const response = result.response;
    const functionCalls = response.functionCalls();
    
    // If AI wants to call functions, execute them THEN let AI respond naturally
    if (functionCalls && functionCalls.length > 0) {
      console.log(`Executing ${functionCalls.length} functions`);
      
      const functionResponses = [];
      
      for (const call of functionCalls) {
        try {
          console.log(`Executing function: ${call.name}`, call.args);

          // Parse dates in args if needed
          if (call.args.date) {
            call.args.date = DateParser.parse(call.args.date);
          }
          if (call.args.sourceDate) {
            call.args.sourceDate = DateParser.parse(call.args.sourceDate);
          }
          if (call.args.targetDate) {
            call.args.targetDate = DateParser.parse(call.args.targetDate);
          }

          // Route to appropriate executor
          let functionResult;

          if (call.name.includes("shift")) {
            functionResult = await shiftExecutor.execute(call.name, call.args);
          } else if (call.name.includes("job")) {
            functionResult = await jobExecutor.execute(call.name, call.args);
          } else if (call.name.includes("goal")) {
            functionResult = await goalExecutor.execute(call.name, call.args);
          } else if (call.name.includes("contact")) {
            functionResult = await contactExecutor.execute(call.name, call.args);
          } else if (
            call.name.includes("feature_request") ||
            call.name.includes("current_time")
          ) {
            functionResult = await utilityExecutor.execute(call.name, call.args);
          } else if (
            call.name.includes("theme") ||
            call.name.includes("notification") ||
            call.name.includes("settings") ||
            call.name.includes("export") ||
            call.name.includes("currency") ||
            call.name.includes("date_format") ||
            call.name.includes("week_start") ||
            call.name.includes("tax") ||
            call.name.includes("chat")
          ) {
            functionResult = await settingsExecutor.execute(call.name, call.args);
          } else if (
            call.name.includes("income") ||
            call.name.includes("compare") ||
            call.name.includes("best") ||
            call.name.includes("worst") ||
            call.name.includes("tax") ||
            call.name.includes("projected") ||
            call.name.includes("year") ||
            call.name.includes("event")
          ) {
            functionResult = await analyticsExecutor.execute(call.name, call.args);
          } else {
            throw new Error(`Unknown function: ${call.name}`);
          }

          functionResponses.push({
            name: call.name,
            response: functionResult,
          });
        } catch (error: any) {
          console.error(`Function ${call.name} error:`, error);
          functionResponses.push({
            name: call.name,
            response: {
              success: false,
              error: error.message || "Function execution failed",
            },
          });
        }
      }

      // Send function results back to AI so it can respond NATURALLY
      conversationHistory.push({
        role: "function",
        parts: functionResponses.map((fr) => ({
          functionResponse: {
            name: fr.name,
            response: fr.response,
          },
        })),
      });

      // Let AI generate a natural, conversational response based on results
      const finalResult = await model.generateContent({
        contents: conversationHistory,
        // Don't include tools here - we just want text, not more function calls
        generationConfig: {
          maxOutputTokens: 1000,
          temperature: 0.7,
        },
        systemInstruction: systemPrompt + `

**RESPONSE GUIDELINES FOR THIS MESSAGE:**
- Be conversational and friendly, not robotic
- Confirm what you did with specific details (date, amounts, job name)
- If user corrected you or pointed out a mistake, apologize briefly and naturally
- Don't ask about information the user already provided in their message
- Keep responses concise but warm
- Use ✅ for success, ⚠️ for partial success, ❌ for failures
- If a function returned "needsConfirmation: true", ask the user to confirm before proceeding
- DO NOT try to call any more functions - just respond with text
- ALWAYS complete your sentences - never leave a response unfinished`,
      });

      let replyText = "";
      try {
        replyText = finalResult.response.text();
        console.log("AI generated response:", replyText);
        console.log("Response length:", replyText?.length);
      } catch (e) {
        console.log("Error getting AI text response:", e);
        replyText = "";
      }
      
      // Check if AI response is too short or looks broken (just punctuation, etc.)
      const isResponseBroken = !replyText || 
        replyText.trim().length < 10 || 
        /^[!?.✅❌⚠️✨\s]+$/.test(replyText.trim());
      
      if (isResponseBroken) {
        console.log("AI response looks broken, using function result message instead");
        // Build fallback from function results
        const results = functionResponses.map(r => {
          if (r.response.needsConfirmation) {
            return r.response.message;
          } else if (r.response.success) {
            return r.response.message || `✅ ${r.name.replace(/_/g, " ")} completed`;
          } else if (r.response.error) {
            return `❌ ${r.name.replace(/_/g, " ")}: ${r.response.error}`;
          } else {
            return `Completed ${r.name.replace(/_/g, " ")}`;
          }
        });
        replyText = results.filter(Boolean).join(" ") || "Action completed. Anything else?";
      }

      // Final safety check - ensure we never return empty
      if (!replyText || replyText.trim() === "") {
        const lastResult = functionResponses[functionResponses.length - 1]?.response;
        if (lastResult?.message) {
          replyText = lastResult.message;
        } else if (lastResult?.success) {
          replyText = `✅ Done! Updated ${lastResult.count || 'your'} shifts successfully.`;
        } else {
          replyText = "Action processed. Anything else?";
        }
      }

      return new Response(
        JSON.stringify({
          success: true,
          reply: replyText,
          functionsExecuted: functionResponses.length,
          debugInfo: {
            functions: functionResponses.map(r => r.name),
          },
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // No function calls - just return AI's text response
    let textResponse = "";
    try {
      textResponse = response.text();
    } catch (e) {
      textResponse = "I'm here to help! Ask me about your shifts, income, goals, or tell me to add/edit data.";
    }
    
    return new Response(
      JSON.stringify({
        success: true,
        reply: textResponse,
        functionsExecuted: 0,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error: any) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ 
        error: error.message || "AI agent failed",
        stack: error.stack,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
