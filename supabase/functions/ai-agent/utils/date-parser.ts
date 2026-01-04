// Date Parser - Converts natural language dates to YYYY-MM-DD format
export class DateParser {
  // Store the user's local date for reference (set from the request)
  private static userLocalDate: Date | null = null;

  /**
   * Set the user's local date to use as reference for "today", "yesterday", etc.
   * Call this at the start of each request with the user's local date.
   * @param localDateStr - The user's local date in YYYY-MM-DD format
   */
  static setUserLocalDate(localDateStr: string | null): void {
    if (localDateStr && /^\d{4}-\d{2}-\d{2}$/.test(localDateStr)) {
      const [year, month, day] = localDateStr.split('-').map(Number);
      // Create date at noon to avoid any timezone edge cases
      this.userLocalDate = new Date(year, month - 1, day, 12, 0, 0);
      console.log(`[DateParser] Set user local date to: ${localDateStr}`);
    } else {
      this.userLocalDate = null;
    }
  }

  /**
   * Get the reference date - user's local date if set, otherwise server time
   */
  private static getNow(): Date {
    if (this.userLocalDate) {
      // Return a copy to avoid mutations
      return new Date(this.userLocalDate.getTime());
    }
    return new Date();
  }

  static parse(dateStr: string): string {
    const lower = dateStr.toLowerCase().trim();
    const now = this.getNow();

    // Handle exact formats first
    if (/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
      return dateStr; // Already in YYYY-MM-DD
    }

    // Common keywords
    if (lower === "today") {
      return this.formatDate(now);
    }

    if (lower === "yesterday") {
      const yesterday = new Date(now);
      yesterday.setDate(now.getDate() - 1);
      return this.formatDate(yesterday);
    }

    if (lower === "tomorrow") {
      const tomorrow = new Date(now);
      tomorrow.setDate(now.getDate() + 1);
      return this.formatDate(tomorrow);
    }

    // Relative days (e.g., "3 days ago", "2 weeks from now")
    const relativeMatch = lower.match(/(\d+)\s+(day|week|month)s?\s+(ago|from now)/);
    if (relativeMatch) {
      const amount = parseInt(relativeMatch[1]);
      const unit = relativeMatch[2];
      const direction = relativeMatch[3] === "ago" ? -1 : 1;

      const date = new Date(now);
      if (unit === "day") {
        date.setDate(now.getDate() + amount * direction);
      } else if (unit === "week") {
        date.setDate(now.getDate() + amount * 7 * direction);
      } else if (unit === "month") {
        date.setMonth(now.getMonth() + amount * direction);
      }

      return this.formatDate(date);
    }

    // Day of week (e.g., "last Tuesday", "next Friday")
    const dayOfWeekMatch = lower.match(/(last|next)\s+(sunday|monday|tuesday|wednesday|thursday|friday|saturday)/);
    if (dayOfWeekMatch) {
      const direction = dayOfWeekMatch[1];
      const targetDay = dayOfWeekMatch[2];
      const targetDayNum = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"].indexOf(targetDay);
      const currentDayNum = now.getDay();

      let daysOffset: number;
      if (direction === "last") {
        daysOffset = currentDayNum - targetDayNum;
        if (daysOffset <= 0) daysOffset += 7;
        daysOffset = -daysOffset;
      } else {
        daysOffset = targetDayNum - currentDayNum;
        if (daysOffset <= 0) daysOffset += 7;
      }

      const date = new Date(now);
      date.setDate(now.getDate() + daysOffset);
      return this.formatDate(date);
    }

    // "the 22nd" (day of month)
    const dayMatch = lower.match(/the\s+(\d{1,2})(st|nd|rd|th)?/);
    if (dayMatch) {
      const day = parseInt(dayMatch[1]);
      const date = new Date(now.getFullYear(), now.getMonth(), day);

      // If the day has already passed this month, assume they mean last month
      if (date > now) {
        date.setMonth(date.getMonth() - 1);
      }

      return this.formatDate(date);
    }

    // "December 22nd" or "Dec 22"
    const monthDayMatch = lower.match(/(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})/);
    if (monthDayMatch) {
      const monthStr = monthDayMatch[1];
      const day = parseInt(monthDayMatch[2]);

      const months = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"];
      const shortMonths = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];

      let monthNum = months.indexOf(monthStr);
      if (monthNum === -1) {
        monthNum = shortMonths.indexOf(monthStr);
      }

      if (monthNum !== -1) {
        const year = now.getFullYear();
        const date = new Date(year, monthNum, day);

        // If date is in the future, assume last year
        if (date > now) {
          date.setFullYear(year - 1);
        }

        return this.formatDate(date);
      }
    }

    // Fallback: return original string (might be invalid, let database handle it)
    return dateStr;
  }

  private static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  }
}
