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
    // Parse request
    const { message, history = [] } = await req.json();

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

    // Extract user from JWT token
    const authHeader = req.headers.get("authorization");
    
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Authentication required - no authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
    
    // Initialize Supabase client with service role key (has admin access)
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    
    // Extract user ID from JWT token directly
    const token = authHeader.replace("Bearer ", "");
    
    let userId = null;
    try {
      // Decode JWT to get user ID (Deno uses TextDecoder, not atob)
      const parts = token.split('.');
      if (parts.length !== 3) {
        throw new Error("Invalid JWT format");
      }
      
      // Decode base64url (JWT uses base64url, not standard base64)
      const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      const padded = base64.padEnd(base64.length + (4 - base64.length % 4) % 4, '=');
      const decoded = Uint8Array.from(atob(padded), c => c.charCodeAt(0));
      const payload = JSON.parse(new TextDecoder().decode(decoded));
      
      userId = payload.sub;
      console.log("Extracted user ID from JWT:", userId);
    } catch (e) {
      console.error("Failed to decode JWT:", e);
      return new Response(
        JSON.stringify({ error: "Invalid authentication token" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
    
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "No user ID found in token" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

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
    const currentDate = new Date().toISOString().split("T")[0];
    const currentYear = new Date().getFullYear();
    
    const systemPrompt = `You are "Biz", an intelligent AI assistant for service industry workers who track tips and income.

**TODAY'S DATE:** ${currentDate}
**CURRENT YEAR:** ${currentYear}

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

**CONTACT MANAGEMENT:**
When user mentions vendors, staff, or people they worked with, automatically create contacts:
- "The DJ was Billy" → add_event_contact(name="Billy", role="dj")
- "Wedding planner Sarah, email sarah@weddings.com" → add contact with email
- "Valet guys Jim and Bob from Elite Valet" → add contact with company
- "Photographer's phone was 555-1234" → add contact with phone
Extract ALL details mentioned: names, roles, companies, phone, email, website, social media

**CRITICAL RULES:**

1. **DATES - ALWAYS USE CURRENT YEAR (${currentYear}):**
   - When user says "December 28th" → use ${currentYear}-12-28, NOT any previous year
   - When user says "yesterday", "last week", "the 22nd" → use ${currentYear} unless they explicitly say another year
   - Only use a previous year if user EXPLICITLY says "2024" or "last year"
   - If a date seems ambiguous, ASK the user to confirm before making changes

2. **JOBS - AUTO-SELECT WHEN ONLY ONE EXISTS:**
   - If user has exactly 1 job: ALWAYS use that job's ID for new shifts without asking
   - If user has 2+ jobs: check if job name is mentioned, otherwise ASK which job
   - Never create a shift without a job_id if user has jobs set up

3. **ACTION-THEN-ASK PATTERN:**
   - CREATE the shift/record immediately with the info provided
   - THEN ask follow-up questions for missing optional details
   - Example: "✅ Added $300 shift for today at [JobName]! Did you want to add hours worked, start/end time, or any notes?"

4. **CONFIRMATIONS FOR AMBIGUITY:**
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
