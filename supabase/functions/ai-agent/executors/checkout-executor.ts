// @ts-nocheck
// Checkout Executor - Handles all server checkout operations
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class CheckoutExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  // ============================================
  // READ OPERATIONS
  // ============================================

  async getCheckouts(filters?: {
    startDate?: string;
    endDate?: string;
    jobId?: string;
    minTips?: number;
    maxTips?: number;
  }): Promise<any> {
    try {
      let query = this.supabase
        .from("server_checkouts")
        .select("*")
        .eq("user_id", this.userId);

      if (filters?.startDate) {
        query = query.gte("checkout_date", filters.startDate);
      }
      if (filters?.endDate) {
        query = query.lte("checkout_date", filters.endDate);
      }
      if (filters?.jobId) {
        query = query.eq("job_id", filters.jobId);
      }

      query = query.order("checkout_date", { ascending: false });

      const { data, error } = await query;

      if (error) throw error;

      let checkouts = data || [];

      // Apply tip filters in memory (since we're filtering on calculated net_tips)
      if (filters?.minTips) {
        checkouts = checkouts.filter((c: any) => (c.net_tips || 0) >= filters.minTips!);
      }
      if (filters?.maxTips) {
        checkouts = checkouts.filter((c: any) => (c.net_tips || 0) <= filters.maxTips!);
      }

      return {
        success: true,
        checkouts,
        count: checkouts.length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async searchCheckouts(searchTerm: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("server_checkouts")
        .select("*")
        .eq("user_id", this.userId)
        .or(`section.ilike.%${searchTerm}%,notes.ilike.%${searchTerm}%`)
        .order("checkout_date", { ascending: false });

      if (error) throw error;

      return {
        success: true,
        checkouts: data || [],
        count: (data || []).length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getCheckoutDetails(checkoutId: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("server_checkouts")
        .select("*")
        .eq("id", checkoutId)
        .eq("user_id", this.userId)
        .single();

      if (error) throw error;

      if (!data) {
        return {
          success: false,
          error: "Checkout not found",
        };
      }

      // Format the response nicely
      const checkout = data;
      let summary = `**Server Checkout - ${new Date(checkout.checkout_date).toLocaleDateString()}**\n\n`;
      
      if (checkout.section) {
        summary += `📍 **Section:** ${checkout.section}\n`;
      }
      if (checkout.gross_sales) {
        summary += `💵 **Gross Sales:** $${checkout.gross_sales.toFixed(2)}\n`;
      }
      if (checkout.net_sales) {
        summary += `💰 **Net Sales:** $${checkout.net_sales.toFixed(2)}\n`;
      }
      if (checkout.table_count) {
        summary += `🪑 **Tables:** ${checkout.table_count}\n`;
      }
      if (checkout.guest_count || checkout.covers) {
        summary += `👥 **Covers:** ${checkout.covers || checkout.guest_count}\n`;
      }
      
      summary += `\n**Tips:**\n`;
      if (checkout.credit_card_tips) {
        summary += `💳 Credit Tips: $${checkout.credit_card_tips.toFixed(2)}\n`;
      }
      if (checkout.cash_tips) {
        summary += `💵 Cash Tips: $${checkout.cash_tips.toFixed(2)}\n`;
      }
      if (checkout.total_tips_before_tipshare) {
        summary += `💰 Total Before Tipshare: $${checkout.total_tips_before_tipshare.toFixed(2)}\n`;
      }
      if (checkout.tip_share) {
        summary += `🤝 Tipshare: -$${checkout.tip_share.toFixed(2)}\n`;
      }
      if (checkout.net_tips) {
        summary += `✅ **Net Tips:** $${checkout.net_tips.toFixed(2)}\n`;
      }

      return {
        success: true,
        checkout: data,
        summary,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async linkCheckoutToShift(checkoutId: string, shiftId: string): Promise<any> {
    try {
      // Verify the checkout exists and belongs to user
      const { data: checkout } = await this.supabase
        .from("server_checkouts")
        .select("id")
        .eq("id", checkoutId)
        .eq("user_id", this.userId)
        .single();

      if (!checkout) {
        return {
          success: false,
          error: "Checkout not found or doesn't belong to you",
        };
      }

      // Update the shift with the checkout ID
      const { error } = await this.supabase
        .from("shifts")
        .update({ checkout_id: checkoutId })
        .eq("id", shiftId)
        .eq("user_id", this.userId);

      if (error) throw error;

      return {
        success: true,
        message: "Checkout linked to shift successfully",
        navigationBadges: [
          {
            label: "View Checkouts",
            route: "/checkouts",
            icon: "checkout"
          },
          {
            label: "View on Calendar",
            route: "/calendar",
            icon: "calendar"
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

  async unlinkCheckoutFromShift(shiftId: string): Promise<any> {
    try {
      const { error } = await this.supabase
        .from("shifts")
        .update({ checkout_id: null })
        .eq("id", shiftId)
        .eq("user_id", this.userId);

      if (error) throw error;

      return {
        success: true,
        message: "Checkout unlinked from shift successfully",
        navigationBadges: [
          {
            label: "View Checkouts",
            route: "/checkouts",
            icon: "checkout"
          },
          {
            label: "View on Calendar",
            route: "/calendar",
            icon: "calendar"
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

  async editCheckout(checkoutId: string, updates: any): Promise<any> {
    try {
      // Verify the checkout exists and belongs to user
      const { data: checkout } = await this.supabase
        .from("server_checkouts")
        .select("id")
        .eq("id", checkoutId)
        .eq("user_id", this.userId)
        .single();

      if (!checkout) {
        return {
          success: false,
          error: "Checkout not found or doesn't belong to you",
        };
      }

      const { data, error } = await this.supabase
        .from("server_checkouts")
        .update(updates)
        .eq("id", checkoutId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        message: "Checkout updated successfully",
        checkout: data,
        navigationBadges: [
          {
            label: "View Checkouts",
            route: "/checkouts",
            icon: "checkout"
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

  async deleteCheckout(checkoutId: string, confirmed: boolean): Promise<any> {
    if (!confirmed) {
      // Return preview of what will be deleted
      const { data: checkout } = await this.supabase
        .from("server_checkouts")
        .select("checkout_date, net_tips")
        .eq("id", checkoutId)
        .eq("user_id", this.userId)
        .single();

      if (!checkout) {
        return {
          success: false,
          error: "Checkout not found",
        };
      }

      return {
        success: false,
        requiresConfirmation: true,
        message: `Are you sure you want to delete the checkout from ${new Date(checkout.checkout_date).toLocaleDateString()} ($${checkout.net_tips?.toFixed(2) || '0.00'} tips)? This cannot be undone.`,
        checkout,
      };
    }

    try {
      // First, unlink any shifts associated with this checkout
      await this.supabase
        .from("shifts")
        .update({ checkout_id: null })
        .eq("checkout_id", checkoutId)
        .eq("user_id", this.userId);

      // Delete the checkout
      const { error } = await this.supabase
        .from("server_checkouts")
        .delete()
        .eq("id", checkoutId)
        .eq("user_id", this.userId);

      if (error) throw error;

      return {
        success: true,
        message: "Checkout deleted successfully",
        navigationBadges: [
          {
            label: "View Checkouts",
            route: "/checkouts",
            icon: "checkout"
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

  async bulkDeleteCheckouts(confirmed: boolean): Promise<any> {
    try {
      if (!confirmed) {
        return {
          success: false,
          needsConfirmation: true,
          message: "Are you sure you want to delete ALL checkouts? This cannot be undone.",
        };
      }

      const { data: checkouts, error: fetchError } = await this.supabase
        .from("server_checkouts")
        .select("*")
        .eq("user_id", this.userId);

      if (fetchError) throw fetchError;

      if (!checkouts || checkouts.length === 0) {
        return {
          success: true,
          count: 0,
          message: "No checkouts to delete",
        };
      }

      // Unlink all shifts
      await this.supabase
        .from("shifts")
        .update({ checkout_id: null })
        .eq("user_id", this.userId);

      // Delete all checkouts
      const { error: deleteError } = await this.supabase
        .from("server_checkouts")
        .delete()
        .eq("user_id", this.userId);

      if (deleteError) throw deleteError;

      return {
        success: true,
        count: checkouts.length,
        message: `✅ Deleted ${checkouts.length} checkout(s)`,
        navigationBadges: [
          {
            label: "View Checkouts",
            route: "/checkouts",
            icon: "checkout"
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

  async getCheckoutStats(filters?: {
    startDate?: string;
    endDate?: string;
    jobId?: string;
  }): Promise<any> {
    try {
      const result = await this.getCheckouts(filters);
      
      if (!result.success) return result;

      const checkouts = result.checkouts;

      if (checkouts.length === 0) {
        return {
          success: true,
          stats: {
            totalCheckouts: 0,
            totalTips: 0,
            avgTips: 0,
            totalSales: 0,
            avgSales: 0,
            totalTipshare: 0,
            avgTipshare: 0,
          },
        };
      }

      const totalTips = checkouts.reduce((sum: number, c: any) => sum + (c.net_tips || 0), 0);
      const totalSales = checkouts.reduce((sum: number, c: any) => sum + (c.net_sales || c.gross_sales || 0), 0);
      const totalTipshare = checkouts.reduce((sum: number, c: any) => sum + (c.tip_share || 0), 0);

      return {
        success: true,
        stats: {
          totalCheckouts: checkouts.length,
          totalTips,
          avgTips: totalTips / checkouts.length,
          totalSales,
          avgSales: totalSales / checkouts.length,
          totalTipshare,
          avgTipshare: totalTipshare / checkouts.length,
        },
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async compareCheckouts(checkout1Id: string, checkout2Id: string): Promise<any> {
    try {
      const [result1, result2] = await Promise.all([
        this.getCheckoutDetails(checkout1Id),
        this.getCheckoutDetails(checkout2Id),
      ]);

      if (!result1.success || !result2.success) {
        return {
          success: false,
          error: "One or both checkouts not found",
        };
      }

      const c1 = result1.checkout;
      const c2 = result2.checkout;

      const comparison = {
        date1: c1.checkout_date,
        date2: c2.checkout_date,
        tipsDiff: (c1.net_tips || 0) - (c2.net_tips || 0),
        salesDiff: (c1.net_sales || c1.gross_sales || 0) - (c2.net_sales || c2.gross_sales || 0),
        tipShareDiff: (c1.tip_share || 0) - (c2.tip_share || 0),
        tableDiff: (c1.table_count || 0) - (c2.table_count || 0),
        coversDiff: (c1.covers || c1.guest_count || 0) - (c2.covers || c2.guest_count || 0),
      };

      return {
        success: true,
        checkout1: c1,
        checkout2: c2,
        comparison,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getTipshareBreakdown(checkoutId: string): Promise<any> {
    try {
      const { data: checkout, error } = await this.supabase
        .from("server_checkouts")
        .select("credit_card_tips, cash_tips, total_tips_before_tipshare, tip_share, net_tips, tipout_amount, tipout_to")
        .eq("id", checkoutId)
        .eq("user_id", this.userId)
        .single();

      if (error) throw error;

      if (!checkout) {
        return {
          success: false,
          error: "Checkout not found",
        };
      }

      const breakdown = {
        creditTips: checkout.credit_card_tips || 0,
        cashTips: checkout.cash_tips || 0,
        totalBeforeTipshare: checkout.total_tips_before_tipshare || 0,
        tipshare: checkout.tip_share || 0,
        tipoutAmount: checkout.tipout_amount || 0,
        tipoutTo: checkout.tipout_to || "",
        netTips: checkout.net_tips || 0,
      };

      return {
        success: true,
        breakdown,
        summary: `Total tips: $${breakdown.totalBeforeTipshare.toFixed(2)} → Tipshare: -$${breakdown.tipshare.toFixed(2)} → Net: $${breakdown.netTips.toFixed(2)}`,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getSectionStats(section: string, filters?: { startDate?: string; endDate?: string }): Promise<any> {
    try {
      let query = this.supabase
        .from("server_checkouts")
        .select("*")
        .eq("user_id", this.userId)
        .ilike("section", `%${section}%`);

      if (filters?.startDate) {
        query = query.gte("checkout_date", filters.startDate);
      }
      if (filters?.endDate) {
        query = query.lte("checkout_date", filters.endDate);
      }

      const { data, error } = await query;

      if (error) throw error;

      const checkouts = data || [];

      if (checkouts.length === 0) {
        return {
          success: true,
          section,
          stats: {
            totalCheckouts: 0,
            totalTips: 0,
            avgTips: 0,
          },
        };
      }

      const totalTips = checkouts.reduce((sum: number, c: any) => sum + (c.net_tips || 0), 0);

      return {
        success: true,
        section,
        stats: {
          totalCheckouts: checkouts.length,
          totalTips,
          avgTips: totalTips / checkouts.length,
        },
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }
}
