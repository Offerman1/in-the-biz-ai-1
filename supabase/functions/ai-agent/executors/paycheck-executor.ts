// @ts-nocheck
// Paycheck Executor - Handles all paycheck operations for W-2 workers
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class PaycheckExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  // ============================================
  // READ OPERATIONS
  // ============================================

  async getPaychecks(filters?: {
    startDate?: string;
    endDate?: string;
    year?: number;
    employerName?: string;
  }): Promise<any> {
    try {
      let query = this.supabase
        .from("paychecks")
        .select("*")
        .eq("user_id", this.userId);

      if (filters?.startDate) {
        query = query.gte("pay_date", filters.startDate);
      }
      if (filters?.endDate) {
        query = query.lte("pay_date", filters.endDate);
      }
      if (filters?.year) {
        const yearStart = `${filters.year}-01-01`;
        const yearEnd = `${filters.year}-12-31`;
        query = query.gte("pay_date", yearStart).lte("pay_date", yearEnd);
      }
      if (filters?.employerName) {
        query = query.ilike("employer_name", `%${filters.employerName}%`);
      }

      query = query.order("pay_date", { ascending: false });

      const { data, error } = await query;

      if (error) throw error;

      return {
        success: true,
        paychecks: data || [],
        count: (data || []).length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async searchPaychecks(searchTerm: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("paychecks")
        .select("*")
        .eq("user_id", this.userId)
        .or(`employer_name.ilike.%${searchTerm}%,payroll_provider.ilike.%${searchTerm}%`)
        .order("pay_date", { ascending: false });

      if (error) throw error;

      return {
        success: true,
        paychecks: data || [],
        count: (data || []).length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getPaycheckDetails(paycheckId: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("paychecks")
        .select("*")
        .eq("id", paycheckId)
        .eq("user_id", this.userId)
        .single();

      if (error) throw error;

      if (!data) {
        return {
          success: false,
          error: "Paycheck not found",
        };
      }

      const paycheck = data;
      let summary = `**Paycheck - ${new Date(paycheck.pay_date).toLocaleDateString()}**\n\n`;
      
      if (paycheck.employer_name) {
        summary += `🏢 **Employer:** ${paycheck.employer_name}\n`;
      }
      if (paycheck.pay_period_start && paycheck.pay_period_end) {
        summary += `📅 **Period:** ${new Date(paycheck.pay_period_start).toLocaleDateString()} - ${new Date(paycheck.pay_period_end).toLocaleDateString()}\n`;
      }
      
      summary += `\n**Earnings:**\n`;
      if (paycheck.regular_hours) {
        summary += `⏰ Regular Hours: ${paycheck.regular_hours} @ $${paycheck.hourly_rate?.toFixed(2) || '0.00'}/hr\n`;
      }
      if (paycheck.overtime_hours) {
        summary += `⏰ Overtime Hours: ${paycheck.overtime_hours} @ $${paycheck.overtime_rate?.toFixed(2) || '0.00'}/hr\n`;
      }
      if (paycheck.gross_pay) {
        summary += `💰 **Gross Pay:** $${paycheck.gross_pay.toFixed(2)}\n`;
      }
      
      summary += `\n**Deductions:**\n`;
      if (paycheck.federal_tax) {
        summary += `🏛️ Federal Tax: -$${paycheck.federal_tax.toFixed(2)}\n`;
      }
      if (paycheck.state_tax) {
        summary += `🏛️ State Tax: -$${paycheck.state_tax.toFixed(2)}\n`;
      }
      if (paycheck.fica_tax) {
        summary += `🏛️ FICA: -$${paycheck.fica_tax.toFixed(2)}\n`;
      }
      if (paycheck.medicare_tax) {
        summary += `🏛️ Medicare: -$${paycheck.medicare_tax.toFixed(2)}\n`;
      }
      if (paycheck.other_deductions) {
        summary += `📋 Other: -$${paycheck.other_deductions.toFixed(2)}\n`;
      }
      
      if (paycheck.net_pay) {
        summary += `\n✅ **Net Pay:** $${paycheck.net_pay.toFixed(2)}\n`;
      }
      
      if (paycheck.ytd_gross) {
        summary += `\n**Year-to-Date:**\n`;
        summary += `💰 YTD Gross: $${paycheck.ytd_gross.toFixed(2)}\n`;
        if (paycheck.ytd_federal_tax) {
          summary += `🏛️ YTD Federal Tax: $${paycheck.ytd_federal_tax.toFixed(2)}\n`;
        }
      }

      return {
        success: true,
        paycheck: data,
        summary,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getUpcomingPaycheck(): Promise<any> {
    try {
      // Get the last 3 paychecks to determine pay frequency
      const { data: recentPaychecks } = await this.supabase
        .from("paychecks")
        .select("pay_date")
        .eq("user_id", this.userId)
        .order("pay_date", { ascending: false })
        .limit(3);

      if (!recentPaychecks || recentPaychecks.length < 2) {
        return {
          success: false,
          error: "Not enough paycheck history to predict next paycheck",
        };
      }

      // Calculate average days between paychecks
      const dates = recentPaychecks.map((p: any) => new Date(p.pay_date).getTime());
      const intervals = [];
      for (let i = 0; i < dates.length - 1; i++) {
        intervals.push((dates[i] - dates[i + 1]) / (1000 * 60 * 60 * 24));
      }
      const avgInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;

      // Predict next paycheck date
      const lastPayDate = new Date(recentPaychecks[0].pay_date);
      const nextPayDate = new Date(lastPayDate.getTime() + avgInterval * 24 * 60 * 60 * 1000);

      // Determine frequency
      let frequency = "Unknown";
      if (avgInterval >= 13 && avgInterval <= 15) frequency = "Bi-weekly (every 2 weeks)";
      else if (avgInterval >= 6 && avgInterval <= 8) frequency = "Weekly";
      else if (avgInterval >= 28 && avgInterval <= 31) frequency = "Monthly";
      else if (avgInterval >= 14 && avgInterval <= 16) frequency = "Semi-monthly (twice a month)";

      return {
        success: true,
        predictedDate: nextPayDate.toISOString().split("T")[0],
        frequency,
        daysUntil: Math.ceil((nextPayDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24)),
        lastPayDate: recentPaychecks[0].pay_date,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getYTDEarnings(year?: number): Promise<any> {
    try {
      const targetYear = year || new Date().getFullYear();
      
      // Get the most recent paycheck in the year (has the latest YTD totals)
      const { data: paychecks, error } = await this.supabase
        .from("paychecks")
        .select("*")
        .eq("user_id", this.userId)
        .gte("pay_date", `${targetYear}-01-01`)
        .lte("pay_date", `${targetYear}-12-31`)
        .order("pay_date", { ascending: false })
        .limit(1);

      if (error) throw error;

      if (!paychecks || paychecks.length === 0) {
        return {
          success: false,
          error: `No paychecks found for ${targetYear}`,
        };
      }

      const latestPaycheck = paychecks[0];

      return {
        success: true,
        year: targetYear,
        ytdGross: latestPaycheck.ytd_gross || 0,
        ytdFederalTax: latestPaycheck.ytd_federal_tax || 0,
        ytdStateTax: latestPaycheck.ytd_state_tax || 0,
        ytdFica: latestPaycheck.ytd_fica || 0,
        ytdMedicare: latestPaycheck.ytd_medicare || 0,
        ytdNet: (latestPaycheck.ytd_gross || 0) - (latestPaycheck.ytd_federal_tax || 0) - (latestPaycheck.ytd_state_tax || 0) - (latestPaycheck.ytd_fica || 0) - (latestPaycheck.ytd_medicare || 0),
        asOf: latestPaycheck.pay_date,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  // ============================================
  // WRITE OPERATIONS
  // ============================================

  async editPaycheck(paycheckId: string, updates: any): Promise<any> {
    try {
      const { data: paycheck } = await this.supabase
        .from("paychecks")
        .select("id")
        .eq("id", paycheckId)
        .eq("user_id", this.userId)
        .single();

      if (!paycheck) {
        return {
          success: false,
          error: "Paycheck not found or doesn't belong to you",
        };
      }

      const { data, error } = await this.supabase
        .from("paychecks")
        .update(updates)
        .eq("id", paycheckId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        message: "Paycheck updated successfully",
        paycheck: data,
        navigationBadges: [
          {
            label: "View Paychecks",
            route: "/paychecks",
            icon: "paycheck"
          }
        ]
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async deletePaycheck(paycheckId: string, confirmed: boolean): Promise<any> {
    if (!confirmed) {
      const { data: paycheck } = await this.supabase
        .from("paychecks")
        .select("pay_date, net_pay, employer_name")
        .eq("id", paycheckId)
        .eq("user_id", this.userId)
        .single();

      if (!paycheck) {
        return {
          success: false,
          error: "Paycheck not found",
        };
      }

      return {
        success: false,
        requiresConfirmation: true,
        message: `Are you sure you want to delete the paycheck from ${paycheck.employer_name || 'Unknown'} on ${new Date(paycheck.pay_date).toLocaleDateString()} ($${paycheck.net_pay?.toFixed(2) || '0.00'})? This cannot be undone.`,
        paycheck,
      };
    }

    try {
      const { error } = await this.supabase
        .from("paychecks")
        .delete()
        .eq("id", paycheckId)
        .eq("user_id", this.userId);

      if (error) throw error;

      return {
        success: true,
        message: "Paycheck deleted successfully",
        navigationBadges: [
          {
            label: "View Paychecks",
            route: "/paychecks",
            icon: "paycheck"
          }
        ]
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getDeductionSummary(year?: number): Promise<any> {
    try {
      const targetYear = year || new Date().getFullYear();
      
      const result = await this.getPaychecks({
        year: targetYear,
      });

      if (!result.success) return result;

      const paychecks = result.paychecks;

      if (paychecks.length === 0) {
        return {
          success: false,
          error: `No paychecks found for ${targetYear}`,
        };
      }

      const totalFederalTax = paychecks.reduce((sum: number, p: any) => sum + (p.federal_tax || 0), 0);
      const totalStateTax = paychecks.reduce((sum: number, p: any) => sum + (p.state_tax || 0), 0);
      const totalFica = paychecks.reduce((sum: number, p: any) => sum + (p.fica_tax || 0), 0);
      const totalMedicare = paychecks.reduce((sum: number, p: any) => sum + (p.medicare_tax || 0), 0);
      const totalOther = paychecks.reduce((sum: number, p: any) => sum + (p.other_deductions || 0), 0);

      return {
        success: true,
        year: targetYear,
        deductions: {
          federalTax: totalFederalTax,
          stateTax: totalStateTax,
          fica: totalFica,
          medicare: totalMedicare,
          other: totalOther,
          total: totalFederalTax + totalStateTax + totalFica + totalMedicare + totalOther,
        },
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getTaxWithholdingSummary(year?: number): Promise<any> {
    return this.getDeductionSummary(year);
  }

  async comparePaychecks(paycheck1Id: string, paycheck2Id: string): Promise<any> {
    try {
      const [result1, result2] = await Promise.all([
        this.getPaycheckDetails(paycheck1Id),
        this.getPaycheckDetails(paycheck2Id),
      ]);

      if (!result1.success || !result2.success) {
        return {
          success: false,
          error: "One or both paychecks not found",
        };
      }

      const p1 = result1.paycheck;
      const p2 = result2.paycheck;

      const comparison = {
        date1: p1.pay_date,
        date2: p2.pay_date,
        grossDiff: (p1.gross_pay || 0) - (p2.gross_pay || 0),
        netDiff: (p1.net_pay || 0) - (p2.net_pay || 0),
        federalTaxDiff: (p1.federal_tax || 0) - (p2.federal_tax || 0),
        regularHoursDiff: (p1.regular_hours || 0) - (p2.regular_hours || 0),
        overtimeHoursDiff: (p1.overtime_hours || 0) - (p2.overtime_hours || 0),
      };

      return {
        success: true,
        paycheck1: p1,
        paycheck2: p2,
        comparison,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getPayFrequency(): Promise<any> {
    try {
      const { data: paychecks } = await this.supabase
        .from("paychecks")
        .select("pay_date")
        .eq("user_id", this.userId)
        .order("pay_date", { ascending: false })
        .limit(4);

      if (!paychecks || paychecks.length < 2) {
        return {
          success: false,
          error: "Not enough paycheck history to determine frequency",
        };
      }

      // Calculate intervals
      const dates = paychecks.map((p: any) => new Date(p.pay_date).getTime());
      const intervals = [];
      for (let i = 0; i < dates.length - 1; i++) {
        intervals.push(Math.round((dates[i] - dates[i + 1]) / (1000 * 60 * 60 * 24)));
      }

      const avgInterval = Math.round(intervals.reduce((a, b) => a + b, 0) / intervals.length);

      let frequency = "Unknown";
      let paychecksPerYear = 0;

      if (avgInterval >= 6 && avgInterval <= 8) {
        frequency = "Weekly";
        paychecksPerYear = 52;
      } else if (avgInterval >= 13 && avgInterval <= 15) {
        frequency = "Bi-weekly";
        paychecksPerYear = 26;
      } else if (avgInterval >= 14 && avgInterval <= 16) {
        frequency = "Semi-monthly";
        paychecksPerYear = 24;
      } else if (avgInterval >= 28 && avgInterval <= 31) {
        frequency = "Monthly";
        paychecksPerYear = 12;
      }

      return {
        success: true,
        frequency,
        avgDaysBetweenPaychecks: avgInterval,
        paychecksPerYear,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async projectAnnualSalary(): Promise<any> {
    try {
      const freqResult = await this.getPayFrequency();
      if (!freqResult.success) return freqResult;

      // Get recent paychecks to calculate average
      const { data: recentPaychecks } = await this.supabase
        .from("paychecks")
        .select("gross_pay, net_pay")
        .eq("user_id", this.userId)
        .order("pay_date", { ascending: false })
        .limit(5);

      if (!recentPaychecks || recentPaychecks.length === 0) {
        return {
          success: false,
          error: "No paychecks found to project from",
        };
      }

      const avgGross = recentPaychecks.reduce((sum: number, p: any) => sum + (p.gross_pay || 0), 0) / recentPaychecks.length;
      const avgNet = recentPaychecks.reduce((sum: number, p: any) => sum + (p.net_pay || 0), 0) / recentPaychecks.length;

      const projectedAnnualGross = avgGross * freqResult.paychecksPerYear;
      const projectedAnnualNet = avgNet * freqResult.paychecksPerYear;

      return {
        success: true,
        frequency: freqResult.frequency,
        avgPaycheckGross: avgGross,
        avgPaycheckNet: avgNet,
        projectedAnnualGross,
        projectedAnnualNet,
        paychecksPerYear: freqResult.paychecksPerYear,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async bulkDeletePaychecks(confirmed: boolean): Promise<any> {
    try {
      if (!confirmed) {
        return {
          success: false,
          needsConfirmation: true,
          message: "Are you sure you want to delete ALL paychecks? This cannot be undone.",
        };
      }

      const { data: paychecks, error: fetchError } = await this.supabase
        .from("paychecks")
        .select("*")
        .eq("user_id", this.userId);

      if (fetchError) throw fetchError;

      if (!paychecks || paychecks.length === 0) {
        return {
          success: true,
          count: 0,
          message: "No paychecks to delete",
        };
      }

      const { error: deleteError } = await this.supabase
        .from("paychecks")
        .delete()
        .eq("user_id", this.userId);

      if (deleteError) throw deleteError;

      return {
        success: true,
        count: paychecks.length,
        message: `✅ Deleted ${paychecks.length} paycheck(s)`,
        navigationBadges: [
          {
            label: "View Paychecks",
            route: "/paychecks",
            icon: "paycheck"
          }
        ]
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }
}
