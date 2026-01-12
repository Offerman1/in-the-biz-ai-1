/// Global currency and language constants for internationalization
/// Supports top 50 currencies and languages worldwide
library;

/// Currency model with code, symbol, and display name
class Currency {
  final String code; // ISO 4217 code (e.g., 'USD')
  final String symbol; // Display symbol (e.g., '$')
  final String name; // Full name (e.g., 'US Dollar')
  final int decimalPlaces; // Number of decimal places (usually 2)

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    this.decimalPlaces = 2,
  });

  /// Format amount with currency symbol
  String format(double amount) {
    final formatted = amount.toStringAsFixed(decimalPlaces);
    return '$symbol$formatted';
  }

  /// Format amount with currency code (for international display)
  String formatWithCode(double amount) {
    final formatted = amount.toStringAsFixed(decimalPlaces);
    return '$formatted $code';
  }
}

/// Top 50 world currencies
class Currencies {
  // North America
  static const usd = Currency(code: 'USD', symbol: '\$', name: 'US Dollar');
  static const cad =
      Currency(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar');
  static const mxn =
      Currency(code: 'MXN', symbol: 'MX\$', name: 'Mexican Peso');

  // Europe
  static const eur = Currency(code: 'EUR', symbol: '€', name: 'Euro');
  static const gbp = Currency(code: 'GBP', symbol: '£', name: 'British Pound');
  static const chf = Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc');
  static const nok =
      Currency(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone');
  static const sek = Currency(code: 'SEK', symbol: 'kr', name: 'Swedish Krona');
  static const dkk = Currency(code: 'DKK', symbol: 'kr', name: 'Danish Krone');
  static const pln = Currency(code: 'PLN', symbol: 'zł', name: 'Polish Zloty');
  static const czk = Currency(code: 'CZK', symbol: 'Kč', name: 'Czech Koruna');
  static const huf = Currency(
      code: 'HUF', symbol: 'Ft', name: 'Hungarian Forint', decimalPlaces: 0);
  static const ron = Currency(code: 'RON', symbol: 'lei', name: 'Romanian Leu');
  static const uah =
      Currency(code: 'UAH', symbol: '₴', name: 'Ukrainian Hryvnia');
  static const rub = Currency(code: 'RUB', symbol: '₽', name: 'Russian Ruble');
  static const try_ = Currency(code: 'TRY', symbol: '₺', name: 'Turkish Lira');

  // Asia Pacific
  static const jpy = Currency(
      code: 'JPY', symbol: '¥', name: 'Japanese Yen', decimalPlaces: 0);
  static const cny = Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan');
  static const hkd =
      Currency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar');
  static const sgd =
      Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar');
  static const aud =
      Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar');
  static const nzd =
      Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar');
  static const krw = Currency(
      code: 'KRW', symbol: '₩', name: 'South Korean Won', decimalPlaces: 0);
  static const inr = Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee');
  static const idr = Currency(
      code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah', decimalPlaces: 0);
  static const myr =
      Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit');
  static const php =
      Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso');
  static const thb = Currency(code: 'THB', symbol: '฿', name: 'Thai Baht');
  static const vnd = Currency(
      code: 'VND', symbol: '₫', name: 'Vietnamese Dong', decimalPlaces: 0);
  static const pkr =
      Currency(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee');
  static const bdt =
      Currency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka');
  static const lkr =
      Currency(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee');

  // Middle East
  static const aed = Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham');
  static const sar = Currency(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal');
  static const ils = Currency(code: 'ILS', symbol: '₪', name: 'Israeli Shekel');
  static const qar = Currency(code: 'QAR', symbol: 'ر.ق', name: 'Qatari Riyal');
  static const kwd = Currency(
      code: 'KWD', symbol: 'د.ك', name: 'Kuwaiti Dinar', decimalPlaces: 3);
  static const omr = Currency(
      code: 'OMR', symbol: 'ر.ع.', name: 'Omani Rial', decimalPlaces: 3);
  static const bhd = Currency(
      code: 'BHD', symbol: '.د.ب', name: 'Bahraini Dinar', decimalPlaces: 3);
  static const jod = Currency(
      code: 'JOD', symbol: 'د.ا', name: 'Jordanian Dinar', decimalPlaces: 3);

  // Africa
  static const zar =
      Currency(code: 'ZAR', symbol: 'R', name: 'South African Rand');
  static const egp =
      Currency(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound');
  static const ngn = Currency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira');
  static const kes =
      Currency(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling');
  static const mad =
      Currency(code: 'MAD', symbol: 'د.م.', name: 'Moroccan Dirham');

  // South America
  static const brl =
      Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real');
  static const ars =
      Currency(code: 'ARS', symbol: 'AR\$', name: 'Argentine Peso');
  static const clp = Currency(
      code: 'CLP', symbol: 'CL\$', name: 'Chilean Peso', decimalPlaces: 0);
  static const cop = Currency(
      code: 'COP', symbol: 'CO\$', name: 'Colombian Peso', decimalPlaces: 0);
  static const pen = Currency(code: 'PEN', symbol: 'S/', name: 'Peruvian Sol');

  /// Get all currencies as a list
  static List<Currency> get all => [
        usd, eur, gbp, jpy, cny, // Top 5 reserve currencies
        aud, cad, chf, hkd, sgd, // Major trading currencies
        nok, sek, dkk, nzd, krw, // Other developed markets
        inr, mxn, brl, zar, try_, // Large emerging markets
        rub, pln, thb, idr, myr, // Regional powers
        php, aed, sar, ils, egp, // Middle East & Africa
        ngn, kes, mad, qar, kwd, // More MENA & Africa
        omr, bhd, jod, czk, huf, // Small but important
        ron, uah, vnd, pkr, bdt, // Populous nations
        lkr, ars, clp, cop, pen, // South America
      ];

  /// Get currency by ISO code
  static Currency? getByCode(String code) {
    try {
      return all.firstWhere(
        (c) => c.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get currency codes only (for dropdowns)
  static List<String> get allCodes => all.map((c) => c.code).toList();

  /// Default currency
  static Currency get defaultCurrency => usd;
}

/// Language model with code and display name
class Language {
  final String code; // ISO 639-1 code (e.g., 'en')
  final String name; // English name (e.g., 'English')
  final String nativeName; // Native name (e.g., 'English')
  final bool rtl; // Right-to-left script

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    this.rtl = false,
  });
}

/// Top 50 world languages
class Languages {
  static const en =
      Language(code: 'en', name: 'English', nativeName: 'English');
  static const es =
      Language(code: 'es', name: 'Spanish', nativeName: 'Español');
  static const zh = Language(code: 'zh', name: 'Chinese', nativeName: '中文');
  static const hi = Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी');
  static const ar =
      Language(code: 'ar', name: 'Arabic', nativeName: 'العربية', rtl: true);
  static const pt =
      Language(code: 'pt', name: 'Portuguese', nativeName: 'Português');
  static const bn = Language(code: 'bn', name: 'Bengali', nativeName: 'বাংলা');
  static const ru =
      Language(code: 'ru', name: 'Russian', nativeName: 'Русский');
  static const ja = Language(code: 'ja', name: 'Japanese', nativeName: '日本語');
  static const pa = Language(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ');
  static const de = Language(code: 'de', name: 'German', nativeName: 'Deutsch');
  static const fr =
      Language(code: 'fr', name: 'French', nativeName: 'Français');
  static const ko = Language(code: 'ko', name: 'Korean', nativeName: '한국어');
  static const it =
      Language(code: 'it', name: 'Italian', nativeName: 'Italiano');
  static const vi =
      Language(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt');
  static const tr = Language(code: 'tr', name: 'Turkish', nativeName: 'Türkçe');
  static const ta = Language(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்');
  static const ur =
      Language(code: 'ur', name: 'Urdu', nativeName: 'اردو', rtl: true);
  static const id =
      Language(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia');
  static const pl = Language(code: 'pl', name: 'Polish', nativeName: 'Polski');
  static const uk =
      Language(code: 'uk', name: 'Ukrainian', nativeName: 'Українська');
  static const th = Language(code: 'th', name: 'Thai', nativeName: 'ไทย');
  static const ro =
      Language(code: 'ro', name: 'Romanian', nativeName: 'Română');
  static const nl =
      Language(code: 'nl', name: 'Dutch', nativeName: 'Nederlands');
  static const el = Language(code: 'el', name: 'Greek', nativeName: 'Ελληνικά');
  static const cs = Language(code: 'cs', name: 'Czech', nativeName: 'Čeština');
  static const sv =
      Language(code: 'sv', name: 'Swedish', nativeName: 'Svenska');
  static const hu =
      Language(code: 'hu', name: 'Hungarian', nativeName: 'Magyar');
  static const ca = Language(code: 'ca', name: 'Catalan', nativeName: 'Català');
  static const fi = Language(code: 'fi', name: 'Finnish', nativeName: 'Suomi');
  static const da = Language(code: 'da', name: 'Danish', nativeName: 'Dansk');
  static const no =
      Language(code: 'no', name: 'Norwegian', nativeName: 'Norsk');
  static const he =
      Language(code: 'he', name: 'Hebrew', nativeName: 'עברית', rtl: true);
  static const ms =
      Language(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu');
  static const sk =
      Language(code: 'sk', name: 'Slovak', nativeName: 'Slovenčina');
  static const hr =
      Language(code: 'hr', name: 'Croatian', nativeName: 'Hrvatski');
  static const bg =
      Language(code: 'bg', name: 'Bulgarian', nativeName: 'Български');
  static const lt =
      Language(code: 'lt', name: 'Lithuanian', nativeName: 'Lietuvių');
  static const sl =
      Language(code: 'sl', name: 'Slovenian', nativeName: 'Slovenščina');
  static const lv =
      Language(code: 'lv', name: 'Latvian', nativeName: 'Latviešu');
  static const et = Language(code: 'et', name: 'Estonian', nativeName: 'Eesti');
  static const is_ =
      Language(code: 'is', name: 'Icelandic', nativeName: 'Íslenska');
  static const sq = Language(code: 'sq', name: 'Albanian', nativeName: 'Shqip');
  static const sr = Language(code: 'sr', name: 'Serbian', nativeName: 'Српски');
  static const mk =
      Language(code: 'mk', name: 'Macedonian', nativeName: 'Македонски');
  static const bs =
      Language(code: 'bs', name: 'Bosnian', nativeName: 'Bosanski');
  static const mt = Language(code: 'mt', name: 'Maltese', nativeName: 'Malti');
  static const cy = Language(code: 'cy', name: 'Welsh', nativeName: 'Cymraeg');
  static const ga = Language(code: 'ga', name: 'Irish', nativeName: 'Gaeilge');
  static const fa =
      Language(code: 'fa', name: 'Persian', nativeName: 'فارسی', rtl: true);

  /// Get all languages as a list
  static List<Language> get all => [
        en, es, zh, hi, ar, // Most spoken
        pt, bn, ru, ja, pa, // Top 10 continued
        de, fr, ko, it, vi, // European + Asian
        tr, ta, ur, id, pl, // Regional
        uk, th, ro, nl, el, // More European
        cs, sv, hu, ca, fi, // Nordic + Central European
        da, no, he, ms, sk, // More diverse
        hr, bg, lt, sl, lv, // Baltics + Balkans
        et, is_, sq, sr, mk, // Small European
        bs, mt, cy, ga, fa, // Celtic + Persian
      ];

  /// Get language by ISO code
  static Language? getByCode(String code) {
    try {
      return all.firstWhere(
        (l) => l.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get language codes only (for dropdowns)
  static List<String> get allCodes => all.map((l) => l.code).toList();

  /// Default language
  static Language get defaultLanguage => en;
}

/// Date format options
class DateFormats {
  static const String mmddyyyy = 'MM/dd/yyyy'; // US: 01/05/2026
  static const String ddmmyyyy = 'dd/MM/yyyy'; // EU: 05/01/2026
  static const String yyyymmdd = 'yyyy-MM-dd'; // ISO: 2026-01-05
  static const String mmmddyyyy = 'MMM dd, yyyy'; // Jan 05, 2026
  static const String ddmmmyyyy = 'dd MMM yyyy'; // 05 Jan 2026

  static List<String> get all => [
        mmddyyyy,
        ddmmyyyy,
        yyyymmdd,
        mmmddyyyy,
        ddmmmyyyy,
      ];

  static String get defaultFormat => mmddyyyy;
}

/// Time format options
class TimeFormats {
  static const String hour12 = '12-hour'; // 2:30 PM
  static const String hour24 = '24-hour'; // 14:30

  static List<String> get all => [hour12, hour24];

  static String get defaultFormat => hour12;
}

/// Number format options (for currency display)
class NumberFormats {
  static const String enUS = 'en_US'; // 1,234.56
  static const String enGB = 'en_GB'; // 1,234.56
  static const String deDE = 'de_DE'; // 1.234,56
  static const String frFR = 'fr_FR'; // 1 234,56
  static const String esES = 'es_ES'; // 1.234,56
  static const String ptBR = 'pt_BR'; // 1.234,56
  static const String zhCN = 'zh_CN'; // 1,234.56
  static const String jaJP = 'ja_JP'; // 1,234.56
  static const String inIN = 'in_IN'; // 1,23,456.78 (Indian numbering)

  static List<String> get all => [
        enUS,
        enGB,
        deDE,
        frFR,
        esES,
        ptBR,
        zhCN,
        jaJP,
        inIN,
      ];

  static String get defaultFormat => enUS;
}
