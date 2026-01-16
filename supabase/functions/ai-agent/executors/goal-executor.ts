// @ts-nocheck
// Goal Executor - Handles all goal-related function calls
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class GoalExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  async execute(functionName: string, args: any): Promise<any> {
    switch (functionName) {
      case "set_daily_goal":
        return await this.setGoal("daily", args);
      case "set_weekly_goal":
        return await this.setGoal("weekly", args);
      case "set_monthly_goal":
        return await this.setGoal("monthly", args);
      case "set_yearly_goal":
        return await this.setGoal("yearly", args);
      case "edit_goal":
        return await this.editGoal(args);
      case "delete_goal":
        return await this.deleteGoal(args);
      case "get_goals":
        return await this.getGoals(args);
      case "get_goal_progress":
        return await this.getGoalProgress(args);
      default:
        throw new Error(`Unknown goal function: ${functionName}`);
    }
  }

  private async setGoal(type: string, args: any) {
    const { amount, jobId, targetHours } = args;

    // Check if goal already exists
    let query = this.supabase
      .from("goals")
      .select("*")
      .eq("user_id", this.userId)
      .eq("type", type);

    if (jobId) {
      query = query.eq("job_id", jobId);
    } else {
      query = query.is("job_id", null);
    }

    const { data: existing } = await query.single();

    if (existing) {
      // Update existing
      const { data, error } = await this.supabase
        .from("goals")
        .update({
          target_amount: amount,
          target_hours: targetHours,
        })
        .eq("id", existing.id)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        goal: data,
        updated: true,
        message: `Updated ${type} goal to $${amount}`,
        navigationBadges: [
          {
            label: "View Goals",
            route: "/goals",
            icon: "goals"
          }
        ]
      };
    } else {
      // Create new
      const { data, error } = await this.supabase
        .from("goals")
        .insert({
          user_id: this.userId,
          type: type,
          target_amount: amount,
          target_hours: targetHours,
          job_id: jobId,
        })
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        goal: data,
        created: true,
        message: `Created ${type} goal of $${amount}`,
        navigationBadges: [
          {
            label: "View Goals",
            route: "/goals",
            icon: "goals"
          }
        ]
      };
    }
  }

  private async editGoal(args: any) {
    const { goalId, updates } = args;

    // Convert camelCase updates to snake_case
    const dbUpdates: any = {};
    if (updates.amount !== undefined) dbUpdates.target_amount = updates.amount;
    if (updates.targetHours !== undefined) dbUpdates.target_hours = updates.targetHours;
    if (updates.jobId !== undefined) dbUpdates.job_id = updates.jobId;
    if (updates.type !== undefined) dbUpdates.type = updates.type;

    const { data, error } = await this.supabase
      .from("goals")
      .update(dbUpdates)
      .eq("id", goalId)
      .eq("user_id", this.userId)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      goal: data,
      message: "Goal updated",
      navigationBadges: [
        {
          label: "View Goals",
          route: "/goals",
          icon: "goals"
        }
      ]
    };
  }

  private async deleteGoal(args: any) {
    const { goalId } = args;

    const { error } = await this.supabase
      .from("goals")
      .delete()
      .eq("id", goalId)
      .eq("user_id", this.userId);

    if (error) throw error;

    return {
      success: true,
      message: "Goal deleted",
      navigationBadges: [
        {
          label: "View Goals",
          route: "/goals",
          icon: "goals"
        }
      ]
    };
  }

  private async getGoals(args: any = {}) {
    const { includeCompleted = true } = args;

    const { data: goals, error } = await this.supabase
      .from("goals")
      .select("*")
      .eq("user_id", this.userId)
      .order("created_at", { ascending: false });

    if (error) throw error;

    // Calculate progress for each goal
    const goalsWithProgress = await Promise.all(
      goals.map(async (goal: any) => {
        const progress = await this.calculateGoalProgress(goal);
        return { ...goal, ...progress };
      })
    );

    return {
      success: true,
      goals: goalsWithProgress,
      count: goalsWithProgress.length,
    };
  }

  private async getGoalProgress(args: any) {
    const { goalId } = args;

    const { data: goal, error } = await this.supabase
      .from("goals")
      .select("*")
      .eq("id", goalId)
      .eq("user_id", this.userId)
      .single();

    if (error || !goal) throw new Error("Goal not found");

    const progress = await this.calculateGoalProgress(goal);

    return {
      success: true,
      goal: goal,
      ...progress,
    };
  }

  private async calculateGoalProgress(goal: any) {
    const now = new Date();
    let startDate: Date;
    let endDate: Date = now;

    // Determine date range based on goal type
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

    // Query shifts in range
    let query = this.supabase
      .from("shifts")
      .select("total_income, hours_worked")
      .eq("user_id", this.userId)
      .gte("date", startDate.toISOString().split("T")[0])
      .lte("date", endDate.toISOString().split("T")[0]);

    if (goal.job_id) {
      query = query.eq("job_id", goal.job_id);
    }

    const { data: shifts, error } = await query;

    if (error) throw error;

    const currentAmount = shifts.reduce((sum: number, s: any) => sum + s.total_income, 0);
    const currentHours = shifts.reduce((sum: number, s: any) => sum + s.hours_worked, 0);

    const progressPercent = (currentAmount / goal.target_amount) * 100;
    const remaining = goal.target_amount - currentAmount;
    const isComplete = currentAmount >= goal.target_amount;

    return {
      currentAmount,
      currentHours,
      progressPercent: Math.round(progressPercent),
      remaining: Math.max(0, remaining),
      isComplete,
      targetAmount: goal.target_amount,
      targetHours: goal.target_hours,
    };
  }
}
