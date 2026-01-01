// Job Executor - Handles all job-related function calls
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// Industry inference keywords
const INDUSTRY_KEYWORDS: Record<string, string[]> = {
  "Food Service": [
    "bartender",
    "server",
    "waiter",
    "waitress",
    "barista",
    "chef",
    "cook",
    "host",
    "hostess",
    "sommelier",
    "busser",
    "food runner",
  ],
  "Beauty & Personal Care": [
    "barber",
    "hairstylist",
    "cosmetologist",
    "nail tech",
    "makeup artist",
    "esthetician",
    "massage therapist",
    "salon",
  ],
  Events: [
    "wedding planner",
    "event coordinator",
    "caterer",
    "dj",
    "photographer",
    "videographer",
    "florist",
  ],
  Hospitality: ["hotel", "valet", "concierge", "bellhop", "housekeeper", "front desk"],
  Rideshare: ["uber", "lyft", "driver", "rideshare"],
  Delivery: ["doordash", "uber eats", "grubhub", "postmates", "delivery driver", "courier"],
};

export class JobExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  async execute(functionName: string, args: any): Promise<any> {
    switch (functionName) {
      case "add_job":
        return await this.addJob(args);
      case "edit_job":
        return await this.editJob(args);
      case "delete_job":
        return await this.deleteJob(args);
      case "set_default_job":
        return await this.setDefaultJob(args);
      case "end_job":
        return await this.endJob(args);
      case "restore_job":
        return await this.restoreJob(args);
      case "get_jobs":
        return await this.getJobs(args);
      case "get_job_stats":
        return await this.getJobStats(args);
      case "compare_jobs":
        return await this.compareJobs(args);
      case "set_job_hourly_rate":
        return await this.setJobHourlyRate(args);
      default:
        throw new Error(`Unknown job function: ${functionName}`);
    }
  }

  private inferIndustry(jobName: string): string {
    const lowerName = jobName.toLowerCase();

    for (const [industry, keywords] of Object.entries(INDUSTRY_KEYWORDS)) {
      if (keywords.some((keyword) => lowerName.includes(keyword))) {
        return industry;
      }
    }

    return "Other Services";
  }

  private async addJob(args: any) {
    const {
      name,
      industry,
      hourlyRate = 0,
      color = "#00D632",
      isDefault = false,
      template = "custom",
    } = args;

    // Infer industry if not provided
    const finalIndustry = industry || this.inferIndustry(name);

    // If setting as default, unset other defaults first
    if (isDefault) {
      await this.supabase
        .from("jobs")
        .update({ is_default: false })
        .eq("user_id", this.userId);
    }

    const { data, error } = await this.supabase
      .from("jobs")
      .insert({
        user_id: this.userId,
        name: name,
        industry: finalIndustry,
        hourly_rate: hourlyRate,
        color: color,
        is_default: isDefault,
        template: template,
      })
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      job: data,
      inferredIndustry: !industry,
      message: `Created ${name} job${!industry ? ` (detected as ${finalIndustry})` : ""}`,
    };
  }

  private async editJob(args: any) {
    const { jobId, updates } = args;

    // Convert camelCase updates to snake_case
    const dbUpdates: any = {};
    if (updates.name !== undefined) dbUpdates.name = updates.name;
    if (updates.industry !== undefined) dbUpdates.industry = updates.industry;
    if (updates.hourlyRate !== undefined) dbUpdates.hourly_rate = updates.hourlyRate;
    if (updates.color !== undefined) dbUpdates.color = updates.color;
    if (updates.isDefault !== undefined) dbUpdates.is_default = updates.isDefault;
    if (updates.template !== undefined) dbUpdates.template = updates.template;

    // Check if setting as default
    if (dbUpdates.is_default === true) {
      await this.supabase
        .from("jobs")
        .update({ is_default: false })
        .eq("user_id", this.userId)
        .neq("id", jobId);
    }

    const { data, error } = await this.supabase
      .from("jobs")
      .update(dbUpdates)
      .eq("id", jobId)
      .eq("user_id", this.userId)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      job: data,
      message: "Job updated successfully",
    };
  }

  private async deleteJob(args: any) {
    const { jobId, deleteShifts = false, confirmed } = args;

    // Get job and shift count
    const { data: job, error: jobError } = await this.supabase
      .from("jobs")
      .select("*")
      .eq("id", jobId)
      .eq("user_id", this.userId)
      .single();

    if (jobError || !job) {
      throw new Error("Job not found");
    }

    const { data: shifts, error: shiftsError } = await this.supabase
      .from("shifts")
      .select("total_income")
      .eq("job_id", jobId)
      .eq("user_id", this.userId);

    if (shiftsError) throw shiftsError;

    const shiftCount = shifts.length;
    const totalIncome = shifts.reduce((sum, s) => sum + s.total_income, 0);

    if (!confirmed && shiftCount > 0) {
      return {
        needsConfirmation: true,
        job: job,
        shiftCount: shiftCount,
        totalIncome: totalIncome,
        message: `This job has ${shiftCount} shifts with total income of $${totalIncome.toFixed(2)}. Delete shifts too or keep them?`,
        options: ["delete_with_shifts", "delete_keep_shifts", "cancel"],
      };
    }

    // Delete or soft-delete shifts
    if (deleteShifts) {
      await this.supabase.from("shifts").delete().eq("job_id", jobId).eq("user_id", this.userId);
    } else {
      // Soft delete by setting deleted_at
      await this.supabase
        .from("shifts")
        .update({ deleted_at: new Date().toISOString() })
        .eq("job_id", jobId)
        .eq("user_id", this.userId);
    }

    // Delete job
    const { error: deleteError } = await this.supabase
      .from("jobs")
      .delete()
      .eq("id", jobId)
      .eq("user_id", this.userId);

    if (deleteError) throw deleteError;

    return {
      success: true,
      message: `Deleted ${job.name}${deleteShifts ? " and all shifts" : " (shifts preserved)"}`,
    };
  }

  private async setDefaultJob(args: any) {
    const { jobId } = args;

    // Unset all other defaults
    await this.supabase.from("jobs").update({ is_default: false }).eq("user_id", this.userId);

    // Set this one as default
    const { data, error } = await this.supabase
      .from("jobs")
      .update({ is_default: true })
      .eq("id", jobId)
      .eq("user_id", this.userId)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      job: data,
      message: `${data.name} is now your default job`,
    };
  }

  private async endJob(args: any) {
    const { jobId, endDate } = args;

    const finalEndDate = endDate || new Date().toISOString().split("T")[0];

    const { data, error } = await this.supabase
      .from("jobs")
      .update({
        is_active: false,
        end_date: finalEndDate,
      })
      .eq("id", jobId)
      .eq("user_id", this.userId)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      job: data,
      message: `${data.name} marked as ended on ${finalEndDate}`,
    };
  }

  private async restoreJob(args: any) {
    const { jobId } = args;

    const { data, error } = await this.supabase
      .from("jobs")
      .update({
        is_active: true,
        end_date: null,
      })
      .eq("id", jobId)
      .eq("user_id", this.userId)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      job: data,
      message: `${data.name} reactivated`,
    };
  }

  private async getJobs(args: any = {}) {
    const { includeEnded = false, includeDeleted = false } = args;

    let query = this.supabase.from("jobs").select("*").eq("user_id", this.userId);

    if (!includeEnded) {
      query = query.eq("is_active", true);
    }

    if (!includeDeleted) {
      query = query.is("deleted_at", null);
    }

    const { data: jobs, error } = await query.order("created_at", { ascending: false });

    if (error) throw error;

    // Get shift counts for each job
    const jobsWithStats = await Promise.all(
      jobs.map(async (job) => {
        const { data: shifts } = await this.supabase
          .from("shifts")
          .select("total_income")
          .eq("job_id", job.id)
          .eq("user_id", this.userId);

        const shiftCount = shifts?.length || 0;
        const totalIncome = shifts?.reduce((sum, s) => sum + s.total_income, 0) || 0;

        return {
          ...job,
          shiftCount,
          totalIncome,
        };
      })
    );

    return {
      success: true,
      jobs: jobsWithStats,
      count: jobsWithStats.length,
    };
  }

  private async getJobStats(args: any) {
    const { jobId, period = "all_time" } = args;

    // Get job
    const { data: job, error: jobError } = await this.supabase
      .from("jobs")
      .select("*")
      .eq("id", jobId)
      .eq("user_id", this.userId)
      .single();

    if (jobError || !job) throw new Error("Job not found");

    // Build date filter
    let query = this.supabase
      .from("shifts")
      .select("*")
      .eq("job_id", jobId)
      .eq("user_id", this.userId);

    const now = new Date();
    if (period === "week") {
      const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      query = query.gte("date", weekAgo.toISOString().split("T")[0]);
    } else if (period === "month") {
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
      query = query.gte("date", monthStart.toISOString().split("T")[0]);
    } else if (period === "year") {
      const yearStart = new Date(now.getFullYear(), 0, 1);
      query = query.gte("date", yearStart.toISOString().split("T")[0]);
    }

    const { data: shifts, error } = await query;

    if (error) throw error;

    const totalIncome = shifts.reduce((sum, s) => sum + s.total_income, 0);
    const totalHours = shifts.reduce((sum, s) => sum + s.hours_worked, 0);
    const avgPerHour = totalHours > 0 ? totalIncome / totalHours : 0;

    // Get best days
    const dayTotals: Record<number, number[]> = {};
    shifts.forEach((shift) => {
      const day = new Date(shift.date).getDay();
      if (!dayTotals[day]) dayTotals[day] = [];
      dayTotals[day].push(shift.total_income);
    });

    const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    const bestDays = Object.entries(dayTotals)
      .map(([day, amounts]) => ({
        day: dayNames[parseInt(day)],
        avgIncome: amounts.reduce((a, b) => a + b, 0) / amounts.length,
        shiftCount: amounts.length,
      }))
      .sort((a, b) => b.avgIncome - a.avgIncome);

    return {
      success: true,
      job: job,
      period: period,
      stats: {
        totalIncome,
        totalHours,
        shiftCount: shifts.length,
        avgPerHour,
        bestDays: bestDays.slice(0, 3),
      },
    };
  }

  private async compareJobs(args: any) {
    const { jobIds, period = "all_time" } = args;

    const comparisons = await Promise.all(
      jobIds.map(async (jobId: string) => {
        const stats = await this.getJobStats({ jobId, period });
        return stats;
      })
    );

    return {
      success: true,
      period: period,
      comparisons: comparisons,
    };
  }

  private async setJobHourlyRate(args: any) {
    const { jobId, newRate, effectiveDate, updatePastShifts = false } = args;

    // Update job
    const { data: job, error: jobError } = await this.supabase
      .from("jobs")
      .update({ hourly_rate: newRate })
      .eq("id", jobId)
      .eq("user_id", this.userId)
      .select()
      .single();

    if (jobError) throw jobError;

    if (updatePastShifts) {
      // Update past shifts with new rate
      const { data: shifts, error: shiftsError } = await this.supabase
        .from("shifts")
        .select("*")
        .eq("job_id", jobId)
        .eq("user_id", this.userId);

      if (shiftsError) throw shiftsError;

      // Recalculate each shift
      await Promise.all(
        shifts.map(async (shift) => {
          const newWages = newRate * shift.hours_worked;
          const newTotal = newWages + shift.net_tips;

          await this.supabase
            .from("shifts")
            .update({
              hourly_rate: newRate,
              hourly_wages: newWages,
              total_income: newTotal,
            })
            .eq("id", shift.id);
        })
      );

      return {
        success: true,
        job: job,
        updatedShiftCount: shifts.length,
        message: `Updated hourly rate to $${newRate}/hr and recalculated ${shifts.length} shifts`,
      };
    }

    return {
      success: true,
      job: job,
      message: `Hourly rate updated to $${newRate}/hr (future shifts only)`,
    };
  }
}
