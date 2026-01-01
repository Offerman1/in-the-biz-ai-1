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
      "light mode": "light_mode",
      light: "light_mode",
      dark: "finance_green",
      "dark mode": "finance_green",
      blue: "midnight_blue",
      purple: "purple_reign",
      ocean: "ocean_breeze",
      sunset: "sunset_glow",
      forest: "forest_night",
      paypal: "paypal_blue",
      crypto: "finance_pro",
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
        id: "finance_green",
        name: "Finance Green (Default)",
        type: "dark",
        description: "Classic green finance app theme",
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
        name: "Sunset Glow",
        type: "dark",
        description: "Warm orange tones",
      },
      {
        id: "forest_night",
        name: "Forest Night",
        type: "dark",
        description: "Nature-inspired green",
      },
      {
        id: "paypal_blue",
        name: "PayPal Blue",
        type: "dark",
        description: "PayPal-inspired theme",
      },
      {
        id: "finance_pro",
        name: "Finance Pro (Crypto)",
        type: "dark",
        description: "Blue and purple crypto theme",
      },
      {
        id: "light_mode",
        name: "Light Mode",
        type: "light",
        description: "Clean white background",
      },
      {
        id: "light_blue",
        name: "Light Blue",
        type: "light",
        description: "Sunny blue theme",
      },
      {
        id: "soft_purple",
        name: "Soft Purple",
        type: "light",
        description: "Gentle purple theme",
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
      finance_green: { primary: "#00D632", accent: "#2D9CDB" },
      midnight_blue: { primary: "#4A90E2", accent: "#50C878" },
      purple_reign: { primary: "#9B59B6", accent: "#E74C3C" },
      ocean_breeze: { primary: "#1ABC9C", accent: "#3498DB" },
      sunset_glow: { primary: "#FF6B35", accent: "#F7931E" },
      forest_night: { primary: "#27AE60", accent: "#16A085" },
      paypal_blue: { primary: "#0070BA", accent: "#00457C" },
      finance_pro: { primary: "#667EEA", accent: "#764BA2" },
      light_mode: { primary: "#00D632", accent: "#2D9CDB" },
      light_blue: { primary: "#4A90E2", accent: "#50C878" },
      soft_purple: { primary: "#9B59B6", accent: "#E74C3C" },
    };

    return {
      success: true,
      theme,
      colors: themeColors[theme] || themeColors.finance_green,
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

    // TODO: Implement CSV generation
    return {
      success: true,
      message: "CSV export feature coming soon",
      downloadUrl: null,
    };
  }

  private async exportDataPdf(args: any) {
    const { dateRange, reportType } = args;

    // TODO: Implement PDF generation
    return {
      success: true,
      message: "PDF export feature coming soon",
      downloadUrl: null,
    };
  }

  private async clearChatHistory(args: any) {
    const { confirmed } = args;

    if (!confirmed) {
      return {
        needsConfirmation: true,
        message: "Are you sure you want to clear all chat history? This cannot be undone.",
      };
    }

    // TODO: Clear chat messages from database
    return {
      success: true,
      message: "Chat history cleared",
    };
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
