// Analytics Executor - Handles all query and reporting functions
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class AnalyticsExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  async execute(functionName: string, args: any): Promise<any> {
    switch (functionName) {
      case "get_income_summary":
        return await this.getIncomeSummary(args);
      case "compare_periods":
        return await this.comparePeriods(args);
      case "get_best_days":
        return await this.getBestDays(args);
      case "get_worst_days":
        return await this.getWorstDays(args);
      case "get_tax_estimate":
        return await this.getTaxEstimate(args);
      case "get_projected_year_end":
        return await this.getProjectedYearEnd(args);
      case "get_year_over_year":
        return await this.getYearOverYear();
      case "get_event_earnings":
        return await this.getEventEarnings(args);
      default:
        throw new Error(`Unknown analytics function: ${functionName}`);
    }
  }

  private async getIncomeSummary(args: any) {
    const { period, dateRange, jobId } = args;

    let startDate: Date;
    let endDate: Date = new Date();

    if (period === "custom" && dateRange) {
      startDate = new Date(dateRange.start);
      endDate = new Date(dateRange.end);
    } else {
      switch (period) {
        case "today":
          startDate = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate());
          break;
        case "week":
          const dayOfWeek = endDate.getDay();
          startDate = new Date(endDate.getTime() - dayOfWeek * 24 * 60 * 60 * 1000);
          break;
        case "month":
          startDate = new Date(endDate.getFullYear(), endDate.getMonth(), 1);
          break;
        case "year":
          startDate = new Date(endDate.getFullYear(), 0, 1);
          break;
        default:
          throw new Error(`Invalid period: ${period}`);
      }
    }

    let query = this.supabase
      .from("shifts")
      .select("*")
      .eq("user_id", this.userId)
      .gte("date", startDate.toISOString().split("T")[0])
      .lte("date", endDate.toISOString().split("T")[0]);

    if (jobId) {
      query = query.eq("job_id", jobId);
    }

    const { data: shifts, error } = await query;

    if (error) throw error;

    const totalIncome = shifts.reduce((sum, s) => sum + s.total_income, 0);
    const totalTips = shifts.reduce((sum, s) => sum + s.total_tips, 0);
    const totalHours = shifts.reduce((sum, s) => sum + s.hours_worked, 0);
    const avgPerHour = totalHours > 0 ? totalIncome / totalHours : 0;

    return {
      success: true,
      period,
      startDate: startDate.toISOString().split("T")[0],
      endDate: endDate.toISOString().split("T")[0],
      summary: {
        totalIncome,
        totalTips,
        totalHours,
        avgPerHour,
        shiftCount: shifts.length,
      },
    };
  }

  private async comparePeriods(args: any) {
    const { period1, period2 } = args;

    // Get data for both periods
    const data1 = await this.getPeriodData(period1);
    const data2 = await this.getPeriodData(period2);

    const difference = data2.totalIncome - data1.totalIncome;
    const percentChange =
      data1.totalIncome > 0 ? ((difference / data1.totalIncome) * 100).toFixed(1) : 0;

    return {
      success: true,
      period1: data1,
      period2: data2,
      comparison: {
        difference,
        percentChange,
        direction: difference > 0 ? "increase" : "decrease",
      },
    };
  }

  private async getPeriodData(periodSpec: any) {
    const { period, year, month } = periodSpec;

    let startDate: Date;
    let endDate: Date;

    if (period === "month") {
      startDate = new Date(year, month - 1, 1);
      endDate = new Date(year, month, 0);
    } else if (period === "year") {
      startDate = new Date(year, 0, 1);
      endDate = new Date(year, 11, 31);
    } else {
      throw new Error("Invalid period specification");
    }

    const { data: shifts } = await this.supabase
      .from("shifts")
      .select("*")
      .eq("user_id", this.userId)
      .gte("date", startDate.toISOString().split("T")[0])
      .lte("date", endDate.toISOString().split("T")[0]);

    const totalIncome = shifts?.reduce((sum, s) => sum + s.total_income, 0) || 0;

    return {
      period,
      year,
      month,
      totalIncome,
      shiftCount: shifts?.length || 0,
    };
  }

  private async getBestDays(args: any = {}) {
    const { limit = 5, jobId } = args;

    let query = this.supabase
      .from("shifts")
      .select("*")
      .eq("user_id", this.userId);

    if (jobId) {
      query = query.eq("job_id", jobId);
    }

    const { data: shifts, error } = await query;

    if (error) throw error;

    const dayTotals: Record<number, number[]> = {};
    shifts.forEach((shift) => {
      const day = new Date(shift.date).getDay();
      if (!dayTotals[day]) dayTotals[day] = [];
      dayTotals[day].push(shift.total_income);
    });

    const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

    const dayStats = Object.entries(dayTotals)
      .map(([day, amounts]) => ({
        day: dayNames[parseInt(day)],
        avgIncome: amounts.reduce((a, b) => a + b, 0) / amounts.length,
        shiftCount: amounts.length,
      }))
      .sort((a, b) => b.avgIncome - a.avgIncome)
      .slice(0, limit);

    return {
      success: true,
      bestDays: dayStats,
    };
  }

  private async getWorstDays(args: any = {}) {
    const { limit = 5, jobId } = args;

    const bestDaysResult = await this.getBestDays({ limit: 100, jobId });
    const worstDays = bestDaysResult.bestDays
      .sort((a: any, b: any) => a.avgIncome - b.avgIncome)
      .slice(0, limit);

    return {
      success: true,
      worstDays,
    };
  }

  private async getTaxEstimate(args: any = {}) {
    const { year = new Date().getFullYear() } = args;

    const { data: shifts } = await this.supabase
      .from("shifts")
      .select("total_income")
      .eq("user_id", this.userId)
      .gte("date", `${year}-01-01`)
      .lte("date", `${year}-12-31`);

    const yearlyIncome = shifts?.reduce((sum, s) => sum + s.total_income, 0) || 0;

    // Simplified tax calculation (2025 rates for single filer)
    const standardDeduction = 14600;
    const taxableIncome = Math.max(0, yearlyIncome - standardDeduction);

    let federalTax = 0;
    if (taxableIncome <= 11600) {
      federalTax = taxableIncome * 0.1;
    } else if (taxableIncome <= 47150) {
      federalTax = 1160 + (taxableIncome - 11600) * 0.12;
    } else if (taxableIncome <= 100525) {
      federalTax = 5426 + (taxableIncome - 47150) * 0.22;
    } else {
      federalTax = 17168.5 + (taxableIncome - 100525) * 0.24;
    }

    // Self-employment tax (15.3% on 92.35% of net earnings)
    const seTax = yearlyIncome * 0.9235 * 0.153;

    const totalTax = federalTax + seTax;
    const effectiveRate = yearlyIncome > 0 ? (totalTax / yearlyIncome) * 100 : 0;

    return {
      success: true,
      year,
      yearlyIncome,
      federalTax: Math.round(federalTax),
      selfEmploymentTax: Math.round(seTax),
      totalTax: Math.round(totalTax),
      effectiveRate: effectiveRate.toFixed(2),
      message: "This is an estimate for single filer. Consult a tax professional for accurate calculations.",
    };
  }

  private async getProjectedYearEnd(args: any = {}) {
    const { year = new Date().getFullYear() } = args;

    const now = new Date();
    const yearStart = new Date(year, 0, 1);
    const yearEnd = new Date(year, 11, 31);
    const daysInYear = 365;
    const daysPassed = Math.floor((now.getTime() - yearStart.getTime()) / (1000 * 60 * 60 * 24));

    const { data: shifts } = await this.supabase
      .from("shifts")
      .select("total_income")
      .eq("user_id", this.userId)
      .gte("date", `${year}-01-01`)
      .lte("date", now.toISOString().split("T")[0]);

    const incomeToDate = shifts?.reduce((sum, s) => sum + s.total_income, 0) || 0;

    const dailyAvg = daysPassed > 0 ? incomeToDate / daysPassed : 0;
    const projectedYearEnd = dailyAvg * daysInYear;

    return {
      success: true,
      year,
      incomeToDate,
      daysPassed,
      projectedYearEnd: Math.round(projectedYearEnd),
      dailyAvg: Math.round(dailyAvg),
      message: `At your current pace, you're projected to earn $${Math.round(projectedYearEnd)} by year-end`,
    };
  }

  private async getYearOverYear() {
    const currentYear = new Date().getFullYear();
    const lastYear = currentYear - 1;

    const current = await this.getTaxEstimate({ year: currentYear });
    const previous = await this.getTaxEstimate({ year: lastYear });

    const difference = current.yearlyIncome - previous.yearlyIncome;
    const percentChange =
      previous.yearlyIncome > 0
        ? ((difference / previous.yearlyIncome) * 100).toFixed(1)
        : 0;

    return {
      success: true,
      currentYear: { year: currentYear, income: current.yearlyIncome },
      previousYear: { year: lastYear, income: previous.yearlyIncome },
      comparison: {
        difference,
        percentChange,
        direction: difference > 0 ? "growth" : "decline",
      },
    };
  }

  private async getEventEarnings(args: any) {
    const { eventName } = args;

    const { data: shifts, error } = await this.supabase
      .from("shifts")
      .select("*")
      .eq("user_id", this.userId)
      .ilike("event_name", `%${eventName}%`);

    if (error) throw error;

    const totalIncome = shifts.reduce((sum, s) => sum + s.total_income, 0);
    const dates = shifts.map((s) => s.date).sort();

    return {
      success: true,
      eventName,
      totalIncome,
      shiftCount: shifts.length,
      dateRange: {
        first: dates[0],
        last: dates[dates.length - 1],
      },
      shifts,
    };
  }
}
