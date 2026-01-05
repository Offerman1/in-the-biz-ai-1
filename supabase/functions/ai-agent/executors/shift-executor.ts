// Shift Executor - Handles all shift-related function calls
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export class ShiftExecutor {
  constructor(private supabase: SupabaseClient, private userId: string) {}

  async execute(functionName: string, args: any): Promise<any> {
    switch (functionName) {
      case "add_shift":
        return await this.addShift(args);
      case "edit_shift":
        return await this.editShift(args);
      case "delete_shift":
        return await this.deleteShift(args);
      case "bulk_edit_shifts":
        return await this.bulkEditShifts(args);
      case "bulk_delete_shifts":
        return await this.bulkDeleteShifts(args);
      case "search_shifts":
        return await this.searchShifts(args);
      case "get_shift_details":
        return await this.getShiftDetails(args);
      case "attach_photo_to_shift":
        return await this.attachPhotoToShift(args);
      case "remove_photo_from_shift":
        return await this.removePhotoFromShift(args);
      case "get_shift_photos":
        return await this.getShiftPhotos(args);
      case "calculate_shift_total":
        return await this.calculateShiftTotal(args);
      case "duplicate_shift":
        return await this.duplicateShift(args);
      default:
        throw new Error(`Unknown shift function: ${functionName}`);
    }
  }

  private async addShift(args: any) {
    const {
      date,
      cashTips = 0,
      creditTips = 0,
      hourlyRate,  // Don't default to 0 - we'll get from job if not provided
      hoursWorked = 0,
      overtimeHours,
      eventName,
      guestCount,
      notes,
      jobId,
      startTime,
      endTime,
      jobType,
      location,
      clientName,
      projectName,
      hostess,
      salesAmount,
      tipoutPercent,
      additionalTipout,
      additionalTipoutNote,
      commission,
      mileage,
      flatRate,
      eventCost,
      // Rideshare & Delivery
      ridesCount,
      deliveriesCount,
      deadMiles,
      fuelCost,
      tollsParking,
      surgeMultiplier,
      acceptanceRate,
      baseFare,
      // Music & Entertainment
      gigType,
      setupHours,
      performanceHours,
      breakdownHours,
      equipmentUsed,
      equipmentRentalCost,
      crewPayment,
      merchSales,
      audienceSize,
      // Artist & Crafts
      piecesCreated,
      piecesSold,
      materialsCost,
      salePrice,
      venueCommissionPercent,
      // Retail/Sales
      itemsSold,
      transactionsCount,
      upsellsCount,
      upsellsAmount,
      returnsCount,
      returnsAmount,
      shrinkAmount,
      department,
      // Salon/Spa
      serviceType,
      servicesCount,
      productSales,
      repeatClientPercent,
      chairRental,
      newClientsCount,
      returningClientsCount,
      walkinCount,
      appointmentCount,
      // Hospitality
      roomType,
      roomsCleaned,
      qualityScore,
      shiftType,
      roomUpgrades,
      guestsCheckedIn,
      carsParked,
      // Healthcare
      patientCount,
      shiftDifferential,
      onCallHours,
      proceduresCount,
      specialization,
      // Fitness
      sessionsCount,
      sessionType,
      classSize,
      retentionRate,
      cancellationsCount,
      packageSales,
      supplementSales,
      // Construction/Trades
      laborCost,
      subcontractorCost,
      squareFootage,
      weatherDelayHours,
      // Freelancer
      revisionsCount,
      clientType,
      expenses,
      billableHours,
      // Restaurant Additional
      tableSection,
      cashSales,
      cardSales,
    } = args;

    // If no jobId provided, try to get the user's default or only job
    let finalJobId = jobId;
    let jobName = null;
    let jobHourlyRate = 0;
    
    // Fetch job info (for hourly rate and name)
    if (finalJobId) {
      // Job ID was provided - fetch its details
      const { data: job } = await this.supabase
        .from("jobs")
        .select("id, name, hourly_rate")
        .eq("id", finalJobId)
        .single();
      
      if (job) {
        jobName = job.name;
        jobHourlyRate = job.hourly_rate || 0;
      }
    } else {
      // No job ID - try to get user's default or only job
      const { data: jobs } = await this.supabase
        .from("jobs")
        .select("id, name, is_default, hourly_rate")
        .eq("user_id", this.userId)
        .eq("is_active", true)
        .is("deleted_at", null)
        .order("is_default", { ascending: false });

      if (jobs && jobs.length === 1) {
        // Only one job - use it automatically
        finalJobId = jobs[0].id;
        jobName = jobs[0].name;
        jobHourlyRate = jobs[0].hourly_rate || 0;
      } else if (jobs && jobs.length > 1) {
        // Multiple jobs - use default if exists
        const defaultJob = jobs.find((j: any) => j.is_default);
        if (defaultJob) {
          finalJobId = defaultJob.id;
          jobName = defaultJob.name;
          jobHourlyRate = defaultJob.hourly_rate || 0;
        }
      }
    }

    // Use provided hourly rate, or fall back to job's hourly rate
    const finalHourlyRate = hourlyRate !== undefined ? hourlyRate : jobHourlyRate;

    // Build insert object with ONLY columns that exist in the database
    const insertData: any = {
      user_id: this.userId,
      date: date,
      cash_tips: cashTips,
      credit_tips: creditTips,
      hourly_rate: finalHourlyRate,
      hours_worked: hoursWorked,
    };

    // Set job_id (either provided or auto-detected)
    if (finalJobId) insertData.job_id = finalJobId;
    
    // Optional fields - only include if provided
    if (eventName) insertData.event_name = eventName;
    if (guestCount) insertData.guest_count = guestCount;
    if (notes) insertData.notes = notes;
    if (startTime) insertData.start_time = startTime;
    if (endTime) insertData.end_time = endTime;
    if (jobType) insertData.job_type = jobType;
    if (location) insertData.location = location;
    if (clientName) insertData.client_name = clientName;
    if (projectName) insertData.project_name = projectName;
    if (hostess) insertData.hostess = hostess;
    if (salesAmount) insertData.sales_amount = salesAmount;
    if (tipoutPercent) insertData.tipout_percent = tipoutPercent;
    if (additionalTipout) insertData.additional_tipout = additionalTipout;
    if (additionalTipoutNote) insertData.additional_tipout_note = additionalTipoutNote;
    if (overtimeHours) insertData.overtime_hours = overtimeHours;
    if (commission) insertData.commission = commission;
    if (mileage) insertData.mileage = mileage;
    if (flatRate) insertData.flat_rate = flatRate;
    if (eventCost) insertData.event_cost = eventCost;
    
    // Rideshare & Delivery fields
    if (ridesCount !== undefined) insertData.rides_count = ridesCount;
    if (deliveriesCount !== undefined) insertData.deliveries_count = deliveriesCount;
    if (deadMiles !== undefined) insertData.dead_miles = deadMiles;
    if (fuelCost !== undefined) insertData.fuel_cost = fuelCost;
    if (tollsParking !== undefined) insertData.tolls_parking = tollsParking;
    if (surgeMultiplier !== undefined) insertData.surge_multiplier = surgeMultiplier;
    if (acceptanceRate !== undefined) insertData.acceptance_rate = acceptanceRate;
    if (baseFare !== undefined) insertData.base_fare = baseFare;
    
    // Music & Entertainment fields
    if (gigType) insertData.gig_type = gigType;
    if (setupHours !== undefined) insertData.setup_hours = setupHours;
    if (performanceHours !== undefined) insertData.performance_hours = performanceHours;
    if (breakdownHours !== undefined) insertData.breakdown_hours = breakdownHours;
    if (equipmentUsed) insertData.equipment_used = equipmentUsed;
    if (equipmentRentalCost !== undefined) insertData.equipment_rental_cost = equipmentRentalCost;
    if (crewPayment !== undefined) insertData.crew_payment = crewPayment;
    if (merchSales !== undefined) insertData.merch_sales = merchSales;
    if (audienceSize !== undefined) insertData.audience_size = audienceSize;
    
    // Artist & Crafts fields
    if (piecesCreated !== undefined) insertData.pieces_created = piecesCreated;
    if (piecesSold !== undefined) insertData.pieces_sold = piecesSold;
    if (materialsCost !== undefined) insertData.materials_cost = materialsCost;
    if (salePrice !== undefined) insertData.sale_price = salePrice;
    if (venueCommissionPercent !== undefined) insertData.venue_commission_percent = venueCommissionPercent;
    
    // Retail/Sales fields
    if (itemsSold !== undefined) insertData.items_sold = itemsSold;
    if (transactionsCount !== undefined) insertData.transactions_count = transactionsCount;
    if (upsellsCount !== undefined) insertData.upsells_count = upsellsCount;
    if (upsellsAmount !== undefined) insertData.upsells_amount = upsellsAmount;
    if (returnsCount !== undefined) insertData.returns_count = returnsCount;
    if (returnsAmount !== undefined) insertData.returns_amount = returnsAmount;
    if (shrinkAmount !== undefined) insertData.shrink_amount = shrinkAmount;
    if (department) insertData.department = department;
    
    // Salon/Spa fields
    if (serviceType) insertData.service_type = serviceType;
    if (servicesCount !== undefined) insertData.services_count = servicesCount;
    if (productSales !== undefined) insertData.product_sales = productSales;
    if (repeatClientPercent !== undefined) insertData.repeat_client_percent = repeatClientPercent;
    if (chairRental !== undefined) insertData.chair_rental = chairRental;
    if (newClientsCount !== undefined) insertData.new_clients_count = newClientsCount;
    if (returningClientsCount !== undefined) insertData.returning_clients_count = returningClientsCount;
    if (walkinCount !== undefined) insertData.walkin_count = walkinCount;
    if (appointmentCount !== undefined) insertData.appointment_count = appointmentCount;
    
    // Hospitality fields
    if (roomType) insertData.room_type = roomType;
    if (roomsCleaned !== undefined) insertData.rooms_cleaned = roomsCleaned;
    if (qualityScore !== undefined) insertData.quality_score = qualityScore;
    if (shiftType) insertData.shift_type = shiftType;
    if (roomUpgrades !== undefined) insertData.room_upgrades = roomUpgrades;
    if (guestsCheckedIn !== undefined) insertData.guests_checked_in = guestsCheckedIn;
    if (carsParked !== undefined) insertData.cars_parked = carsParked;
    
    // Healthcare fields
    if (patientCount !== undefined) insertData.patient_count = patientCount;
    if (shiftDifferential !== undefined) insertData.shift_differential = shiftDifferential;
    if (onCallHours !== undefined) insertData.on_call_hours = onCallHours;
    if (proceduresCount !== undefined) insertData.procedures_count = proceduresCount;
    if (specialization) insertData.specialization = specialization;
    
    // Fitness fields
    if (sessionsCount !== undefined) insertData.sessions_count = sessionsCount;
    if (sessionType) insertData.session_type = sessionType;
    if (classSize !== undefined) insertData.class_size = classSize;
    if (retentionRate !== undefined) insertData.retention_rate = retentionRate;
    if (cancellationsCount !== undefined) insertData.cancellations_count = cancellationsCount;
    if (packageSales !== undefined) insertData.package_sales = packageSales;
    if (supplementSales !== undefined) insertData.supplement_sales = supplementSales;
    
    // Construction/Trades fields
    if (laborCost !== undefined) insertData.labor_cost = laborCost;
    if (subcontractorCost !== undefined) insertData.subcontractor_cost = subcontractorCost;
    if (squareFootage !== undefined) insertData.square_footage = squareFootage;
    if (weatherDelayHours !== undefined) insertData.weather_delay_hours = weatherDelayHours;
    
    // Freelancer fields
    if (revisionsCount !== undefined) insertData.revisions_count = revisionsCount;
    if (clientType) insertData.client_type = clientType;
    if (expenses !== undefined) insertData.expenses = expenses;
    if (billableHours !== undefined) insertData.billable_hours = billableHours;
    
    // Restaurant Additional fields
    if (tableSection) insertData.table_section = tableSection;
    if (cashSales !== undefined) insertData.cash_sales = cashSales;
    if (cardSales !== undefined) insertData.card_sales = cardSales;

    const { data, error } = await this.supabase
      .from("shifts")
      .insert(insertData)
      .select()
      .single();

    if (error) throw error;

    // Calculate totals for response (not stored in DB)
    const totalTips = cashTips + creditTips;
    const hourlyWages = hourlyRate * hoursWorked;
    const totalIncome = hourlyWages + totalTips;

    // Build response with job info
    const missingFields = [];
    if (!hoursWorked) missingFields.push("hours worked");
    if (!startTime && !endTime) missingFields.push("start/end time");

    return {
      success: true,
      shift: data,
      jobName: jobName,
      jobAutoSelected: !jobId && !!finalJobId,
      summary: {
        date: date,
        totalIncome: totalIncome,
        cashTips: cashTips,
        creditTips: creditTips,
        hours: hoursWorked,
        eventName: eventName,
        jobName: jobName,
      },
      missingFields: missingFields.length > 0 ? missingFields : null,
    };
  }

  private async editShift(args: any) {
    const { date, updates } = args;

    // Find shift by date (with job info)
    const { data: existingShift, error: findError } = await this.supabase
      .from("shifts")
      .select("*, jobs(hourly_rate)")
      .eq("user_id", this.userId)
      .eq("date", date)
      .single();

    if (findError || !existingShift) {
      throw new Error(`No shift found on ${date}`);
    }

    // Convert camelCase updates to snake_case for database
    // ONLY include columns that actually exist in the schema
    const dbUpdates: any = {};
    if (updates.cashTips !== undefined) dbUpdates.cash_tips = updates.cashTips;
    if (updates.creditTips !== undefined) dbUpdates.credit_tips = updates.creditTips;
    if (updates.hourlyRate !== undefined) dbUpdates.hourly_rate = updates.hourlyRate;
    if (updates.hoursWorked !== undefined) dbUpdates.hours_worked = updates.hoursWorked;
    if (updates.overtimeHours !== undefined) dbUpdates.overtime_hours = updates.overtimeHours;
    if (updates.eventName !== undefined) dbUpdates.event_name = updates.eventName;
    if (updates.guestCount !== undefined) dbUpdates.guest_count = updates.guestCount;
    if (updates.notes !== undefined) dbUpdates.notes = updates.notes;
    if (updates.jobId !== undefined) dbUpdates.job_id = updates.jobId;
    if (updates.startTime !== undefined) dbUpdates.start_time = updates.startTime;
    if (updates.endTime !== undefined) dbUpdates.end_time = updates.endTime;
    if (updates.jobType !== undefined) dbUpdates.job_type = updates.jobType;
    if (updates.location !== undefined) dbUpdates.location = updates.location;
    if (updates.clientName !== undefined) dbUpdates.client_name = updates.clientName;
    if (updates.projectName !== undefined) dbUpdates.project_name = updates.projectName;
    if (updates.hostess !== undefined) dbUpdates.hostess = updates.hostess;
    if (updates.salesAmount !== undefined) dbUpdates.sales_amount = updates.salesAmount;
    if (updates.tipoutPercent !== undefined) dbUpdates.tipout_percent = updates.tipoutPercent;
    if (updates.additionalTipout !== undefined) dbUpdates.additional_tipout = updates.additionalTipout;
    if (updates.additionalTipoutNote !== undefined) dbUpdates.additional_tipout_note = updates.additionalTipoutNote;
    if (updates.commission !== undefined) dbUpdates.commission = updates.commission;
    if (updates.mileage !== undefined) dbUpdates.mileage = updates.mileage;
    if (updates.flatRate !== undefined) dbUpdates.flat_rate = updates.flatRate;
    if (updates.eventCost !== undefined) dbUpdates.event_cost = updates.eventCost;
    
    // Rideshare & Delivery fields
    if (updates.ridesCount !== undefined) dbUpdates.rides_count = updates.ridesCount;
    if (updates.deliveriesCount !== undefined) dbUpdates.deliveries_count = updates.deliveriesCount;
    if (updates.deadMiles !== undefined) dbUpdates.dead_miles = updates.deadMiles;
    if (updates.fuelCost !== undefined) dbUpdates.fuel_cost = updates.fuelCost;
    if (updates.tollsParking !== undefined) dbUpdates.tolls_parking = updates.tollsParking;
    if (updates.surgeMultiplier !== undefined) dbUpdates.surge_multiplier = updates.surgeMultiplier;
    if (updates.acceptanceRate !== undefined) dbUpdates.acceptance_rate = updates.acceptanceRate;
    if (updates.baseFare !== undefined) dbUpdates.base_fare = updates.baseFare;
    
    // Music & Entertainment fields
    if (updates.gigType !== undefined) dbUpdates.gig_type = updates.gigType;
    if (updates.setupHours !== undefined) dbUpdates.setup_hours = updates.setupHours;
    if (updates.performanceHours !== undefined) dbUpdates.performance_hours = updates.performanceHours;
    if (updates.breakdownHours !== undefined) dbUpdates.breakdown_hours = updates.breakdownHours;
    if (updates.equipmentUsed !== undefined) dbUpdates.equipment_used = updates.equipmentUsed;
    if (updates.equipmentRentalCost !== undefined) dbUpdates.equipment_rental_cost = updates.equipmentRentalCost;
    if (updates.crewPayment !== undefined) dbUpdates.crew_payment = updates.crewPayment;
    if (updates.merchSales !== undefined) dbUpdates.merch_sales = updates.merchSales;
    if (updates.audienceSize !== undefined) dbUpdates.audience_size = updates.audienceSize;
    
    // Artist & Crafts fields
    if (updates.piecesCreated !== undefined) dbUpdates.pieces_created = updates.piecesCreated;
    if (updates.piecesSold !== undefined) dbUpdates.pieces_sold = updates.piecesSold;
    if (updates.materialsCost !== undefined) dbUpdates.materials_cost = updates.materialsCost;
    if (updates.salePrice !== undefined) dbUpdates.sale_price = updates.salePrice;
    if (updates.venueCommissionPercent !== undefined) dbUpdates.venue_commission_percent = updates.venueCommissionPercent;
    
    // Retail/Sales fields
    if (updates.itemsSold !== undefined) dbUpdates.items_sold = updates.itemsSold;
    if (updates.transactionsCount !== undefined) dbUpdates.transactions_count = updates.transactionsCount;
    if (updates.upsellsCount !== undefined) dbUpdates.upsells_count = updates.upsellsCount;
    if (updates.upsellsAmount !== undefined) dbUpdates.upsells_amount = updates.upsellsAmount;
    if (updates.returnsCount !== undefined) dbUpdates.returns_count = updates.returnsCount;
    if (updates.returnsAmount !== undefined) dbUpdates.returns_amount = updates.returnsAmount;
    if (updates.shrinkAmount !== undefined) dbUpdates.shrink_amount = updates.shrinkAmount;
    if (updates.department !== undefined) dbUpdates.department = updates.department;
    
    // Salon/Spa fields
    if (updates.serviceType !== undefined) dbUpdates.service_type = updates.serviceType;
    if (updates.servicesCount !== undefined) dbUpdates.services_count = updates.servicesCount;
    if (updates.productSales !== undefined) dbUpdates.product_sales = updates.productSales;
    if (updates.repeatClientPercent !== undefined) dbUpdates.repeat_client_percent = updates.repeatClientPercent;
    if (updates.chairRental !== undefined) dbUpdates.chair_rental = updates.chairRental;
    if (updates.newClientsCount !== undefined) dbUpdates.new_clients_count = updates.newClientsCount;
    if (updates.returningClientsCount !== undefined) dbUpdates.returning_clients_count = updates.returningClientsCount;
    if (updates.walkinCount !== undefined) dbUpdates.walkin_count = updates.walkinCount;
    if (updates.appointmentCount !== undefined) dbUpdates.appointment_count = updates.appointmentCount;
    
    // Hospitality fields
    if (updates.roomType !== undefined) dbUpdates.room_type = updates.roomType;
    if (updates.roomsCleaned !== undefined) dbUpdates.rooms_cleaned = updates.roomsCleaned;
    if (updates.qualityScore !== undefined) dbUpdates.quality_score = updates.qualityScore;
    if (updates.shiftType !== undefined) dbUpdates.shift_type = updates.shiftType;
    if (updates.roomUpgrades !== undefined) dbUpdates.room_upgrades = updates.roomUpgrades;
    if (updates.guestsCheckedIn !== undefined) dbUpdates.guests_checked_in = updates.guestsCheckedIn;
    if (updates.carsParked !== undefined) dbUpdates.cars_parked = updates.carsParked;
    
    // Healthcare fields
    if (updates.patientCount !== undefined) dbUpdates.patient_count = updates.patientCount;
    if (updates.shiftDifferential !== undefined) dbUpdates.shift_differential = updates.shiftDifferential;
    if (updates.onCallHours !== undefined) dbUpdates.on_call_hours = updates.onCallHours;
    if (updates.proceduresCount !== undefined) dbUpdates.procedures_count = updates.proceduresCount;
    if (updates.specialization !== undefined) dbUpdates.specialization = updates.specialization;
    
    // Fitness fields
    if (updates.sessionsCount !== undefined) dbUpdates.sessions_count = updates.sessionsCount;
    if (updates.sessionType !== undefined) dbUpdates.session_type = updates.sessionType;
    if (updates.classSize !== undefined) dbUpdates.class_size = updates.classSize;
    if (updates.retentionRate !== undefined) dbUpdates.retention_rate = updates.retentionRate;
    if (updates.cancellationsCount !== undefined) dbUpdates.cancellations_count = updates.cancellationsCount;
    if (updates.packageSales !== undefined) dbUpdates.package_sales = updates.packageSales;
    if (updates.supplementSales !== undefined) dbUpdates.supplement_sales = updates.supplementSales;
    
    // Construction/Trades fields
    if (updates.laborCost !== undefined) dbUpdates.labor_cost = updates.laborCost;
    if (updates.subcontractorCost !== undefined) dbUpdates.subcontractor_cost = updates.subcontractorCost;
    if (updates.squareFootage !== undefined) dbUpdates.square_footage = updates.squareFootage;
    if (updates.weatherDelayHours !== undefined) dbUpdates.weather_delay_hours = updates.weatherDelayHours;
    
    // Freelancer fields
    if (updates.revisionsCount !== undefined) dbUpdates.revisions_count = updates.revisionsCount;
    if (updates.clientType !== undefined) dbUpdates.client_type = updates.clientType;
    if (updates.expenses !== undefined) dbUpdates.expenses = updates.expenses;
    if (updates.billableHours !== undefined) dbUpdates.billable_hours = updates.billableHours;
    
    // Restaurant Additional fields
    if (updates.tableSection !== undefined) dbUpdates.table_section = updates.tableSection;
    if (updates.cashSales !== undefined) dbUpdates.cash_sales = updates.cashSales;
    if (updates.cardSales !== undefined) dbUpdates.card_sales = updates.cardSales;

    // Always ensure hourly rate is set when updating hours or tips
    // Pull from job if shift has no hourly_rate or it's 0
    if ((updates.hoursWorked !== undefined || updates.cashTips !== undefined || updates.creditTips !== undefined) && 
        (!existingShift.hourly_rate || existingShift.hourly_rate === 0) && 
        !updates.hourlyRate) {
      const jobHourlyRate = existingShift.jobs?.hourly_rate || 0;
      if (jobHourlyRate > 0) {
        dbUpdates.hourly_rate = jobHourlyRate;
        console.log(`Setting hourly rate from job: ${jobHourlyRate} for shift on ${existingShift.date}`);
      }
    }

    // Update shift with ONLY valid columns
    const { data, error } = await this.supabase
      .from("shifts")
      .update(dbUpdates)
      .eq("id", existingShift.id)
      .select()
      .single();

    if (error) throw error;

    // Calculate totals for response (not stored in DB)
    const cashTips = data.cash_tips || 0;
    const creditTips = data.credit_tips || 0;
    const hourlyRate = data.hourly_rate || 0;
    const hoursWorked = data.hours_worked || 0;
    const totalTips = cashTips + creditTips;
    const totalIncome = (hourlyRate * hoursWorked) + totalTips;

    return {
      success: true,
      shift: data,
      before: existingShift,
      after: { ...data, total_income: totalIncome },
    };
  }

  private async deleteShift(args: any) {
    const { date, confirmed } = args;

    if (!confirmed) {
      // Return shift details for confirmation
      const { data: shift } = await this.supabase
        .from("shifts")
        .select("*")
        .eq("user_id", this.userId)
        .eq("date", date)
        .single();

      if (!shift) throw new Error(`No shift found on ${date}`);

      return {
        needsConfirmation: true,
        shift: shift,
        message: `Are you sure you want to delete the shift from ${date}? You earned $${shift.total_income.toFixed(2)} that day.`,
      };
    }

    // Delete the shift
    const { error } = await this.supabase
      .from("shifts")
      .delete()
      .eq("user_id", this.userId)
      .eq("date", date);

    if (error) throw error;

    return {
      success: true,
      message: `Shift from ${date} deleted successfully.`,
    };
  }

  private async bulkEditShifts(args: any) {
    const { startDate, endDate, jobId, jobName, updates, confirmed } = args;

    // Build query to find matching shifts
    let queryBuilder = this.supabase
      .from("shifts")
      .select("*, jobs(name)")
      .eq("user_id", this.userId);

    // Apply date range filter
    if (startDate) {
      queryBuilder = queryBuilder.gte("date", startDate);
    }
    if (endDate) {
      queryBuilder = queryBuilder.lte("date", endDate);
    }

    // Apply job filter by ID or name
    if (jobId) {
      queryBuilder = queryBuilder.eq("job_id", jobId);
    } else if (jobName) {
      // Find job by name first
      const { data: jobs } = await this.supabase
        .from("jobs")
        .select("id, name")
        .eq("user_id", this.userId)
        .ilike("name", `%${jobName}%`);
      
      if (jobs && jobs.length > 0) {
        queryBuilder = queryBuilder.eq("job_id", jobs[0].id);
      }
    }

    const { data: shifts, error: findError } = await queryBuilder.order("date", { ascending: true });

    if (findError) throw findError;

    if (!shifts || shifts.length === 0) {
      return {
        success: false,
        count: 0,
        message: "No shifts found matching those criteria.",
      };
    }

    // If not confirmed, return a PREVIEW (don't actually update)
    if (!confirmed) {
      const dateRange = shifts.length > 0 
        ? `${shifts[0].date} to ${shifts[shifts.length - 1].date}`
        : "N/A";
      
      // Build a description of what will change
      const changeDescriptions = [];
      if (updates.cashTips !== undefined) changeDescriptions.push(`cash tips to $${updates.cashTips}`);
      if (updates.creditTips !== undefined) changeDescriptions.push(`credit tips to $${updates.creditTips}`);
      if (updates.hourlyRate !== undefined) changeDescriptions.push(`hourly rate to $${updates.hourlyRate}`);
      if (updates.hoursWorked !== undefined) changeDescriptions.push(`hours worked to ${updates.hoursWorked}`);
      if (updates.overtimeHours !== undefined) changeDescriptions.push(`overtime hours to ${updates.overtimeHours}`);
      if (updates.startTime !== undefined) changeDescriptions.push(`start time to ${updates.startTime}`);
      if (updates.endTime !== undefined) changeDescriptions.push(`end time to ${updates.endTime}`);
      if (updates.notes !== undefined) changeDescriptions.push(`notes to "${updates.notes}"`);
      if (updates.eventName !== undefined) changeDescriptions.push(`event name to "${updates.eventName}"`);
      if (updates.guestCount !== undefined) changeDescriptions.push(`guest count to ${updates.guestCount}`);
      if (updates.location !== undefined) changeDescriptions.push(`location to "${updates.location}"`);
      if (updates.clientName !== undefined) changeDescriptions.push(`client name to "${updates.clientName}"`);
      if (updates.projectName !== undefined) changeDescriptions.push(`project name to "${updates.projectName}"`);
      if (updates.hostess !== undefined) changeDescriptions.push(`hostess to "${updates.hostess}"`);
      if (updates.salesAmount !== undefined) changeDescriptions.push(`sales amount to $${updates.salesAmount}`);
      if (updates.tipoutPercent !== undefined) changeDescriptions.push(`tipout % to ${updates.tipoutPercent}%`);
      if (updates.additionalTipout !== undefined) changeDescriptions.push(`additional tipout to $${updates.additionalTipout}`);
      if (updates.additionalTipoutNote !== undefined) changeDescriptions.push(`tipout note to "${updates.additionalTipoutNote}"`);
      if (updates.commission !== undefined) changeDescriptions.push(`commission to $${updates.commission}`);
      if (updates.mileage !== undefined) changeDescriptions.push(`mileage to ${updates.mileage} miles`);
      if (updates.flatRate !== undefined) changeDescriptions.push(`flat rate to $${updates.flatRate}`);
      if (updates.eventCost !== undefined) changeDescriptions.push(`event cost to $${updates.eventCost}`);

      return {
        needsConfirmation: true,
        count: shifts.length,
        dateRange: dateRange,
        changes: changeDescriptions.join(", "),
        message: `I found ${shifts.length} shifts from ${dateRange}. I'll update ${changeDescriptions.join(", ")}. Should I proceed?`,
        shiftDates: shifts.slice(0, 5).map((s: any) => s.date), // Show first 5 dates as preview
      };
    }

    // CONFIRMED - Actually update all shifts
    // Convert camelCase updates to snake_case
    const dbUpdates: any = {};
    if (updates.cashTips !== undefined) dbUpdates.cash_tips = updates.cashTips;
    if (updates.creditTips !== undefined) dbUpdates.credit_tips = updates.creditTips;
    if (updates.hourlyRate !== undefined) dbUpdates.hourly_rate = updates.hourlyRate;
    if (updates.hoursWorked !== undefined) dbUpdates.hours_worked = updates.hoursWorked;
    if (updates.overtimeHours !== undefined) dbUpdates.overtime_hours = updates.overtimeHours;
    if (updates.startTime !== undefined) dbUpdates.start_time = updates.startTime;
    if (updates.endTime !== undefined) dbUpdates.end_time = updates.endTime;
    if (updates.notes !== undefined) dbUpdates.notes = updates.notes;
    if (updates.eventName !== undefined) dbUpdates.event_name = updates.eventName;
    if (updates.guestCount !== undefined) dbUpdates.guest_count = updates.guestCount;
    if (updates.location !== undefined) dbUpdates.location = updates.location;
    if (updates.clientName !== undefined) dbUpdates.client_name = updates.clientName;
    if (updates.projectName !== undefined) dbUpdates.project_name = updates.projectName;
    if (updates.hostess !== undefined) dbUpdates.hostess = updates.hostess;
    if (updates.salesAmount !== undefined) dbUpdates.sales_amount = updates.salesAmount;
    if (updates.tipoutPercent !== undefined) dbUpdates.tipout_percent = updates.tipoutPercent;
    if (updates.additionalTipout !== undefined) dbUpdates.additional_tipout = updates.additionalTipout;
    if (updates.additionalTipoutNote !== undefined) dbUpdates.additional_tipout_note = updates.additionalTipoutNote;
    if (updates.commission !== undefined) dbUpdates.commission = updates.commission;
    if (updates.mileage !== undefined) dbUpdates.mileage = updates.mileage;
    if (updates.flatRate !== undefined) dbUpdates.flat_rate = updates.flatRate;
    if (updates.eventCost !== undefined) dbUpdates.event_cost = updates.eventCost;
    
    // Rideshare & Delivery fields
    if (updates.ridesCount !== undefined) dbUpdates.rides_count = updates.ridesCount;
    if (updates.deliveriesCount !== undefined) dbUpdates.deliveries_count = updates.deliveriesCount;
    if (updates.deadMiles !== undefined) dbUpdates.dead_miles = updates.deadMiles;
    if (updates.fuelCost !== undefined) dbUpdates.fuel_cost = updates.fuelCost;
    if (updates.tollsParking !== undefined) dbUpdates.tolls_parking = updates.tollsParking;
    if (updates.surgeMultiplier !== undefined) dbUpdates.surge_multiplier = updates.surgeMultiplier;
    if (updates.acceptanceRate !== undefined) dbUpdates.acceptance_rate = updates.acceptanceRate;
    if (updates.baseFare !== undefined) dbUpdates.base_fare = updates.baseFare;
    
    // Music & Entertainment fields
    if (updates.gigType !== undefined) dbUpdates.gig_type = updates.gigType;
    if (updates.setupHours !== undefined) dbUpdates.setup_hours = updates.setupHours;
    if (updates.performanceHours !== undefined) dbUpdates.performance_hours = updates.performanceHours;
    if (updates.breakdownHours !== undefined) dbUpdates.breakdown_hours = updates.breakdownHours;
    if (updates.equipmentUsed !== undefined) dbUpdates.equipment_used = updates.equipmentUsed;
    if (updates.equipmentRentalCost !== undefined) dbUpdates.equipment_rental_cost = updates.equipmentRentalCost;
    if (updates.crewPayment !== undefined) dbUpdates.crew_payment = updates.crewPayment;
    if (updates.merchSales !== undefined) dbUpdates.merch_sales = updates.merchSales;
    if (updates.audienceSize !== undefined) dbUpdates.audience_size = updates.audienceSize;
    
    // Artist & Crafts fields
    if (updates.piecesCreated !== undefined) dbUpdates.pieces_created = updates.piecesCreated;
    if (updates.piecesSold !== undefined) dbUpdates.pieces_sold = updates.piecesSold;
    if (updates.materialsCost !== undefined) dbUpdates.materials_cost = updates.materialsCost;
    if (updates.salePrice !== undefined) dbUpdates.sale_price = updates.salePrice;
    if (updates.venueCommissionPercent !== undefined) dbUpdates.venue_commission_percent = updates.venueCommissionPercent;
    
    // Retail/Sales fields
    if (updates.itemsSold !== undefined) dbUpdates.items_sold = updates.itemsSold;
    if (updates.transactionsCount !== undefined) dbUpdates.transactions_count = updates.transactionsCount;
    if (updates.upsellsCount !== undefined) dbUpdates.upsells_count = updates.upsellsCount;
    if (updates.upsellsAmount !== undefined) dbUpdates.upsells_amount = updates.upsellsAmount;
    if (updates.returnsCount !== undefined) dbUpdates.returns_count = updates.returnsCount;
    if (updates.returnsAmount !== undefined) dbUpdates.returns_amount = updates.returnsAmount;
    if (updates.shrinkAmount !== undefined) dbUpdates.shrink_amount = updates.shrinkAmount;
    if (updates.department !== undefined) dbUpdates.department = updates.department;
    
    // Salon/Spa fields
    if (updates.serviceType !== undefined) dbUpdates.service_type = updates.serviceType;
    if (updates.servicesCount !== undefined) dbUpdates.services_count = updates.servicesCount;
    if (updates.productSales !== undefined) dbUpdates.product_sales = updates.productSales;
    if (updates.repeatClientPercent !== undefined) dbUpdates.repeat_client_percent = updates.repeatClientPercent;
    if (updates.chairRental !== undefined) dbUpdates.chair_rental = updates.chairRental;
    if (updates.newClientsCount !== undefined) dbUpdates.new_clients_count = updates.newClientsCount;
    if (updates.returningClientsCount !== undefined) dbUpdates.returning_clients_count = updates.returningClientsCount;
    if (updates.walkinCount !== undefined) dbUpdates.walkin_count = updates.walkinCount;
    if (updates.appointmentCount !== undefined) dbUpdates.appointment_count = updates.appointmentCount;
    
    // Hospitality fields
    if (updates.roomType !== undefined) dbUpdates.room_type = updates.roomType;
    if (updates.roomsCleaned !== undefined) dbUpdates.rooms_cleaned = updates.roomsCleaned;
    if (updates.qualityScore !== undefined) dbUpdates.quality_score = updates.qualityScore;
    if (updates.shiftType !== undefined) dbUpdates.shift_type = updates.shiftType;
    if (updates.roomUpgrades !== undefined) dbUpdates.room_upgrades = updates.roomUpgrades;
    if (updates.guestsCheckedIn !== undefined) dbUpdates.guests_checked_in = updates.guestsCheckedIn;
    if (updates.carsParked !== undefined) dbUpdates.cars_parked = updates.carsParked;
    
    // Healthcare fields
    if (updates.patientCount !== undefined) dbUpdates.patient_count = updates.patientCount;
    if (updates.shiftDifferential !== undefined) dbUpdates.shift_differential = updates.shiftDifferential;
    if (updates.onCallHours !== undefined) dbUpdates.on_call_hours = updates.onCallHours;
    if (updates.proceduresCount !== undefined) dbUpdates.procedures_count = updates.proceduresCount;
    if (updates.specialization !== undefined) dbUpdates.specialization = updates.specialization;
    
    // Fitness fields
    if (updates.sessionsCount !== undefined) dbUpdates.sessions_count = updates.sessionsCount;
    if (updates.sessionType !== undefined) dbUpdates.session_type = updates.sessionType;
    if (updates.classSize !== undefined) dbUpdates.class_size = updates.classSize;
    if (updates.retentionRate !== undefined) dbUpdates.retention_rate = updates.retentionRate;
    if (updates.cancellationsCount !== undefined) dbUpdates.cancellations_count = updates.cancellationsCount;
    if (updates.packageSales !== undefined) dbUpdates.package_sales = updates.packageSales;
    if (updates.supplementSales !== undefined) dbUpdates.supplement_sales = updates.supplementSales;
    
    // Construction/Trades fields
    if (updates.laborCost !== undefined) dbUpdates.labor_cost = updates.laborCost;
    if (updates.subcontractorCost !== undefined) dbUpdates.subcontractor_cost = updates.subcontractorCost;
    if (updates.squareFootage !== undefined) dbUpdates.square_footage = updates.squareFootage;
    if (updates.weatherDelayHours !== undefined) dbUpdates.weather_delay_hours = updates.weatherDelayHours;
    
    // Freelancer fields
    if (updates.revisionsCount !== undefined) dbUpdates.revisions_count = updates.revisionsCount;
    if (updates.clientType !== undefined) dbUpdates.client_type = updates.clientType;
    if (updates.expenses !== undefined) dbUpdates.expenses = updates.expenses;
    if (updates.billableHours !== undefined) dbUpdates.billable_hours = updates.billableHours;
    
    // Restaurant Additional fields
    if (updates.tableSection !== undefined) dbUpdates.table_section = updates.tableSection;
    if (updates.cashSales !== undefined) dbUpdates.cash_sales = updates.cashSales;
    if (updates.cardSales !== undefined) dbUpdates.card_sales = updates.cardSales;

    // When updating ANY earnings-related field (tips, hours), ensure hourly_rate is set from job
    // This requires individual updates to set correct hourly_rate per shift
    const needsHourlyRateCheck = (
      updates.hoursWorked !== undefined || 
      updates.cashTips !== undefined || 
      updates.creditTips !== undefined
    ) && updates.hourlyRate === undefined;

    if (needsHourlyRateCheck) {
      // Get all unique job IDs from the shifts
      const jobIds = [...new Set(shifts.map((s: any) => s.job_id).filter(Boolean))];
      
      // Fetch job hourly rates
      const { data: jobs } = await this.supabase
        .from("jobs")
        .select("id, hourly_rate")
        .in("id", jobIds);
      
      const jobRates: Record<string, number> = {};
      if (jobs) {
        jobs.forEach((j: any) => {
          if (j.hourly_rate && j.hourly_rate > 0) {
            jobRates[j.id] = j.hourly_rate;
          }
        });
      }

      // Update each shift individually with its job's hourly rate
      let updatedCount = 0;
      let hourlyRateAppliedCount = 0;
      let appliedHourlyRate = 0;
      
      for (const shift of shifts) {
        const shiftUpdate = { ...dbUpdates };
        // If shift has no hourly_rate (0 or null), get it from the job
        if ((!shift.hourly_rate || shift.hourly_rate === 0) && shift.job_id && jobRates[shift.job_id]) {
          shiftUpdate.hourly_rate = jobRates[shift.job_id];
          appliedHourlyRate = jobRates[shift.job_id];
          hourlyRateAppliedCount++;
        }
        
        const { error } = await this.supabase
          .from("shifts")
          .update(shiftUpdate)
          .eq("id", shift.id);
        
        if (!error) updatedCount++;
      }

      // Build informative message about what was done
      let message = `✅ Updated ${updatedCount} shifts successfully!`;
      if (hourlyRateAppliedCount > 0) {
        message += ` Also applied hourly rate of $${appliedHourlyRate}/hr from your job to ${hourlyRateAppliedCount} shifts that were missing it.`;
      }

      return {
        success: true,
        count: updatedCount,
        hourlyRateApplied: hourlyRateAppliedCount > 0,
        hourlyRate: appliedHourlyRate,
        message: message,
      };
    }

    // Standard bulk update (no hourly rate logic needed)
    const shiftIds = shifts.map((s: any) => s.id);
    const { error } = await this.supabase
      .from("shifts")
      .update(dbUpdates)
      .in("id", shiftIds);

    if (error) throw error;

    return {
      success: true,
      count: shifts.length,
      message: `✅ Updated ${shifts.length} shifts successfully!`,
    };
  }

  private async bulkDeleteShifts(args: any) {
    const { query, confirmed } = args;

    if (!confirmed) {
      throw new Error("Bulk deletes MUST be confirmed. Set confirmed=true only after user approval.");
    }

    // Build query (same as bulk edit)
    let queryBuilder = this.supabase
      .from("shifts")
      .select("*")
      .eq("user_id", this.userId);

    if (query.dateRange) {
      queryBuilder = queryBuilder
        .gte("date", query.dateRange.start)
        .lte("date", query.dateRange.end);
    }

    if (query.jobId) {
      queryBuilder = queryBuilder.eq("job_id", query.jobId);
    }

    const { data: shifts, error: findError } = await queryBuilder;
    if (findError) throw findError;

    const totalIncomeLost = shifts.reduce((sum: number, s: any) => sum + s.total_income, 0);

    // Delete shifts
    const shiftIds = shifts.map((s: any) => s.id);
    const { error } = await this.supabase.from("shifts").delete().in("id", shiftIds);

    if (error) throw error;

    return {
      success: true,
      count: shifts.length,
      totalIncomeLost: totalIncomeLost,
      message: `Deleted ${shifts.length} shifts (total income: $${totalIncomeLost.toFixed(2)}).`,
    };
  }

  private async searchShifts(args: any) {
    const { query } = args;

    let queryBuilder = this.supabase
      .from("shifts")
      .select("*")
      .eq("user_id", this.userId);

    if (query.dateRange) {
      queryBuilder = queryBuilder
        .gte("date", query.dateRange.start)
        .lte("date", query.dateRange.end);
    }

    if (query.jobId) {
      queryBuilder = queryBuilder.eq("job_id", query.jobId);
    }

    if (query.eventName) {
      queryBuilder = queryBuilder.ilike("event_name", `%${query.eventName}%`);
    }

    if (query.minAmount) {
      queryBuilder = queryBuilder.gte("total_income", query.minAmount);
    }

    if (query.maxAmount) {
      queryBuilder = queryBuilder.lte("total_income", query.maxAmount);
    }

    if (query.hasNotes !== undefined) {
      if (query.hasNotes) {
        queryBuilder = queryBuilder.not("notes", "is", null);
      } else {
        queryBuilder = queryBuilder.is("notes", null);
      }
    }

    const { data: shifts, error } = await queryBuilder.order("date", { ascending: false });

    if (error) throw error;

    return {
      success: true,
      count: shifts.length,
      shifts: shifts,
    };
  }

  private async getShiftDetails(args: any) {
    const { date, jobId } = args;

    let query = this.supabase
      .from("shifts")
      .select("*")
      .eq("user_id", this.userId)
      .eq("date", date);

    if (jobId) {
      query = query.eq("job_id", jobId);
    }

    const { data: shift, error } = await query.single();

    if (error || !shift) {
      throw new Error(`No shift found on ${date}`);
    }

    return {
      success: true,
      shift: shift,
    };
  }

  private async attachPhotoToShift(args: any) {
    const { shiftDate, photoId, photoUrl } = args;

    try {
      // Get the shift for this date
      const { data: shift, error: shiftError } = await this.supabase
        .from("shifts")
        .select("id")
        .eq("user_id", this.userId)
        .eq("date", shiftDate)
        .single();

      if (shiftError || !shift) {
        throw new Error(`No shift found on ${shiftDate}`);
      }

      // Insert into shift_attachments table
      const { error: attachError } = await this.supabase
        .from("shift_attachments")
        .insert({
          shift_id: shift.id,
          user_id: this.userId,
          file_url: photoUrl || photoId,
          file_type: "image",
          created_at: new Date().toISOString(),
        });

      if (attachError) throw attachError;

      return {
        success: true,
        message: `Photo attached to shift on ${shiftDate}`,
      };
    } catch (e: any) {
      return {
        success: false,
        message: `Error attaching photo: ${e.message}`,
      };
    }
  }

  private async removePhotoFromShift(args: any) {
    const { shiftDate, photoId } = args;

    try {
      // Get the shift for this date
      const { data: shift, error: shiftError } = await this.supabase
        .from("shifts")
        .select("id")
        .eq("user_id", this.userId)
        .eq("date", shiftDate)
        .single();

      if (shiftError || !shift) {
        throw new Error(`No shift found on ${shiftDate}`);
      }

      // Delete from shift_attachments table
      const { error: deleteError } = await this.supabase
        .from("shift_attachments")
        .delete()
        .eq("shift_id", shift.id)
        .eq("id", photoId);

      if (deleteError) throw deleteError;

      return {
        success: true,
        message: `Photo removed from shift on ${shiftDate}`,
      };
    } catch (e: any) {
      return {
        success: false,
        message: `Error removing photo: ${e.message}`,
      };
    }
  }

  private async getShiftPhotos(args: any) {
    const { shiftDate } = args;

    try {
      // Get the shift for this date
      const { data: shift, error: shiftError } = await this.supabase
        .from("shifts")
        .select("id")
        .eq("user_id", this.userId)
        .eq("date", shiftDate)
        .single();

      if (shiftError || !shift) {
        return {
          success: true,
          photos: [],
          message: `No shift found on ${shiftDate}`,
        };
      }

      // Get attachments for this shift
      const { data: attachments, error: attachError } = await this.supabase
        .from("shift_attachments")
        .select("id, file_url, file_type, created_at")
        .eq("shift_id", shift.id)
        .eq("file_type", "image");

      if (attachError) throw attachError;

      return {
        success: true,
        photos: attachments || [],
        count: attachments?.length || 0,
        message: attachments?.length 
          ? `Found ${attachments.length} photo(s) for shift on ${shiftDate}`
          : `No photos attached to shift on ${shiftDate}`,
      };
    } catch (e: any) {
      return {
        success: false,
        photos: [],
        message: `Error getting photos: ${e.message}`,
      };
    }
  }

  private async calculateShiftTotal(args: any) {
    const { shiftDate } = args;

    const { data: shift, error } = await this.supabase
      .from("shifts")
      .select("*")
      .eq("user_id", this.userId)
      .eq("date", shiftDate)
      .single();

    if (error || !shift) {
      throw new Error(`No shift found on ${shiftDate}`);
    }

    // Recalculate
    const totalTips = (shift.cash_tips || 0) + (shift.credit_tips || 0);
    const netTips = totalTips - (shift.tip_outs || 0);
    const hourlyWages = (shift.hourly_rate || 0) * (shift.hours_worked || 0);
    const totalIncome = hourlyWages + netTips;

    // Update if different
    if (shift.total_income !== totalIncome) {
      await this.supabase
        .from("shifts")
        .update({
          total_tips: totalTips,
          net_tips: netTips,
          hourly_wages: hourlyWages,
          total_income: totalIncome,
        })
        .eq("id", shift.id);
    }

    return {
      success: true,
      totalIncome: totalIncome,
      breakdown: {
        cashTips: shift.cash_tips,
        creditTips: shift.credit_tips,
        tipOuts: shift.tip_outs,
        netTips: netTips,
        hourlyWages: hourlyWages,
        totalIncome: totalIncome,
      },
    };
  }

  private async duplicateShift(args: any) {
    const { sourceDate, targetDate, copyPhotos = false } = args;

    // Get source shift
    const { data: sourceShift, error: findError } = await this.supabase
      .from("shifts")
      .select("*")
      .eq("user_id", this.userId)
      .eq("date", sourceDate)
      .single();

    if (findError || !sourceShift) {
      throw new Error(`No shift found on ${sourceDate}`);
    }

    // Create duplicate with new date
    const { data: newShift, error: insertError } = await this.supabase
      .from("shifts")
      .insert({
        ...sourceShift,
        id: undefined, // Let database generate new ID
        date: targetDate,
        created_at: undefined,
      })
      .select()
      .single();

    if (insertError) throw insertError;

    return {
      success: true,
      message: `Duplicated shift from ${sourceDate} to ${targetDate}`,
      newShift: newShift,
    };
  }
}
