// @deno-types="https://esm.sh/@supabase/supabase-js@2.39.3"
// Utility Executor - Handles feature requests, time queries, and misc utilities
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class UtilityExecutor {
  private currentTime: string;
  private timeZoneName: string;

  constructor(
    private supabase: SupabaseClient, 
    private userId: string,
    currentTime: string = "12:00 PM",
    timeZoneName: string = "Local"
  ) {
    this.currentTime = currentTime;
    this.timeZoneName = timeZoneName;
  }

  async execute(functionName: string, args: any): Promise<any> {
    switch (functionName) {
      case "send_feature_request":
        return await this.sendFeatureRequest(args);
      case "get_current_time":
        return await this.getCurrentTime();
      default:
        throw new Error(`Unknown utility function: ${functionName}`);
    }
  }

  private async getCurrentTime(): Promise<any> {
    return {
      success: true,
      time: this.currentTime,
      timezone: this.timeZoneName,
      message: `The current time is ${this.currentTime} (${this.timeZoneName}).`,
    };
  }

  private async sendFeatureRequest(args: any): Promise<any> {
    const { idea, category = "new_feature" } = args;

    if (!idea || idea.trim().length === 0) {
      return {
        success: false,
        error: "No feature idea provided",
      };
    }

    // Fetch the user's name and email
    let userName = "Unknown User";
    let userEmail = "No email on file";
    
    try {
      // First, try to get name from profiles table
      const { data: profile } = await this.supabase
        .from("profiles")
        .select("full_name")
        .eq("id", this.userId)
        .single();
      
      if (profile?.full_name) {
        userName = profile.full_name;
      }
    } catch (e) {
      console.log("Could not fetch user profile:", e);
    }

    try {
      // Also get the user's email from auth.users (using service role key)
      const { data: authUser } = await this.supabase.auth.admin.getUserById(this.userId);
      
      if (authUser?.user?.email) {
        userEmail = authUser.user.email;
        // If we still don't have a name, try getting it from user metadata
        if (userName === "Unknown User") {
          const metadata = authUser.user.user_metadata;
          if (metadata?.full_name) {
            userName = metadata.full_name;
          } else if (metadata?.name) {
            userName = metadata.name;
          } else {
            // Use email username as last resort
            userName = userEmail.split('@')[0];
          }
        }
      }
    } catch (e) {
      console.log("Could not fetch user email:", e);
    }

    // Get Zoho SMTP credentials from environment
    const smtpHost = Deno.env.get("ZOHO_SMTP_HOST");
    const smtpPort = Deno.env.get("ZOHO_SMTP_PORT");
    const smtpUser = Deno.env.get("ZOHO_SMTP_USERNAME");
    const smtpPass = Deno.env.get("ZOHO_SMTP_PASSWORD");
    
    if (!smtpHost || !smtpUser || !smtpPass) {
      console.error("Zoho SMTP credentials not configured");
      // Still log the request to the database even if email fails
      await this.logFeatureRequest(idea, category, false, "Email service not configured");
      return {
        success: true,
        message: "Your feature request has been logged! The team will review it. (Note: Email notification pending setup)",
      };
    }

    try {
      // Format the email
      const categoryLabels: Record<string, string> = {
        new_feature: "🆕 New Feature",
        improvement: "✨ Improvement",
        bug_report: "🐛 Bug Report",
        integration: "🔗 Integration Request",
        other: "💬 Other",
      };

      const emailHtml = `
        <h2>${categoryLabels[category] || category}</h2>
        <p><strong>User Name:</strong> ${userName}</p>
        <p><strong>User Email:</strong> ${userEmail}</p>
        <p><strong>User ID:</strong> ${this.userId}</p>
        <p><strong>Submitted:</strong> ${new Date().toISOString()}</p>
        <hr>
        <h3>Feature Request:</h3>
        <p style="font-size: 16px; line-height: 1.6; background: #f5f5f5; padding: 16px; border-radius: 8px;">
          ${idea}
        </p>
        <hr>
        <p style="color: #666; font-size: 12px;">
          This request was submitted via the In The Biz AI assistant.
        </p>
      `;

      // Send email via Zoho SMTP using nodemailer
      const nodemailer = await import("npm:nodemailer@6.9.8");
      
      const transporter = nodemailer.createTransport({
        host: smtpHost,
        port: parseInt(smtpPort || "587"),
        secure: smtpPort === "465", // true for 465, false for other ports
        auth: {
          user: smtpUser,
          pass: smtpPass,
        },
      });

      await transporter.sendMail({
        from: `"In The Biz AI" <${smtpUser}>`,
        to: smtpUser, // Send to support@inthebiz.app
        subject: `[Feature Request] ${categoryLabels[category] || category} - ${idea.substring(0, 50)}...`,
        html: emailHtml,
      });

      // Log successful submission
      await this.logFeatureRequest(idea, category, true);

      return {
        success: true,
        message: "✅ Your feature request has been sent to the development team! They review all suggestions and may reach out if they have questions. Thank you for helping make In The Biz better!",
      };
    } catch (error: any) {
      console.error("Feature request error:", error);
      // Log to database anyway
      await this.logFeatureRequest(idea, category, false, error.message);
      return {
        success: true,
        message: "Your feature request has been logged! The team will review it.",
      };
    }
  }

  private async logFeatureRequest(
    idea: string, 
    category: string, 
    emailSent: boolean,
    errorMessage?: string
  ): Promise<void> {
    try {
      await this.supabase.from("feature_requests").insert({
        user_id: this.userId,
        idea: idea,
        category: category,
        email_sent: emailSent,
        error_message: errorMessage || null,
        created_at: new Date().toISOString(),
      });
    } catch (e) {
      // Table might not exist yet - that's OK
      console.log("Could not log feature request to database:", e);
    }
  }
}
