// @ts-nocheck
// Receipt Executor - Handles all receipt/expense tracking operations
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class ReceiptExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  // ============================================
  // READ OPERATIONS
  // ============================================

  async getReceipts(filters?: {
    startDate?: string;
    endDate?: string;
    vendor?: string;
    category?: string;
    minAmount?: number;
    maxAmount?: number;
    deductibleOnly?: boolean;
  }): Promise<any> {
    try {
      let query = this.supabase
        .from("receipts")
        .select("*")
        .eq("user_id", this.userId);

      if (filters?.startDate) {
        query = query.gte("receipt_date", filters.startDate);
      }
      if (filters?.endDate) {
        query = query.lte("receipt_date", filters.endDate);
      }
      if (filters?.vendor) {
        query = query.ilike("vendor_name", `%${filters.vendor}%`);
      }
      if (filters?.category) {
        query = query.eq("expense_category", filters.category);
      }
      if (filters?.deductibleOnly) {
        query = query.eq("is_tax_deductible", true);
      }

      query = query.order("receipt_date", { ascending: false });

      const { data, error } = await query;

      if (error) throw error;

      let receipts = data || [];

      // Apply amount filters in memory
      if (filters?.minAmount) {
        receipts = receipts.filter((r: any) => (r.total_amount || 0) >= filters.minAmount!);
      }
      if (filters?.maxAmount) {
        receipts = receipts.filter((r: any) => (r.total_amount || 0) <= filters.maxAmount!);
      }

      return {
        success: true,
        receipts,
        count: receipts.length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async searchReceipts(searchTerm: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("receipts")
        .select("*")
        .eq("user_id", this.userId)
        .or(`vendor_name.ilike.%${searchTerm}%,expense_category.ilike.%${searchTerm}%,receipt_number.ilike.%${searchTerm}%`)
        .order("receipt_date", { ascending: false });

      if (error) throw error;

      return {
        success: true,
        receipts: data || [],
        count: (data || []).length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getReceiptDetails(receiptId: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("receipts")
        .select("*")
        .eq("id", receiptId)
        .eq("user_id", this.userId)
        .single();

      if (error) throw error;

      if (!data) {
        return {
          success: false,
          error: "Receipt not found",
        };
      }

      const receipt = data;
      let summary = `**Receipt - ${receipt.vendor_name}**\n\n`;
      
      summary += `📅 **Date:** ${new Date(receipt.receipt_date).toLocaleDateString()}\n`;
      summary += `💰 **Amount:** $${receipt.total_amount.toFixed(2)}\n`;
      
      if (receipt.expense_category) {
        summary += `📂 **Category:** ${receipt.expense_category}\n`;
      }
      if (receipt.payment_method) {
        summary += `💳 **Payment:** ${receipt.payment_method}\n`;
      }
      if (receipt.is_tax_deductible) {
        summary += `✅ **Tax Deductible**\n`;
      }
      if (receipt.receipt_number) {
        summary += `🔢 **Receipt #:** ${receipt.receipt_number}\n`;
      }
      if (receipt.quickbooks_synced) {
        summary += `📊 **QuickBooks:** Synced\n`;
      }

      return {
        success: true,
        receipt: data,
        summary,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getExpenseSummary(filters?: {
    startDate?: string;
    endDate?: string;
    category?: string;
  }): Promise<any> {
    try {
      const result = await this.getReceipts(filters);
      
      if (!result.success) return result;

      const receipts = result.receipts;

      if (receipts.length === 0) {
        return {
          success: true,
          summary: {
            totalExpenses: 0,
            totalReceipts: 0,
            avgExpense: 0,
            deductibleTotal: 0,
            byCategory: {},
          },
        };
      }

      const totalExpenses = receipts.reduce((sum: number, r: any) => sum + (r.total_amount || 0), 0);
      const deductibleTotal = receipts
        .filter((r: any) => r.is_tax_deductible)
        .reduce((sum: number, r: any) => sum + (r.total_amount || 0), 0);

      // Group by category
      const byCategory: { [key: string]: { count: number; total: number } } = {};
      receipts.forEach((r: any) => {
        const cat = r.expense_category || "Uncategorized";
        if (!byCategory[cat]) {
          byCategory[cat] = { count: 0, total: 0 };
        }
        byCategory[cat].count++;
        byCategory[cat].total += r.total_amount || 0;
      });

      return {
        success: true,
        summary: {
          totalExpenses,
          totalReceipts: receipts.length,
          avgExpense: totalExpenses / receipts.length,
          deductibleTotal,
          byCategory,
        },
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getDeductibleExpenses(year?: number): Promise<any> {
    try {
      const targetYear = year || new Date().getFullYear();
      
      const result = await this.getReceipts({
        startDate: `${targetYear}-01-01`,
        endDate: `${targetYear}-12-31`,
        deductibleOnly: true,
      });

      if (!result.success) return result;

      const receipts = result.receipts;
      const total = receipts.reduce((sum: number, r: any) => sum + (r.total_amount || 0), 0);

      return {
        success: true,
        year: targetYear,
        count: receipts.length,
        total,
        receipts,
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

  async categorizeReceipt(receiptId: string, category: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("receipts")
        .update({ expense_category: category })
        .eq("id", receiptId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        message: `Receipt categorized as "${category}"`,
        receipt: data,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async markReceiptDeductible(receiptId: string, isDeductible: boolean): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("receipts")
        .update({ is_tax_deductible: isDeductible })
        .eq("id", receiptId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        message: `Receipt marked as ${isDeductible ? 'deductible' : 'not deductible'}`,
        receipt: data,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async linkReceiptToShift(receiptId: string, shiftId: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("receipts")
        .update({ shift_id: shiftId })
        .eq("id", receiptId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        message: "Receipt linked to shift successfully",
        receipt: data,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async editReceipt(receiptId: string, updates: any): Promise<any> {
    try {
      const { data: receipt } = await this.supabase
        .from("receipts")
        .select("id")
        .eq("id", receiptId)
        .eq("user_id", this.userId)
        .single();

      if (!receipt) {
        return {
          success: false,
          error: "Receipt not found or doesn't belong to you",
        };
      }

      const { data, error } = await this.supabase
        .from("receipts")
        .update(updates)
        .eq("id", receiptId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        message: "Receipt updated successfully",
        receipt: data,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async deleteReceipt(receiptId: string, confirmed: boolean): Promise<any> {
    if (!confirmed) {
      const { data: receipt } = await this.supabase
        .from("receipts")
        .select("vendor_name, receipt_date, total_amount")
        .eq("id", receiptId)
        .eq("user_id", this.userId)
        .single();

      if (!receipt) {
        return {
          success: false,
          error: "Receipt not found",
        };
      }

      return {
        success: false,
        requiresConfirmation: true,
        message: `Are you sure you want to delete the receipt from ${receipt.vendor_name} on ${new Date(receipt.receipt_date).toLocaleDateString()} ($${receipt.total_amount?.toFixed(2) || '0.00'})? This cannot be undone.`,
        receipt,
      };
    }

    try {
      const { error } = await this.supabase
        .from("receipts")
        .delete()
        .eq("id", receiptId)
        .eq("user_id", this.userId);

      if (error) throw error;

      return {
        success: true,
        message: "Receipt deleted successfully",
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }
}
