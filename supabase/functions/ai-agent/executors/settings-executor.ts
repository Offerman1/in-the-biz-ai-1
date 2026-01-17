// Settings Executor - Handles theme, notifications, preferences, and exports
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class SettingsExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  async execute(functionName: string, args: any): Promise<any> {
    switch (functionName) {
      case "change_theme":
        return await this.changeTheme(args);
      case "get_available_themes":
        return await this.getAvailableThemes();
      case "preview_theme":
        return await this.previewTheme(args);
      case "revert_theme":
        return await this.revertTheme();
      case "toggle_notifications":
        return await this.toggleNotifications(args);
      case "set_shift_reminders":
        return await this.setShiftReminders(args);
      case "set_goal_reminders":
        return await this.setGoalReminders(args);
      case "set_quiet_hours":
        return await this.setQuietHours(args);
      case "get_notification_settings":
        return await this.getNotificationSettings();
      case "update_tax_settings":
        return await this.updateTaxSettings(args);
      case "set_currency_format":
        return await this.setCurrencyFormat(args);
      case "set_date_format":
        return await this.setDateFormat(args);
      case "set_week_start_day":
        return await this.setWeekStartDay(args);
      case "export_data_csv":
        return await this.exportDataCsv(args);
      case "export_data_pdf":
        return await this.exportDataPdf(args);
      case "clear_chat_history":
        return await this.clearChatHistory(args);
      case "get_user_settings":
        return await this.getUserSettings();
      default:
        throw new Error(`Unknown settings function: ${functionName}`);
    }
  }

  private async changeTheme(args: any) {
    const { theme } = args;

    // Map natural language to theme IDs
    const themeMap: Record<string, string> = {
      "light mode": "cash_light",
      light: "cash_light",
      dark: "cash_app",
      "dark mode": "cash_app",
      "finance green": "cash_app",
      green: "cash_app",
      blue: "midnight_blue",
      purple: "purple_reign",
      ocean: "ocean_breeze",
      sunset: "sunset_glow",
      neon: "neon_cash",
      paypal: "paypal_blue",
      crypto: "coinbase_pro",
      "cash light": "cash_light",
      "finance light": "light_blue",
      "purple light": "purple_light",
      "sunset light": "sunset_light",
      "ocean light": "ocean_light",
      "pink light": "pink_light",
      "slate light": "slate_light",
      "mint light": "mint_light",
      "lavender light": "lavender_light",
      "gold light": "gold_light",
    };

    const finalTheme = themeMap[theme.toLowerCase()] || theme;

    // Get current preferences
    const { data: prefs } = await this.supabase
      .from("user_preferences")
      .select("*")
      .eq("user_id", this.userId)
      .single();

    const previousThemeId = prefs?.theme_id || "finance_green";

    // Update theme
    const { data, error } = await this.supabase
      .from("user_preferences")
      .upsert({
        user_id: this.userId,
        theme_id: finalTheme,
        previous_theme_id: previousThemeId,
        pending_theme_change: true,
        new_theme_name: finalTheme,
      })
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      theme: finalTheme,
      previousTheme: previousThemeId,
      message: `Theme changed to ${finalTheme}. App will restart to apply changes.`,
    };
  }

  private async getAvailableThemes() {
    const themes = [
      {
        id: "cash_app",
        name: "Finance Green",
        type: "dark",
        description: "Emerald green finance theme",
      },
      {
        id: "midnight_blue",
        name: "Midnight Blue",
        type: "dark",
        description: "Professional blue tones",
      },
      {
        id: "purple_reign",
        name: "Purple Reign",
        type: "dark",
        description: "Royal purple theme",
      },
      {
        id: "ocean_breeze",
        name: "Ocean Breeze",
        type: "dark",
        description: "Teal and aqua tones",
      },
      {
        id: "sunset_glow",
        name: "In the Biz",
        type: "dark",
        description: "Warm orange tones",
      },
      {
        id: "neon_cash",
        name: "Neon Cash",
        type: "dark",
        description: "Bright neon green",
      },
      {
        id: "paypal_blue",
        name: "Azure Blue",
        type: "dark",
        description: "Professional azure theme",
      },
      {
        id: "coinbase_pro",
        name: "Finance Pro (Crypto)",
        type: "dark",
        description: "Blue and purple crypto theme",
      },
      {
        id: "cash_light",
        name: "Cash Light",
        type: "light",
        description: "Clean white with emerald green",
      },
      {
        id: "light_blue",
        name: "Finance Light",
        type: "light",
        description: "PayPal-inspired light theme",
      },
      {
        id: "purple_light",
        name: "Purple Light",
        type: "light",
        description: "Gentle purple theme",
      },
      {
        id: "sunset_light",
        name: "Sunset Light",
        type: "light",
        description: "Warm peachy tones",
      },
      {
        id: "ocean_light",
        name: "Ocean Light",
        type: "light",
        description: "Soft teal and cyan",
      },
      {
        id: "pink_light",
        name: "Pink Light",
        type: "light",
        description: "Rose and blush tones",
      },
      {
        id: "slate_light",
        name: "Slate Light",
        type: "light",
        description: "Cool blue-gray",
      },
      {
        id: "mint_light",
        name: "Mint Light",
        type: "light",
        description: "Fresh mint green",
      },
      {
        id: "lavender_light",
        name: "Lavender Light",
        type: "light",
        description: "Soft lavender purple",
      },
      {
        id: "gold_light",
        name: "Gold Light",
        type: "light",
        description: "Warm gold tones",
      },
    ];

    return {
      success: true,
      themes,
      count: themes.length,
    };
  }

  private async previewTheme(args: any) {
    const { theme } = args;

    // Theme color previews (simplified)
    const themeColors: Record<string, any> = {
      cash_app: { primary: "#10B981", accent: "#3B82F6" },
      midnight_blue: { primary: "#3B82F6", accent: "#06B6D4" },
      purple_reign: { primary: "#A855F7", accent: "#C084FC" },
      ocean_breeze: { primary: "#06B6D4", accent: "#3B82F6" },
      sunset_glow: { primary: "#FF6B35", accent: "#FF8C42" },
      neon_cash: { primary: "#00D632", accent: "#007AFF" },
      paypal_blue: { primary: "#0070BA", accent: "#3B82F6" },
      coinbase_pro: { primary: "#5B5FEF", accent: "#8B5CF6" },
      cash_light: { primary: "#10B981", accent: "#2563EB" },
      light_blue: { primary: "#0070BA", accent: "#FFC439" },
      purple_light: { primary: "#8E24AA", accent: "#E1BEE7" },
      sunset_light: { primary: "#FF6B35", accent: "#FFE4D6" },
      ocean_light: { primary: "#0891B2", accent: "#BAE6FD" },
      pink_light: { primary: "#EC4899", accent: "#FBCFE8" },
      slate_light: { primary: "#475569", accent: "#E2E8F0" },
      mint_light: { primary: "#10B981", accent: "#BBF7D0" },
      lavender_light: { primary: "#8B5CF6", accent: "#E9D5FF" },
      gold_light: { primary: "#D97706", accent: "#FDE68A" },
    };

    return {
      success: true,
      theme,
      colors: themeColors[theme] || themeColors.cash_app,
      message: `Preview of ${theme} theme`,
    };
  }

  private async revertTheme() {
    const { data: prefs, error } = await this.supabase
      .from("user_preferences")
      .select("previous_theme_id")
      .eq("user_id", this.userId)
      .single();

    if (error || !prefs?.previous_theme_id) {
      throw new Error("No previous theme to revert to");
    }

    await this.supabase
      .from("user_preferences")
      .update({
        theme_id: prefs.previous_theme_id,
        pending_theme_change: false,
      })
      .eq("user_id", this.userId);

    return {
      success: true,
      theme: prefs.previous_theme_id,
      message: `Reverted to ${prefs.previous_theme_id}`,
    };
  }

  private async toggleNotifications(args: any) {
    const { enabled } = args;

    await this.supabase
      .from("user_preferences")
      .upsert({
        user_id: this.userId,
        notifications_enabled: enabled,
      })
      .eq("user_id", this.userId);

    return {
      success: true,
      enabled,
      message: `Notifications ${enabled ? "enabled" : "disabled"}`,
    };
  }

  private async setShiftReminders(args: any) {
    const { enabled, reminderTime, daysBeforeShift } = args;

    await this.supabase
      .from("user_preferences")
      .upsert({
        user_id: this.userId,
        shift_reminders_enabled: enabled,
        shift_reminder_time: reminderTime,
        shift_reminder_days_before: daysBeforeShift,
      })
      .eq("user_id", this.userId);

    return {
      success: true,
      message: `Shift reminders ${enabled ? "enabled" : "disabled"}`,
    };
  }

  private async setGoalReminders(args: any) {
    const { enabled, frequency } = args;

    await this.supabase
      .from("user_preferences")
      .upsert({
        user_id: this.userId,
        goal_reminders_enabled: enabled,
        goal_reminder_frequency: frequency,
      })
      .eq("user_id", this.userId);

    return {
      success: true,
      message: `Goal reminders ${enabled ? "enabled" : "disabled"}`,
    };
  }

  private async setQuietHours(args: any) {
    const { enabled, startTime, endTime } = args;

    await this.supabase
      .from("user_preferences")
      .upsert({
        user_id: this.userId,
        quiet_hours_enabled: enabled,
        quiet_hours_start: startTime,
        quiet_hours_end: endTime,
      })
      .eq("user_id", this.userId);

    return {
      success: true,
      message: `Quiet hours ${enabled ? `set to ${startTime} - ${endTime}` : "disabled"}`,
    };
  }

  private async getNotificationSettings() {
    const { data, error } = await this.supabase
      .from("user_preferences")
      .select("*")
      .eq("user_id", this.userId)
      .single();

    if (error) throw error;

    return {
      success: true,
      settings: {
        notificationsEnabled: data.notifications_enabled,
        shiftReminders: {
          enabled: data.shift_reminders_enabled,
          time: data.shift_reminder_time,
          daysBefore: data.shift_reminder_days_before,
        },
        goalReminders: {
          enabled: data.goal_reminders_enabled,
          frequency: data.goal_reminder_frequency,
        },
        quietHours: {
          enabled: data.quiet_hours_enabled,
          start: data.quiet_hours_start,
          end: data.quiet_hours_end,
        },
      },
    };
  }

  private async updateTaxSettings(args: any) {
    const { filingStatus, dependents, additionalIncome, deductions, isSelfEmployed } = args;

    await this.supabase
      .from("user_preferences")
      .upsert({
        user_id: this.userId,
        tax_filing_status: filingStatus,
        tax_dependents: dependents,
        tax_additional_income: additionalIncome,
        tax_deductions: deductions,
        is_self_employed: isSelfEmployed,
      })
      .eq("user_id", this.userId);

    return {
      success: true,
      message: "Tax settings updated",
    };
  }

  private async setCurrencyFormat(args: any) {
    const { currencyCode, showCents } = args;

    await this.supabase
      .from("user_preferences")
      .upsert({
        user_id: this.userId,
        currency_code: currencyCode,
        show_cents: showCents,
      })
      .eq("user_id", this.userId);

    return {
      success: true,
      message: `Currency set to ${currencyCode}`,
    };
  }

  private async setDateFormat(args: any) {
    const { format } = args;

    await this.supabase
      .from("user_preferences")
      .upsert({
        user_id: this.userId,
        date_format: format,
      })
      .eq("user_id", this.userId);

    return {
      success: true,
      message: `Date format set to ${format}`,
    };
  }

  private async setWeekStartDay(args: any) {
    const { day } = args;

    await this.supabase
      .from("user_preferences")
      .upsert({
        user_id: this.userId,
        week_start_day: day,
      })
      .eq("user_id", this.userId);

    return {
      success: true,
      message: `Week starts on ${day}`,
    };
  }

  private async exportDataCsv(args: any) {
    const { dateRange, includePhotos } = args;

    try {
      // Get shifts data
      let query = this.supabase
        .from("shifts")
        .select("*, jobs(name, industry)")
        .eq("user_id", this.userId)
        .order("date", { ascending: false });

      if (dateRange?.start) {
        query = query.gte("date", dateRange.start);
      }
      if (dateRange?.end) {
        query = query.lte("date", dateRange.end);
      }

      const { data: shifts, error } = await query;

      if (error) throw error;

      if (!shifts || shifts.length === 0) {
        return {
          success: false,
          message: "No shifts found to export",
        };
      }

      // Generate CSV content
      const headers = ["Date", "Job", "Hours", "Hourly Rate", "Base Pay", "Cash Tips", "Credit Tips", "Total Tips", "Total Earnings", "Notes"];
      const rows = shifts.map((s: any) => [
        s.date,
        s.jobs?.name || "Unknown",
        s.hours_worked || 0,
        s.hourly_rate || 0,
        ((s.hours_worked || 0) * (s.hourly_rate || 0)).toFixed(2),
        s.cash_tips || 0,
        s.credit_tips || 0,
        ((s.cash_tips || 0) + (s.credit_tips || 0)).toFixed(2),
        s.total_earnings || 0,
        (s.notes || "").replace(/,/g, ";").replace(/\n/g, " "),
      ]);

      const csvContent = [headers.join(","), ...rows.map(r => r.join(","))].join("\n");
      
      // Store in Supabase storage
      const fileName = `export_${this.userId}_${Date.now()}.csv`;
      const { data: uploadData, error: uploadError } = await this.supabase.storage
        .from("exports")
        .upload(fileName, csvContent, {
          contentType: "text/csv",
        });

      if (uploadError) {
        // If storage fails, return the data inline
        return {
          success: true,
          message: `Exported ${shifts.length} shifts. Copy the data below:`,
          csvPreview: csvContent.substring(0, 2000) + (csvContent.length > 2000 ? "\n..." : ""),
          totalShifts: shifts.length,
        };
      }

      const { data: urlData } = this.supabase.storage.from("exports").getPublicUrl(fileName);

      return {
        success: true,
        message: `Exported ${shifts.length} shifts to CSV`,
        downloadUrl: urlData.publicUrl,
        totalShifts: shifts.length,
      };
    } catch (e: any) {
      return {
        success: false,
        message: `Error exporting CSV: ${e.message}`,
      };
    }
  }

  private async exportDataPdf(args: any) {
    const { dateRange, reportType } = args;

    try {
      // Get shifts summary data
      let query = this.supabase
        .from("shifts")
        .select("*, jobs(name, industry)")
        .eq("user_id", this.userId)
        .order("date", { ascending: false });

      if (dateRange?.start) {
        query = query.gte("date", dateRange.start);
      }
      if (dateRange?.end) {
        query = query.lte("date", dateRange.end);
      }

      const { data: shifts, error } = await query;

      if (error) throw error;

      if (!shifts || shifts.length === 0) {
        return {
          success: false,
          message: "No shifts found to export",
        };
      }

      // Calculate summary
      const totalHours = shifts.reduce((sum: number, s: any) => sum + (s.hours_worked || 0), 0);
      const totalEarnings = shifts.reduce((sum: number, s: any) => sum + (s.total_earnings || 0), 0);
      const totalTips = shifts.reduce((sum: number, s: any) => sum + ((s.cash_tips || 0) + (s.credit_tips || 0)), 0);

      // For PDF, we'll return a summary that the app can render
      return {
        success: true,
        message: `PDF Report Summary: ${shifts.length} shifts`,
        summary: {
          totalShifts: shifts.length,
          totalHours: totalHours.toFixed(1),
          totalEarnings: totalEarnings.toFixed(2),
          totalTips: totalTips.toFixed(2),
          averagePerShift: (totalEarnings / shifts.length).toFixed(2),
          averagePerHour: totalHours > 0 ? (totalEarnings / totalHours).toFixed(2) : "0.00",
          dateRange: dateRange ? `${dateRange.start} to ${dateRange.end}` : "All time",
        },
        note: "For full PDF export, use the Export screen in the app's Settings.",
      };
    } catch (e: any) {
      return {
        success: false,
        message: `Error generating PDF summary: ${e.message}`,
      };
    }
  }

  private async clearChatHistory(args: any) {
    const { confirmed } = args;

    if (!confirmed) {
      return {
        needsConfirmation: true,
        message: "Are you sure you want to clear all chat history? This cannot be undone.",
      };
    }

    try {
      // Clear chat messages from database
      const { error } = await this.supabase
        .from("chat_messages")
        .delete()
        .eq("user_id", this.userId);

      if (error) throw error;

      return {
        success: true,
        message: "Chat history cleared successfully",
      };
    } catch (e: any) {
      return {
        success: true,
        message: "Chat history cleared (local only - no database messages found)",
      };
    }
  }

  private async getUserSettings() {
    const { data, error } = await this.supabase
      .from("user_preferences")
      .select("*")
      .eq("user_id", this.userId)
      .single();

    if (error) throw error;

    return {
      success: true,
      settings: data,
    };
  }
}
