// @ts-nocheck
// Invoice Executor - Handles all invoice/income tracking operations for freelancers
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class InvoiceExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  // ============================================
  // READ OPERATIONS
  // ============================================

  async getInvoices(filters?: {
    startDate?: string;
    endDate?: string;
    client?: string;
    status?: string;
    minAmount?: number;
    maxAmount?: number;
  }): Promise<any> {
    try {
      let query = this.supabase
        .from("invoices")
        .select("*")
        .eq("user_id", this.userId);

      if (filters?.startDate) {
        query = query.gte("invoice_date", filters.startDate);
      }
      if (filters?.endDate) {
        query = query.lte("invoice_date", filters.endDate);
      }
      if (filters?.client) {
        query = query.ilike("client_name", `%${filters.client}%`);
      }
      if (filters?.status) {
        query = query.eq("status", filters.status);
      }

      query = query.order("invoice_date", { ascending: false });

      const { data, error } = await query;

      if (error) throw error;

      let invoices = data || [];

      // Apply amount filters in memory
      if (filters?.minAmount) {
        invoices = invoices.filter((i: any) => (i.total_amount || 0) >= filters.minAmount!);
      }
      if (filters?.maxAmount) {
        invoices = invoices.filter((i: any) => (i.total_amount || 0) <= filters.maxAmount!);
      }

      return {
        success: true,
        invoices,
        count: invoices.length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async searchInvoices(searchTerm: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("invoices")
        .select("*")
        .eq("user_id", this.userId)
        .or(`client_name.ilike.%${searchTerm}%,invoice_number.ilike.%${searchTerm}%`)
        .order("invoice_date", { ascending: false });

      if (error) throw error;

      return {
        success: true,
        invoices: data || [],
        count: (data || []).length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getInvoiceDetails(invoiceId: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("invoices")
        .select("*")
        .eq("id", invoiceId)
        .eq("user_id", this.userId)
        .single();

      if (error) throw error;

      if (!data) {
        return {
          success: false,
          error: "Invoice not found",
        };
      }

      const invoice = data;
      let summary = `**Invoice ${invoice.invoice_number || invoice.id.substring(0, 8)}**\n\n`;
      
      summary += `👤 **Client:** ${invoice.client_name}\n`;
      summary += `📅 **Date:** ${new Date(invoice.invoice_date).toLocaleDateString()}\n`;
      
      if (invoice.due_date) {
        summary += `⏰ **Due:** ${new Date(invoice.due_date).toLocaleDateString()}\n`;
      }
      
      summary += `💰 **Total:** $${invoice.total_amount.toFixed(2)}\n`;
      summary += `💵 **Paid:** $${invoice.amount_paid.toFixed(2)}\n`;
      
      if (invoice.balance_due) {
        summary += `📊 **Balance:** $${invoice.balance_due.toFixed(2)}\n`;
      }
      
      summary += `📌 **Status:** ${invoice.status.toUpperCase()}\n`;
      
      if (invoice.paid_date) {
        summary += `✅ **Paid On:** ${new Date(invoice.paid_date).toLocaleDateString()}\n`;
      }
      
      if (invoice.quickbooks_synced) {
        summary += `📊 **QuickBooks:** Synced\n`;
      }

      return {
        success: true,
        invoice: data,
        summary,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getUnpaidInvoices(): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("invoices")
        .select("*")
        .eq("user_id", this.userId)
        .neq("status", "paid")
        .order("due_date", { ascending: true });

      if (error) throw error;

      const invoices = data || [];
      const totalOwed = invoices.reduce((sum: number, i: any) => sum + (i.balance_due || i.total_amount || 0), 0);

      return {
        success: true,
        invoices,
        count: invoices.length,
        totalOwed,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getOverdueInvoices(): Promise<any> {
    try {
      const today = new Date().toISOString().split("T")[0];
      
      const { data, error } = await this.supabase
        .from("invoices")
        .select("*")
        .eq("user_id", this.userId)
        .neq("status", "paid")
        .lt("due_date", today)
        .order("due_date", { ascending: true });

      if (error) throw error;

      const invoices = data || [];
      const totalOverdue = invoices.reduce((sum: number, i: any) => sum + (i.balance_due || i.total_amount || 0), 0);

      return {
        success: true,
        invoices,
        count: invoices.length,
        totalOverdue,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getTotalReceivables(): Promise<any> {
    try {
      const result = await this.getUnpaidInvoices();
      
      if (!result.success) return result;

      return {
        success: true,
        totalReceivables: result.totalOwed,
        invoiceCount: result.count,
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

  async markInvoicePaid(invoiceId: string, amountPaid: number, paidDate?: string): Promise<any> {
    try {
      const { data: invoice } = await this.supabase
        .from("invoices")
        .select("total_amount, amount_paid")
        .eq("id", invoiceId)
        .eq("user_id", this.userId)
        .single();

      if (!invoice) {
        return {
          success: false,
          error: "Invoice not found",
        };
      }

      const newAmountPaid = (invoice.amount_paid || 0) + amountPaid;
      const balanceDue = invoice.total_amount - newAmountPaid;
      const status = balanceDue <= 0 ? "paid" : "partial";
      
      const updates: any = {
        amount_paid: newAmountPaid,
        balance_due: balanceDue,
        status,
      };

      if (status === "paid") {
        updates.paid_date = paidDate || new Date().toISOString().split("T")[0];
      }

      const { data, error } = await this.supabase
        .from("invoices")
        .update(updates)
        .eq("id", invoiceId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        message: status === "paid" ? "Invoice marked as paid" : "Partial payment recorded",
        invoice: data,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async markInvoiceOverdue(invoiceId: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("invoices")
        .update({ status: "overdue" })
        .eq("id", invoiceId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        message: "Invoice marked as overdue",
        invoice: data,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async linkInvoiceToShift(invoiceId: string, shiftId: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("invoices")
        .update({ shift_id: shiftId })
        .eq("id", invoiceId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        message: "Invoice linked to shift successfully",
        invoice: data,
        navigationBadges: [
          {
            label: "View Invoices",
            route: "/invoices",
            icon: "invoice"
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

  async editInvoice(invoiceId: string, updates: any): Promise<any> {
    try {
      const { data: invoice } = await this.supabase
        .from("invoices")
        .select("id, shift_id")
        .eq("id", invoiceId)
        .eq("user_id", this.userId)
        .single();

      if (!invoice) {
        return {
          success: false,
          error: "Invoice not found or doesn't belong to you",
        };
      }

      const { data, error } = await this.supabase
        .from("invoices")
        .update(updates)
        .eq("id", invoiceId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      // Build navigation badges - always include Invoices, add Calendar if linked to shift
      const navigationBadges: any[] = [
        {
          label: "View Invoices",
          route: "/invoices",
          icon: "invoice"
        }
      ];
      
      if (data.shift_id) {
        navigationBadges.push({
          label: "View on Calendar",
          route: "/calendar",
          icon: "calendar"
        });
      }

      return {
        success: true,
        message: "Invoice updated successfully",
        invoice: data,
        navigationBadges
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async deleteInvoice(invoiceId: string, confirmed: boolean): Promise<any> {
    if (!confirmed) {
      const { data: invoice } = await this.supabase
        .from("invoices")
        .select("client_name, invoice_date, total_amount, invoice_number")
        .eq("id", invoiceId)
        .eq("user_id", this.userId)
        .single();

      if (!invoice) {
        return {
          success: false,
          error: "Invoice not found",
        };
      }

      return {
        success: false,
        requiresConfirmation: true,
        message: `Are you sure you want to delete invoice ${invoice.invoice_number || invoice.id.substring(0, 8)} for ${invoice.client_name} ($${invoice.total_amount?.toFixed(2) || '0.00'})? This cannot be undone.`,
        invoice,
      };
    }

    try {
      // Get invoice to check if linked to shift before deleting
      const { data: invoice } = await this.supabase
        .from("invoices")
        .select("shift_id")
        .eq("id", invoiceId)
        .eq("user_id", this.userId)
        .single();

      const wasLinkedToShift = invoice?.shift_id;

      const { error } = await this.supabase
        .from("invoices")
        .delete()
        .eq("id", invoiceId)
        .eq("user_id", this.userId);

      if (error) throw error;

      // Build navigation badges - always include Invoices, add Calendar if was linked to shift
      const navigationBadges: any[] = [
        {
          label: "View Invoices",
          route: "/invoices",
          icon: "invoice"
        }
      ];
      
      if (wasLinkedToShift) {
        navigationBadges.push({
          label: "View on Calendar",
          route: "/calendar",
          icon: "calendar"
        });
      }

      return {
        success: true,
        message: "Invoice deleted successfully",
        navigationBadges
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async bulkDeleteInvoices(confirmed: boolean): Promise<any> {
    try {
      if (!confirmed) {
        return {
          success: false,
          needsConfirmation: true,
          message: "Are you sure you want to delete ALL invoices? This cannot be undone.",
        };
      }

      const { data: invoices, error: fetchError } = await this.supabase
        .from("invoices")
        .select("*")
        .eq("user_id", this.userId);

      if (fetchError) throw fetchError;

      if (!invoices || invoices.length === 0) {
        return {
          success: true,
          count: 0,
          message: "No invoices to delete",
        };
      }

      const { error: deleteError } = await this.supabase
        .from("invoices")
        .delete()
        .eq("user_id", this.userId);

      if (deleteError) throw deleteError;

      return {
        success: true,
        count: invoices.length,
        message: `✅ Deleted ${invoices.length} invoice(s)`,
        navigationBadges: [
          {
            label: "View Invoices",
            route: "/invoices",
            icon: "invoice"
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
