// Validators - Input validation and sanitization
export class Validators {
  static isValidDate(dateStr: string): boolean {
    // Check YYYY-MM-DD format
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
      return false;
    }

    const date = new Date(dateStr);
    return date instanceof Date && !isNaN(date.getTime());
  }

  static isValidAmount(amount: any): boolean {
    const num = parseFloat(amount);
    return !isNaN(num) && num >= 0 && num <= 1000000; // Max $1M per shift (sanity check)
  }

  static isValidHours(hours: any): boolean {
    const num = parseFloat(hours);
    return !isNaN(num) && num >= 0 && num <= 24; // Max 24 hours per shift
  }

  static isValidHourlyRate(rate: any): boolean {
    const num = parseFloat(rate);
    return !isNaN(num) && num >= 0 && num <= 500; // Max $500/hr (sanity check)
  }

  static isValidUUID(uuid: string): boolean {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    return uuidRegex.test(uuid);
  }

  static sanitizeString(str: string): string {
    // Remove HTML tags
    str = str.replace(/<[^>]*>/g, "");

    // Trim whitespace
    str = str.trim();

    // Limit length
    if (str.length > 1000) {
      str = str.substring(0, 1000);
    }

    return str;
  }

  static sanitizeNumber(num: any, min: number = 0, max: number = Infinity): number {
    const parsed = parseFloat(num);
    if (isNaN(parsed)) return 0;
    return Math.max(min, Math.min(max, parsed));
  }

  static validateJobName(name: string): { valid: boolean; error?: string } {
    if (!name || name.trim().length === 0) {
      return { valid: false, error: "Job name cannot be empty" };
    }

    if (name.length > 100) {
      return { valid: false, error: "Job name too long (max 100 characters)" };
    }

    return { valid: true };
  }

  static validateEventName(name: string): { valid: boolean; error?: string } {
    if (name && name.length > 200) {
      return { valid: false, error: "Event name too long (max 200 characters)" };
    }

    return { valid: true };
  }

  static validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  static parseThemeName(input: string): string {
    const themeMap: Record<string, string> = {
      "light mode": "cash_light",
      light: "cash_light",
      dark: "cash_app",
      "dark mode": "cash_app",
      "finance green": "cash_app",
      green: "cash_app",
      blue: "midnight_blue",
      purple: "purple_reign",
      ocean: "ocean_breeze",
      sunset: "sunset_glow",
      neon: "neon_cash",
      paypal: "paypal_blue",
      crypto: "coinbase_pro",
      "cash light": "cash_light",
      "finance light": "light_blue",
      "purple light": "purple_light",
      "sunset light": "sunset_light",
      "ocean light": "ocean_light",
      "pink light": "pink_light",
      "slate light": "slate_light",
      "mint light": "mint_light",
      "lavender light": "lavender_light",
      "gold light": "gold_light",
    };

    const lower = input.toLowerCase().trim();
    return themeMap[lower] || input;
  }
}
