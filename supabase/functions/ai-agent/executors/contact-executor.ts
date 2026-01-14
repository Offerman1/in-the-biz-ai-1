// @ts-nocheck
// Contact Executor - Manages event contacts (vendors, staff, etc.)
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class ContactExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  async execute(functionName: string, args: any): Promise<any> {
    switch (functionName) {
      case "add_event_contact":
        return await this.addEventContact(args);
      case "edit_event_contact":
        return await this.editEventContact(args);
      case "delete_event_contact":
        return await this.deleteEventContact(args);
      case "search_contacts":
        return await this.searchContacts(args);
      case "get_contacts_for_shift":
        return await this.getContactsForShift(args);
      case "set_contact_favorite":
        return await this.setContactFavorite(args);
      case "link_contact_to_shift":
        return await this.linkContactToShift(args);
      case "link_contacts_to_beo_shift":
        return await this.linkContactsToBEOShift(args);
      default:
        throw new Error(`Unknown contact function: ${functionName}`);
    }
  }

  private async addEventContact(args: any) {
    const {
      name,
      role = "custom",
      customRole,
      company,
      phone,
      email,
      website,
      notes,
      shiftId,
      instagram,
      tiktok,
      facebook,
      twitter,
      linkedin,
      youtube,
      snapchat,
      pinterest,
    } = args;

    if (!name) {
      throw new Error("Contact name is required");
    }

    const insertData: any = {
      user_id: this.userId,
      name: name,
      role: role,
    };

    // Add optional fields
    if (customRole) insertData.custom_role = customRole;
    if (company) insertData.company = company;
    if (phone) insertData.phone = phone;
    if (email) insertData.email = email;
    if (website) insertData.website = website;
    if (notes) insertData.notes = notes;
    if (shiftId) insertData.shift_id = shiftId;
    if (instagram) insertData.instagram = instagram;
    if (tiktok) insertData.tiktok = tiktok;
    if (facebook) insertData.facebook = facebook;
    if (twitter) insertData.twitter = twitter;
    if (linkedin) insertData.linkedin = linkedin;
    if (youtube) insertData.youtube = youtube;
    if (snapchat) insertData.snapchat = snapchat;
    if (pinterest) insertData.pinterest = pinterest;

    const { data, error } = await this.supabase
      .from("event_contacts")
      .insert(insertData)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      contact: data,
      message: `✅ Added ${name}${company ? ` from ${company}` : ""} as ${role === "custom" ? customRole || "contact" : role.replace(/_/g, " ")}`,
    };
  }

  private async editEventContact(args: any) {
    const { contactId, name, updates } = args;

    // Find contact by ID or name
    let contact;
    if (contactId) {
      const { data } = await this.supabase
        .from("event_contacts")
        .select("*")
        .eq("id", contactId)
        .eq("user_id", this.userId)
        .single();
      contact = data;
    } else if (name) {
      const { data } = await this.supabase
        .from("event_contacts")
        .select("*")
        .eq("user_id", this.userId)
        .ilike("name", `%${name}%`)
        .single();
      contact = data;
    }

    if (!contact) {
      throw new Error(`Contact not found: ${name || contactId}`);
    }

    // Build updates object (camelCase to snake_case)
    const dbUpdates: any = {};
    if (updates.name !== undefined) dbUpdates.name = updates.name;
    if (updates.role !== undefined) dbUpdates.role = updates.role;
    if (updates.customRole !== undefined) dbUpdates.custom_role = updates.customRole;
    if (updates.company !== undefined) dbUpdates.company = updates.company;
    if (updates.phone !== undefined) dbUpdates.phone = updates.phone;
    if (updates.email !== undefined) dbUpdates.email = updates.email;
    if (updates.website !== undefined) dbUpdates.website = updates.website;
    if (updates.notes !== undefined) dbUpdates.notes = updates.notes;
    if (updates.shiftId !== undefined) dbUpdates.shift_id = updates.shiftId;
    if (updates.instagram !== undefined) dbUpdates.instagram = updates.instagram;
    if (updates.tiktok !== undefined) dbUpdates.tiktok = updates.tiktok;
    if (updates.facebook !== undefined) dbUpdates.facebook = updates.facebook;
    if (updates.twitter !== undefined) dbUpdates.twitter = updates.twitter;
    if (updates.linkedin !== undefined) dbUpdates.linkedin = updates.linkedin;
    if (updates.youtube !== undefined) dbUpdates.youtube = updates.youtube;
    if (updates.snapchat !== undefined) dbUpdates.snapchat = updates.snapchat;
    if (updates.pinterest !== undefined) dbUpdates.pinterest = updates.pinterest;

    const { data, error } = await this.supabase
      .from("event_contacts")
      .update(dbUpdates)
      .eq("id", contact.id)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      contact: data,
      message: `✅ Updated ${contact.name}'s info`,
    };
  }

  private async deleteEventContact(args: any) {
    const { contactId, name, confirmed } = args;

    if (!confirmed) {
      return {
        needsConfirmation: true,
        message: `Are you sure you want to delete this contact?`,
      };
    }

    // Find contact
    let contact;
    if (contactId) {
      const { data } = await this.supabase
        .from("event_contacts")
        .select("*")
        .eq("id", contactId)
        .eq("user_id", this.userId)
        .single();
      contact = data;
    } else if (name) {
      const { data } = await this.supabase
        .from("event_contacts")
        .select("*")
        .eq("user_id", this.userId)
        .ilike("name", `%${name}%`)
        .single();
      contact = data;
    }

    if (!contact) {
      throw new Error(`Contact not found: ${name || contactId}`);
    }

    const { error } = await this.supabase
      .from("event_contacts")
      .delete()
      .eq("id", contact.id);

    if (error) throw error;

    return {
      success: true,
      message: `✅ Deleted ${contact.name}`,
    };
  }

  private async searchContacts(args: any) {
    const { query, role, company } = args;

    let queryBuilder = this.supabase
      .from("event_contacts")
      .select("*")
      .eq("user_id", this.userId);

    if (query) {
      queryBuilder = queryBuilder.or(
        `name.ilike.%${query}%,company.ilike.%${query}%,notes.ilike.%${query}%`
      );
    }

    if (role) {
      queryBuilder = queryBuilder.eq("role", role);
    }

    if (company) {
      queryBuilder = queryBuilder.ilike("company", `%${company}%`);
    }

    const { data, error } = await queryBuilder.order("name");

    if (error) throw error;

    return {
      success: true,
      contacts: data || [],
      count: data?.length || 0,
      message: `Found ${data?.length || 0} contacts`,
    };
  }

  private async getContactsForShift(args: any) {
    const { shiftId, date } = args;

    let finalShiftId = shiftId;

    // If date provided instead of shiftId, find the shift
    if (!finalShiftId && date) {
      const { data: shift } = await this.supabase
        .from("shifts")
        .select("id")
        .eq("user_id", this.userId)
        .eq("date", date)
        .single();

      if (shift) finalShiftId = shift.id;
    }

    if (!finalShiftId) {
      throw new Error("Could not find shift");
    }

    const { data, error } = await this.supabase
      .from("event_contacts")
      .select("*")
      .eq("shift_id", finalShiftId)
      .order("role");

    if (error) throw error;

    return {
      success: true,
      contacts: data || [],
      count: data?.length || 0,
      message: `Found ${data?.length || 0} contacts for this event`,
    };
  }

  private async setContactFavorite(args: any) {
    const { contactId, name, isFavorite } = args;

    // Find contact
    let contact;
    if (contactId) {
      const { data } = await this.supabase
        .from("event_contacts")
        .select("*")
        .eq("id", contactId)
        .eq("user_id", this.userId)
        .single();
      contact = data;
    } else if (name) {
      const { data } = await this.supabase
        .from("event_contacts")
        .select("*")
        .eq("user_id", this.userId)
        .ilike("name", `%${name}%`)
        .single();
      contact = data;
    }

    if (!contact) {
      throw new Error(`Contact not found: ${name || contactId}`);
    }

    const { data, error } = await this.supabase
      .from("event_contacts")
      .update({ is_favorite: isFavorite })
      .eq("id", contact.id)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      contact: data,
      message: isFavorite
        ? `✅ Added ${contact.name} to favorites`
        : `Removed ${contact.name} from favorites`,
    };
  }

  private async linkContactToShift(args: any) {
    const { contactId, contactName, shiftId } = args;

    // Find contact
    let contact;
    if (contactId) {
      const { data } = await this.supabase
        .from("event_contacts")
        .select("*")
        .eq("id", contactId)
        .eq("user_id", this.userId)
        .single();
      contact = data;
    } else if (contactName) {
      const { data } = await this.supabase
        .from("event_contacts")
        .select("*")
        .eq("user_id", this.userId)
        .ilike("name", `%${contactName}%`)
        .single();
      contact = data;
    }

    if (!contact) {
      throw new Error(`Contact not found: ${contactName || contactId}`);
    }

    // Verify shift exists
    const { data: shift } = await this.supabase
      .from("shifts")
      .select("id")
      .eq("id", shiftId)
      .eq("user_id", this.userId)
      .single();

    if (!shift) {
      throw new Error("Shift not found");
    }

    // Link contact to shift
    const { data, error } = await this.supabase
      .from("event_contacts")
      .update({ shift_id: shiftId })
      .eq("id", contact.id)
      .select()
      .single();

    if (error) throw error;

    return {
      success: true,
      message: `✅ Linked ${contact.name} to shift`,
      contact: data,
    };
  }

  private async linkContactsToBEOShift(args: any) {
    const { beoEventId, contactIds, contactNames } = args;

    // First, find the shift that's linked to this BEO
    const { data: shift } = await this.supabase
      .from("shifts")
      .select("id")
      .eq("beo_event_id", beoEventId)
      .eq("user_id", this.userId)
      .single();

    if (!shift) {
      throw new Error("No shift found linked to this BEO event. Link the BEO to a shift first.");
    }

    const linkedContacts = [];
    const errors = [];

    // Process contact IDs
    if (contactIds && Array.isArray(contactIds)) {
      for (const contactId of contactIds) {
        try {
          const { data, error } = await this.supabase
            .from("event_contacts")
            .update({ shift_id: shift.id })
            .eq("id", contactId)
            .eq("user_id", this.userId)
            .select()
            .single();

          if (error) throw error;
          linkedContacts.push(data.name);
        } catch (e: any) {
          errors.push(`Failed to link contact ID ${contactId}: ${e.message}`);
        }
      }
    }

    // Process contact names
    if (contactNames && Array.isArray(contactNames)) {
      for (const name of contactNames) {
        try {
          const { data: contact } = await this.supabase
            .from("event_contacts")
            .select("*")
            .eq("user_id", this.userId)
            .ilike("name", `%${name}%`)
            .single();

          if (!contact) {
            errors.push(`Contact not found: ${name}`);
            continue;
          }

          const { data, error } = await this.supabase
            .from("event_contacts")
            .update({ shift_id: shift.id })
            .eq("id", contact.id)
            .select()
            .single();

          if (error) throw error;
          linkedContacts.push(data.name);
        } catch (e: any) {
          errors.push(`Failed to link ${name}: ${e.message}`);
        }
      }
    }

    return {
      success: true,
      message: `✅ Linked ${linkedContacts.length} contact(s) to BEO shift`,
      linkedContacts,
      errors: errors.length > 0 ? errors : undefined,
    };
  }
}
