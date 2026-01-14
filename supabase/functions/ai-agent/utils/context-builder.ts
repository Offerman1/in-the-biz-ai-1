// Context Builder - Builds user context for AI prompt
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class ContextBuilder {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  async buildContext(): Promise<string> {
    const [jobs, recentShifts, goals, preferences, beoEvents, checkouts, paychecks, receipts, invoices] = await Promise.all([
      this.getJobs(),
      this.getRecentShifts(),
      this.getGoals(),
      this.getPreferences(),
      this.getBEOEvents(),
      this.getServerCheckouts(),
      this.getPaychecks(),
      this.getReceipts(),
      this.getInvoices(),
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

    // BEO Events
    context += "**BEO EVENTS:**\n";
    if (beoEvents.total === 0) {
      context += "- No BEO events yet\n";
    } else {
      context += `- ${beoEvents.total} total events (${beoEvents.upcoming} upcoming, ${beoEvents.past} completed)\n`;
      if (beoEvents.upcoming > 0 && beoEvents.nextEvent) {
        const nextDate = new Date(beoEvents.nextEvent.event_date).toLocaleDateString();
        context += `- Next event: "${beoEvents.nextEvent.event_name}" on ${nextDate}\n`;
        if (beoEvents.nextEvent.venue_name) {
          context += `  at ${beoEvents.nextEvent.venue_name}\n`;
        }
        if (beoEvents.nextEvent.guest_count_expected) {
          context += `  (${beoEvents.nextEvent.guest_count_expected} guests)\n`;
        }
      }
      context += "- User can ask: 'Show me my upcoming BEOs', 'What's the Smith wedding details?'\n";
    }
    context += "\n";

    // Server Checkouts
    context += "**SERVER CHECKOUTS:**\n";
    if (checkouts.total === 0) {
      context += "- No server checkouts yet\n";
    } else {
      context += `- ${checkouts.total} total checkouts\n`;
      context += `- Last 7 days: ${checkouts.recent} checkouts, $${checkouts.recentTips.toFixed(2)} total tips\n`;
      if (checkouts.avgTipsPerShift > 0) {
        context += `- Average tips per checkout: $${checkouts.avgTipsPerShift.toFixed(2)}\n`;
      }
      context += "- User can ask: 'How much did I make in tips yesterday?', 'Show my tipshare'\n";
    }
    context += "\n";

    // Paychecks
    context += "**PAYCHECKS:**\n";
    if (paychecks.total === 0) {
      context += "- No paychecks yet\n";
    } else {
      context += `- ${paychecks.total} total paychecks\n`;
      if (paychecks.lastPaycheck) {
        const lastDate = new Date(paychecks.lastPaycheck.pay_date).toLocaleDateString();
        context += `- Last paycheck: $${paychecks.lastPaycheck.net_pay?.toFixed(2) || '0.00'} on ${lastDate}\n`;
      }
      if (paychecks.ytdGross > 0) {
        context += `- YTD gross: $${paychecks.ytdGross.toFixed(2)}, YTD net: $${paychecks.ytdNet.toFixed(2)}\n`;
      }
      context += "- User can ask: 'When's my next paycheck?', 'Show my YTD earnings'\n";
    }
    context += "\n";

    // Receipts (Expenses)
    context += "**RECEIPTS (EXPENSES):**\n";
    if (receipts.total === 0) {
      context += "- No receipts/expenses yet\n";
    } else {
      context += `- ${receipts.total} total receipts\n`;
      context += `- This month: $${receipts.monthlyTotal.toFixed(2)} in expenses\n`;
      context += `- Tax deductible: $${receipts.deductibleTotal.toFixed(2)}\n`;
      if (receipts.topCategory) {
        context += `- Top category: ${receipts.topCategory}\n`;
      }
      context += "- User can ask: 'How much did I spend on gas?', 'Show deductible expenses'\n";
    }
    context += "\n";

    // Invoices (Income)
    context += "**INVOICES:**\n";
    if (invoices.total === 0) {
      context += "- No invoices yet\n";
    } else {
      context += `- ${invoices.total} total invoices\n`;
      context += `- Unpaid: ${invoices.unpaidCount} invoices, $${invoices.unpaidTotal.toFixed(2)} owed\n`;
      if (invoices.overdueCount > 0) {
        context += `- ⚠️ Overdue: ${invoices.overdueCount} invoices\n`;
      }
      context += "- User can ask: 'Who owes me money?', 'Show overdue invoices'\n";
    }
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

  private async getBEOEvents() {
    const now = new Date();
    const today = now.toISOString().split("T")[0];

    const { data: allEvents } = await this.supabase
      .from("beo_events")
      .select("*")
      .eq("user_id", this.userId)
      .order("event_date", { ascending: true });

    const events = allEvents || [];
    const upcoming = events.filter((e: any) => e.event_date >= today);
    const past = events.filter((e: any) => e.event_date < today);

    return {
      total: events.length,
      upcoming: upcoming.length,
      past: past.length,
      nextEvent: upcoming[0] || null,
    };
  }

  private async getServerCheckouts() {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const sevenDaysAgoStr = sevenDaysAgo.toISOString().split("T")[0];

    const { data: allCheckouts } = await this.supabase
      .from("server_checkouts")
      .select("*")
      .eq("user_id", this.userId)
      .order("checkout_date", { ascending: false });

    const checkouts = allCheckouts || [];
    const recentCheckouts = checkouts.filter((c: any) => c.checkout_date >= sevenDaysAgoStr);

    const recentTips = recentCheckouts.reduce((sum: number, c: any) => sum + (c.net_tips || 0), 0);
    const avgTipsPerShift = recentCheckouts.length > 0 ? recentTips / recentCheckouts.length : 0;

    return {
      total: checkouts.length,
      recent: recentCheckouts.length,
      recentTips,
      avgTipsPerShift,
    };
  }

  private async getPaychecks() {
    const { data: allPaychecks } = await this.supabase
      .from("paychecks")
      .select("*")
      .eq("user_id", this.userId)
      .order("pay_date", { ascending: false });

    const paychecks = allPaychecks || [];
    const lastPaycheck = paychecks[0] || null;

    // Calculate YTD totals from most recent paycheck
    const ytdGross = lastPaycheck?.ytd_gross || 0;
    const ytdNet = lastPaycheck?.ytd_gross 
      ? (lastPaycheck.ytd_gross - (lastPaycheck.ytd_federal_tax || 0) - (lastPaycheck.ytd_state_tax || 0))
      : 0;

    return {
      total: paychecks.length,
      lastPaycheck,
      ytdGross,
      ytdNet,
    };
  }

  private async getReceipts() {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfMonthStr = startOfMonth.toISOString().split("T")[0];

    const { data: allReceipts } = await this.supabase
      .from("receipts")
      .select("*")
      .eq("user_id", this.userId)
      .order("receipt_date", { ascending: false });

    const receipts = allReceipts || [];
    const monthlyReceipts = receipts.filter((r: any) => r.receipt_date >= startOfMonthStr);

    const monthlyTotal = monthlyReceipts.reduce((sum: number, r: any) => sum + (r.total_amount || 0), 0);
    const deductibleTotal = receipts
      .filter((r: any) => r.is_tax_deductible)
      .reduce((sum: number, r: any) => sum + (r.total_amount || 0), 0);

    // Find most common expense category
    const categories: { [key: string]: number } = {};
    receipts.forEach((r: any) => {
      if (r.expense_category) {
        categories[r.expense_category] = (categories[r.expense_category] || 0) + 1;
      }
    });
    const topCategory = Object.keys(categories).length > 0
      ? Object.keys(categories).reduce((a, b) => categories[a] > categories[b] ? a : b)
      : null;

    return {
      total: receipts.length,
      monthlyTotal,
      deductibleTotal,
      topCategory,
    };
  }

  private async getInvoices() {
    const now = new Date();
    const today = now.toISOString().split("T")[0];

    const { data: allInvoices } = await this.supabase
      .from("invoices")
      .select("*")
      .eq("user_id", this.userId)
      .order("invoice_date", { ascending: false });

    const invoices = allInvoices || [];
    const unpaid = invoices.filter((i: any) => i.status !== "paid");
    const overdue = invoices.filter((i: any) => i.status === "overdue" || (i.due_date && i.due_date < today && i.status !== "paid"));

    const unpaidTotal = unpaid.reduce((sum: number, i: any) => sum + (i.balance_due || i.total_amount || 0), 0);

    return {
      total: invoices.length,
      unpaidCount: unpaid.length,
      unpaidTotal,
      overdueCount: overdue.length,
    };
  }
}
