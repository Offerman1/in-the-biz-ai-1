// Context Builder - Builds user context for AI prompt
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class ContextBuilder {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  async buildContext(): Promise<string> {
    const [jobs, recentShifts, goals, preferences] = await Promise.all([
      this.getJobs(),
      this.getRecentShifts(),
      this.getGoals(),
      this.getPreferences(),
    ]);

    let context = "**USER CONTEXT:**\n\n";

    // Jobs section
    context += "**JOBS:**\n";
    if (jobs.length === 0) {
      context += "- No jobs set up yet\n";
    } else if (jobs.length === 1) {
      const job = jobs[0];
      context += `- ONLY ONE JOB: "${job.name}" (ID: ${job.id}) | $${job.hourly_rate}/hr | ${job.industry}\n`;
      context += `  ⚠️ AUTO-USE THIS JOB ID (${job.id}) for ALL new shifts without asking!\n`;
    } else {
      context += `- ${jobs.length} jobs available. Ask user which job if not mentioned.\n`;
      jobs.forEach((job: any) => {
        context += `  • ${job.name} (ID: ${job.id})`;
        if (job.is_default) context += " [DEFAULT]";
        context += ` | $${job.hourly_rate}/hr | ${job.industry}\n`;
      });
    }
    context += "\n";

    // Recent shifts summary
    context += "**RECENT ACTIVITY (Last 7 days):**\n";
    if (recentShifts.length === 0) {
      context += "- No recent shifts\n";
    } else {
      const totalIncome = recentShifts.reduce((sum: number, s: any) => sum + s.total_income, 0);
      const totalHours = recentShifts.reduce((sum: number, s: any) => sum + s.hours_worked, 0);
      context += `- ${recentShifts.length} shifts\n`;
      context += `- Total income: $${totalIncome.toFixed(2)}\n`;
      context += `- Total hours: ${totalHours.toFixed(1)}\n`;
      context += `- Avg per shift: $${(totalIncome / recentShifts.length).toFixed(2)}\n`;
    }
    context += "\n";

    // Goals section
    context += "**ACTIVE GOALS:**\n";
    if (goals.length === 0) {
      context += "- No goals set\n";
    } else {
      for (const goal of goals) {
        const progress = await this.calculateGoalProgress(goal);
        context += `- ${goal.type.toUpperCase()}: $${goal.target_amount} (${progress.percentComplete}% complete, $${progress.remaining} remaining)\n`;
      }
    }
    context += "\n";

    // Preferences
    context += "**PREFERENCES:**\n";
    context += `- Theme: ${preferences.theme_id || "finance_green"}\n`;
    context += `- Notifications: ${preferences.notifications_enabled ? "ON" : "OFF"}\n`;
    context += `- Week starts: ${preferences.week_start_day || "Sunday"}\n`;
    context += "\n";

    return context;
  }

  private async getJobs() {
    const { data } = await this.supabase
      .from("jobs")
      .select("*")
      .eq("user_id", this.userId)
      .eq("is_active", true)
      .is("deleted_at", null)
      .order("is_default", { ascending: false });

    return data || [];
  }

  private async getRecentShifts() {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const { data } = await this.supabase
      .from("shifts")
      .select("*")
      .eq("user_id", this.userId)
      .gte("date", sevenDaysAgo.toISOString().split("T")[0])
      .order("date", { ascending: false });

    return data || [];
  }

  private async getGoals() {
    const { data } = await this.supabase
      .from("goals")
      .select("*")
      .eq("user_id", this.userId)
      .order("type", { ascending: true });

    return data || [];
  }

  private async getPreferences() {
    const { data } = await this.supabase
      .from("user_preferences")
      .select("*")
      .eq("user_id", this.userId)
      .single();

    return data || {};
  }

  private async calculateGoalProgress(goal: any) {
    const now = new Date();
    let startDate: Date;

    switch (goal.type) {
      case "daily":
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        break;
      case "weekly":
        const dayOfWeek = now.getDay();
        startDate = new Date(now.getTime() - dayOfWeek * 24 * 60 * 60 * 1000);
        break;
      case "monthly":
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        break;
      case "yearly":
        startDate = new Date(now.getFullYear(), 0, 1);
        break;
      default:
        startDate = new Date(0);
    }

    let query = this.supabase
      .from("shifts")
      .select("total_income")
      .eq("user_id", this.userId)
      .gte("date", startDate.toISOString().split("T")[0])
      .lte("date", now.toISOString().split("T")[0]);

    if (goal.job_id) {
      query = query.eq("job_id", goal.job_id);
    }

    const { data: shifts } = await query;

    const currentAmount = shifts?.reduce((sum, s) => sum + s.total_income, 0) || 0;
    const percentComplete = Math.round((currentAmount / goal.target_amount) * 100);
    const remaining = Math.max(0, goal.target_amount - currentAmount);

    return {
      currentAmount,
      percentComplete,
      remaining,
    };
  }
}
