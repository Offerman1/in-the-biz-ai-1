// @ts-nocheck
// BEO Executor - Handles all BEO (Banquet Event Order) operations
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class BEOExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  // ============================================
  // READ OPERATIONS
  // ============================================

  async getBEOEvents(filters?: { 
    upcoming?: boolean; 
    past?: boolean; 
    startDate?: string; 
    endDate?: string;
    venue?: string;
    clientName?: string;
  }): Promise<any> {
    try {
      let query = this.supabase
        .from("beo_events")
        .select("*")
        .eq("user_id", this.userId);

      // Apply filters
      if (filters?.upcoming) {
        const today = new Date().toISOString().split("T")[0];
        query = query.gte("event_date", today);
      }
      if (filters?.past) {
        const today = new Date().toISOString().split("T")[0];
        query = query.lt("event_date", today);
      }
      if (filters?.startDate) {
        query = query.gte("event_date", filters.startDate);
      }
      if (filters?.endDate) {
        query = query.lte("event_date", filters.endDate);
      }
      if (filters?.venue) {
        query = query.ilike("venue_name", `%${filters.venue}%`);
      }
      if (filters?.clientName) {
        query = query.or(`primary_contact_name.ilike.%${filters.clientName}%,account_name.ilike.%${filters.clientName}%`);
      }

      query = query.order("event_date", { ascending: true });

      const { data, error } = await query;

      if (error) throw error;

      return {
        success: true,
        events: data || [],
        count: (data || []).length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async searchBEOEvents(searchTerm: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("beo_events")
        .select("*")
        .eq("user_id", this.userId)
        .or(`event_name.ilike.%${searchTerm}%,venue_name.ilike.%${searchTerm}%,primary_contact_name.ilike.%${searchTerm}%,account_name.ilike.%${searchTerm}%`)
        .order("event_date", { ascending: true });

      if (error) throw error;

      return {
        success: true,
        events: data || [],
        count: (data || []).length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getBEODetails(eventId: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("beo_events")
        .select("*")
        .eq("id", eventId)
        .eq("user_id", this.userId)
        .single();

      if (error) throw error;

      if (!data) {
        return {
          success: false,
          error: "BEO event not found",
        };
      }

      // Format the response nicely
      const event = data;
      let summary = `**${event.event_name}**\n\n`;
      
      if (event.event_date) {
        summary += `📅 **Date:** ${new Date(event.event_date).toLocaleDateString()}\n`;
      }
      if (event.venue_name) {
        summary += `🏢 **Venue:** ${event.venue_name}\n`;
      }
      if (event.guest_count_expected || event.guest_count_confirmed) {
        summary += `👥 **Guests:** ${event.guest_count_confirmed || event.guest_count_expected} expected\n`;
      }
      if (event.primary_contact_name) {
        summary += `📞 **Contact:** ${event.primary_contact_name}`;
        if (event.primary_contact_phone) summary += ` | ${event.primary_contact_phone}`;
        if (event.primary_contact_email) summary += ` | ${event.primary_contact_email}`;
        summary += `\n`;
      }
      if (event.grand_total) {
        summary += `💰 **Total:** $${event.grand_total.toFixed(2)}\n`;
      }
      if (event.event_start_time || event.event_end_time) {
        summary += `⏰ **Time:** ${event.event_start_time || 'TBD'} - ${event.event_end_time || 'TBD'}\n`;
      }

      return {
        success: true,
        event: data,
        summary,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getUpcomingBEOs(daysAhead: number = 30): Promise<any> {
    try {
      const today = new Date().toISOString().split("T")[0];
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + daysAhead);
      const futureDateStr = futureDate.toISOString().split("T")[0];

      const { data, error } = await this.supabase
        .from("beo_events")
        .select("*")
        .eq("user_id", this.userId)
        .gte("event_date", today)
        .lte("event_date", futureDateStr)
        .order("event_date", { ascending: true });

      if (error) throw error;

      return {
        success: true,
        events: data || [],
        count: (data || []).length,
        daysAhead,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getBEOsByVenue(venueName: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("beo_events")
        .select("*")
        .eq("user_id", this.userId)
        .ilike("venue_name", `%${venueName}%`)
        .order("event_date", { ascending: false });

      if (error) throw error;

      return {
        success: true,
        events: data || [],
        count: (data || []).length,
        venue: venueName,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getBEOsByClient(clientName: string): Promise<any> {
    try {
      const { data, error } = await this.supabase
        .from("beo_events")
        .select("*")
        .eq("user_id", this.userId)
        .or(`primary_contact_name.ilike.%${clientName}%,account_name.ilike.%${clientName}%`)
        .order("event_date", { ascending: false });

      if (error) throw error;

      return {
        success: true,
        events: data || [],
        count: (data || []).length,
        client: clientName,
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

  async linkBEOToShift(eventId: string, shiftId: string): Promise<any> {
    try {
      // Verify the BEO exists and belongs to user
      const { data: event } = await this.supabase
        .from("beo_events")
        .select("id")
        .eq("id", eventId)
        .eq("user_id", this.userId)
        .single();

      if (!event) {
        return {
          success: false,
          error: "BEO event not found or doesn't belong to you",
        };
      }

      // Update the shift with the BEO event ID
      const { error } = await this.supabase
        .from("shifts")
        .update({ beo_event_id: eventId })
        .eq("id", shiftId)
        .eq("user_id", this.userId);

      if (error) throw error;

      return {
        success: true,
        message: "BEO linked to shift successfully",
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async unlinkBEOFromShift(shiftId: string): Promise<any> {
    try {
      const { error } = await this.supabase
        .from("shifts")
        .update({ beo_event_id: null })
        .eq("id", shiftId)
        .eq("user_id", this.userId);

      if (error) throw error;

      return {
        success: true,
        message: "BEO unlinked from shift successfully",
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async editBEOEvent(eventId: string, updates: any): Promise<any> {
    try {
      // Verify the BEO exists and belongs to user
      const { data: event } = await this.supabase
        .from("beo_events")
        .select("id")
        .eq("id", eventId)
        .eq("user_id", this.userId)
        .single();

      if (!event) {
        return {
          success: false,
          error: "BEO event not found or doesn't belong to you",
        };
      }

      const { data, error } = await this.supabase
        .from("beo_events")
        .update(updates)
        .eq("id", eventId)
        .eq("user_id", this.userId)
        .select()
        .single();

      if (error) throw error;

      return {
        success: true,
        message: "BEO event updated successfully",
        event: data,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async deleteBEOEvent(eventId: string, confirmed: boolean): Promise<any> {
    if (!confirmed) {
      // Return preview of what will be deleted
      const { data: event } = await this.supabase
        .from("beo_events")
        .select("event_name, event_date")
        .eq("id", eventId)
        .eq("user_id", this.userId)
        .single();

      if (!event) {
        return {
          success: false,
          error: "BEO event not found",
        };
      }

      return {
        success: false,
        requiresConfirmation: true,
        message: `Are you sure you want to delete the BEO for "${event.event_name}" on ${new Date(event.event_date).toLocaleDateString()}? This cannot be undone.`,
        event,
      };
    }

    try {
      // First, unlink any shifts associated with this BEO
      await this.supabase
        .from("shifts")
        .update({ beo_event_id: null })
        .eq("beo_event_id", eventId)
        .eq("user_id", this.userId);

      // Delete the BEO event
      const { error } = await this.supabase
        .from("beo_events")
        .delete()
        .eq("id", eventId)
        .eq("user_id", this.userId);

      if (error) throw error;

      return {
        success: true,
        message: "BEO event deleted successfully",
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async bulkDeleteBEOEvents(confirmed: boolean): Promise<any> {
    try {
      if (!confirmed) {
        return {
          success: false,
          needsConfirmation: true,
          message: "Are you sure you want to delete ALL BEO events? This cannot be undone.",
        };
      }

      // Get all BEO events for preview
      const { data: events, error: fetchError } = await this.supabase
        .from("beo_events")
        .select("*")
        .eq("user_id", this.userId);

      if (fetchError) throw fetchError;

      if (!events || events.length === 0) {
        return {
          success: true,
          count: 0,
          message: "No BEO events to delete",
        };
      }

      // Delete all BEO events
      const { error: deleteError } = await this.supabase
        .from("beo_events")
        .delete()
        .eq("user_id", this.userId);

      if (deleteError) throw deleteError;

      return {
        success: true,
        count: events.length,
        message: `✅ Deleted ${events.length} BEO event(s)`,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getBEOContacts(eventId: string): Promise<any> {
    try {
      const { data: event, error } = await this.supabase
        .from("beo_events")
        .select("primary_contact_name, primary_contact_phone, primary_contact_email, sales_manager_name, sales_manager_phone, sales_manager_email, catering_manager_name, catering_manager_phone")
        .eq("id", eventId)
        .eq("user_id", this.userId)
        .single();

      if (error) throw error;

      if (!event) {
        return {
          success: false,
          error: "BEO event not found",
        };
      }

      const contacts = [];

      if (event.primary_contact_name) {
        contacts.push({
          name: event.primary_contact_name,
          phone: event.primary_contact_phone,
          email: event.primary_contact_email,
          role: "Primary Contact",
        });
      }

      if (event.sales_manager_name) {
        contacts.push({
          name: event.sales_manager_name,
          phone: event.sales_manager_phone,
          email: event.sales_manager_email,
          role: "Sales Manager",
        });
      }

      if (event.catering_manager_name) {
        contacts.push({
          name: event.catering_manager_name,
          phone: event.catering_manager_phone,
          email: null,
          role: "Catering Manager",
        });
      }

      return {
        success: true,
        contacts,
        count: contacts.length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getBEOEarnings(eventId: string): Promise<any> {
    try {
      const { data: event, error } = await this.supabase
        .from("beo_events")
        .select("grand_total, commission_percentage, commission_amount")
        .eq("id", eventId)
        .eq("user_id", this.userId)
        .single();

      if (error) throw error;

      if (!event) {
        return {
          success: false,
          error: "BEO event not found",
        };
      }

      const earnings = {
        grandTotal: event.grand_total || 0,
        commissionPercentage: event.commission_percentage || 0,
        commissionAmount: event.commission_amount || 0,
      };

      // If commission amount not stored, calculate it
      if (!earnings.commissionAmount && earnings.grandTotal && earnings.commissionPercentage) {
        earnings.commissionAmount = (earnings.grandTotal * earnings.commissionPercentage) / 100;
      }

      return {
        success: true,
        earnings,
        summary: `Expected earnings: $${earnings.commissionAmount.toFixed(2)} (${earnings.commissionPercentage}% of $${earnings.grandTotal.toFixed(2)})`,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  async getBEOTimeline(eventId: string): Promise<any> {
    try {
      const { data: event, error } = await this.supabase
        .from("beo_events")
        .select("load_in_time, setup_time, guest_arrival_time, event_start_time, event_end_time, breakdown_time, load_out_time")
        .eq("id", eventId)
        .eq("user_id", this.userId)
        .single();

      if (error) throw error;

      if (!event) {
        return {
          success: false,
          error: "BEO event not found",
        };
      }

      const timeline = [];

      if (event.load_in_time) timeline.push({ time: event.load_in_time, activity: "Load In" });
      if (event.setup_time) timeline.push({ time: event.setup_time, activity: "Setup" });
      if (event.guest_arrival_time) timeline.push({ time: event.guest_arrival_time, activity: "Guest Arrival" });
      if (event.event_start_time) timeline.push({ time: event.event_start_time, activity: "Event Start" });
      if (event.event_end_time) timeline.push({ time: event.event_end_time, activity: "Event End" });
      if (event.breakdown_time) timeline.push({ time: event.breakdown_time, activity: "Breakdown" });
      if (event.load_out_time) timeline.push({ time: event.load_out_time, activity: "Load Out" });

      return {
        success: true,
        timeline,
        count: timeline.length,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }
}
