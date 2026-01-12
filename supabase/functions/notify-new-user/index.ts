// Supabase Edge Function: notify-new-user
// Sends email notification when a new user signs up
// Deploy: npx supabase functions deploy notify-new-user --no-verify-jwt

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

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
    // Parse the webhook payload from Supabase
    // Webhook sends: { type: "INSERT", table: "profiles", record: {...}, old_record: null }
    const payload = await req.json();
    
    console.log("Received webhook payload:", JSON.stringify(payload, null, 2));

    // Handle different payload formats
    // Database webhooks send: { type, table, record, schema, old_record }
    // Direct calls might send: { user_id } or { record: { id } }
    let userId: string | null = null;
    
    if (payload.record?.id) {
      // Standard webhook format
      userId = payload.record.id;
    } else if (payload.user_id) {
      // Direct call format
      userId = payload.user_id;
    } else if (payload.id) {
      // Simple format
      userId = payload.id;
    }

    if (!userId) {
      console.error("No user ID found in payload");
      return new Response(
        JSON.stringify({ error: "No user ID in payload", payload }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client with service role (to access auth.users)
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Fetch user details from auth.users
    const { data: authUser, error: authError } = await supabase.auth.admin.getUserById(userId);
    
    if (authError || !authUser?.user) {
      console.error("Could not fetch user:", authError);
      return new Response(
        JSON.stringify({ error: "Could not fetch user details", details: authError }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const user = authUser.user;
    
    // Extract user information
    const userEmail = user.email || "No email";
    const userMetadata = user.user_metadata || {};
    const appMetadata = user.app_metadata || {};
    
    // Get user name from various sources
    let userName = "Unknown User";
    if (userMetadata.full_name) {
      userName = userMetadata.full_name;
    } else if (userMetadata.name) {
      userName = userMetadata.name;
    } else if (userEmail !== "No email") {
      userName = userEmail.split("@")[0];
    }

    // Determine sign-in provider
    const provider = appMetadata.provider || user.app_metadata?.providers?.[0] || "email";
    const providers = appMetadata.providers || [provider];
    
    // Get profile data if available (from the webhook payload or database)
    let profileData = payload.record || {};
    if (!profileData.full_name) {
      // Try to fetch from profiles table
      const { data: profile } = await supabase
        .from("profiles")
        .select("*")
        .eq("id", userId)
        .single();
      
      if (profile) {
        profileData = profile;
      }
    }

    // Format timestamps
    const createdAt = user.created_at ? new Date(user.created_at).toLocaleString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZoneName: "short",
    }) : "Unknown";

    const lastSignIn = user.last_sign_in_at ? new Date(user.last_sign_in_at).toLocaleString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZoneName: "short",
    }) : "First signup";

    // Get Zoho SMTP credentials
    const smtpHost = Deno.env.get("ZOHO_SMTP_HOST");
    const smtpPort = Deno.env.get("ZOHO_SMTP_PORT");
    const smtpUser = Deno.env.get("ZOHO_SMTP_USERNAME");
    const smtpPass = Deno.env.get("ZOHO_SMTP_PASSWORD");

    if (!smtpHost || !smtpUser || !smtpPass) {
      console.error("Zoho SMTP credentials not configured");
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: "Email service not configured",
          user: { id: userId, email: userEmail, name: userName }
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build comprehensive email
    const emailHtml = `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #00D632 0%, #00A3FF 100%); padding: 24px; border-radius: 12px 12px 0 0;">
          <h1 style="color: white; margin: 0; font-size: 24px;">🎉 New User Signup!</h1>
        </div>
        
        <div style="background: #1a1a1a; padding: 24px; color: #ffffff;">
          <h2 style="color: #00D632; margin-top: 0;">User Details</h2>
          
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #888;">Name</td>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #fff; font-weight: 600;">${userName}</td>
            </tr>
            <tr>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #888;">Email</td>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #fff;">${userEmail}</td>
            </tr>
            <tr>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #888;">User ID</td>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #fff; font-family: monospace; font-size: 12px;">${userId}</td>
            </tr>
            <tr>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #888;">Sign-in Provider</td>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #fff;">
                ${getProviderBadge(provider)}
              </td>
            </tr>
            <tr>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #888;">All Providers</td>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #fff;">${providers.join(", ")}</td>
            </tr>
            <tr>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #888;">Signed Up</td>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #fff;">${createdAt}</td>
            </tr>
            <tr>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #888;">Email Verified</td>
              <td style="padding: 12px 0; border-bottom: 1px solid #333; color: #fff;">
                ${user.email_confirmed_at ? "✅ Yes" : "❌ No"}
              </td>
            </tr>
          </table>

          ${Object.keys(userMetadata).length > 0 ? `
            <h3 style="color: #00A3FF; margin-top: 24px;">User Metadata</h3>
            <div style="background: #2a2a2a; padding: 16px; border-radius: 8px; font-family: monospace; font-size: 12px; overflow-x: auto;">
              <pre style="margin: 0; white-space: pre-wrap; color: #ccc;">${JSON.stringify(userMetadata, null, 2)}</pre>
            </div>
          ` : ""}

          ${Object.keys(appMetadata).length > 0 ? `
            <h3 style="color: #00A3FF; margin-top: 24px;">App Metadata</h3>
            <div style="background: #2a2a2a; padding: 16px; border-radius: 8px; font-family: monospace; font-size: 12px; overflow-x: auto;">
              <pre style="margin: 0; white-space: pre-wrap; color: #ccc;">${JSON.stringify(appMetadata, null, 2)}</pre>
            </div>
          ` : ""}
        </div>

        <div style="background: #111; padding: 16px; border-radius: 0 0 12px 12px; text-align: center;">
          <p style="color: #666; font-size: 12px; margin: 0;">
            This notification was sent automatically by In The Biz AI
          </p>
        </div>
      </div>
    `;

    // Send email via Zoho SMTP
    const nodemailer = await import("npm:nodemailer@6.9.8");
    
    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: parseInt(smtpPort || "587"),
      secure: smtpPort === "465",
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
    });

    await transporter.sendMail({
      from: `"In The Biz AI" <${smtpUser}>`,
      to: smtpUser, // Send to support@inthebiz.app
      subject: `🎉 New User: ${userName} (${userEmail})`,
      html: emailHtml,
    });

    console.log(`✅ New user notification sent for ${userEmail}`);

    // Optionally log to a table for tracking
    try {
      await supabase.from("signup_notifications").insert({
        user_id: userId,
        user_email: userEmail,
        user_name: userName,
        provider: provider,
        email_sent: true,
        created_at: new Date().toISOString(),
      });
    } catch (e) {
      // Table might not exist - that's OK
      console.log("Could not log to signup_notifications table:", e);
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Notification sent for new user: ${userEmail}`,
        user: { id: userId, email: userEmail, name: userName, provider }
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error: any) {
    console.error("Error processing new user notification:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// Helper function to get a styled provider badge
function getProviderBadge(provider: string): string {
  const badges: Record<string, string> = {
    google: '🔵 Google',
    apple: '⚫ Apple',
    email: '📧 Email/Password',
    phone: '📱 Phone',
    facebook: '🔵 Facebook',
    twitter: '🐦 Twitter/X',
    github: '⚫ GitHub',
    discord: '💜 Discord',
  };
  return badges[provider.toLowerCase()] || `🔗 ${provider}`;
}
