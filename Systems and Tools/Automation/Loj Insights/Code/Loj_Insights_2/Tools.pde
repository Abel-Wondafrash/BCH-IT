import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.time.DayOfWeek;

static class DateUtils {
  static long toEpochMillis(String timestamp) {
    try {
      // Parse the date-only string (e.g., "2025-05-26")
      LocalDate localDate = LocalDate.parse(timestamp);

      // Convert to ZonedDateTime at start of day in system default time zone
      ZonedDateTime zonedDate = localDate.atStartOfDay(ZoneId.systemDefault());

      // Convert to epoch milliseconds
      return zonedDate.toInstant().toEpochMilli();
    } 
    catch (Exception e) {
      System.out.println("Error parsing timestamp: " + e.getMessage());
      return -1;
    }
  }

  static LocalDateTime getLocalDateTime(Long epochMillis) {
    Instant instant = Instant.ofEpochMilli(epochMillis);
    // Interpret as UTC+3 time
    return LocalDateTime.ofInstant(instant, ZoneId.of("UTC+3"));
  }

  static String formatDate(Long epochMillis, String pattern) {
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern(pattern);
    return getLocalDateTime(epochMillis).format(formatter);
  }
  static String formatDateToday(String pattern) {
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern(pattern);
    LocalDateTime now = LocalDateTime.now(ZoneId.of("UTC+3"));
    return now.format(formatter);
  }
  static String formatDate(String pattern, int dayOffset) {
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern(pattern);
    // Get today in UTC+3 and apply the offset
    LocalDateTime adjustedDate = LocalDateTime.now(ZoneId.of("UTC+3")).plusDays(dayOffset);
    return adjustedDate.format(formatter);
  }


  public static boolean isValidDateFormat (String dateStr, String pattern) {
    if (dateStr == null || dateStr.isEmpty() || pattern == null || pattern.isEmpty()) return false;

    try {
      DateTimeFormatter formatter = DateTimeFormatter.ofPattern(pattern);
      formatter.parse(dateStr); // Parses without needing to convert to LocalDate/DateTime
      return true;
    } 
    catch (DateTimeParseException e) {
      return false;
    }
  }
  public static boolean isSunday (String dateStr) {
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern(VALID_DATE_FORMAT);
    LocalDate date = LocalDate.parse(dateStr, formatter);

    return date.getDayOfWeek() == DayOfWeek.SUNDAY;
  }
  public static String getWeekStartDate(String dateStr) {
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern(VALID_DATE_FORMAT);
    LocalDate date = LocalDate.parse(dateStr, formatter);

    if (date.getDayOfWeek() != DayOfWeek.SUNDAY) return null; // Only allow Sunday as valid input

    // Since we're on Sunday, minus 6 days to get to Monday (start of the week)
    LocalDate startDate = date.minusDays(6);

    return startDate.format(formatter);
  }
  public static String getWeekEndDate(String dateStr) {
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern(VALID_DATE_FORMAT);
    LocalDate date = LocalDate.parse(dateStr, formatter);

    if (date.getDayOfWeek() != DayOfWeek.MONDAY) return null; // Only allow Monday as valid input

    // Since we're on Monday, add 6 days to get to Sunday (end of the week)
    LocalDate endDate = date.plusDays(6);

    return endDate.format(formatter);
  }

  public static String getWeekNumber(String dateStr) {
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    LocalDate date = LocalDate.parse(dateStr, formatter);

    // ISO week: Monday is first day of the week, and week 1 contains first Thursday
    int number = date.get(java.time.temporal.WeekFields.ISO.weekOfYear());
    return nf (number, 2);
  }
}

Comparator <Customer> customerNameComparator () {
  return new Comparator <Customer> () {
    public int compare (Customer c1, Customer c2) {
      return c1.getName ().compareTo (c2.getName ());
    }
  };
}

StringList getDaysBetween (String fromDate, String toDate) {
  StringList list = null;
  try {
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    LocalDate startDate = LocalDate.parse(fromDate);
    LocalDate endDate = LocalDate.parse(toDate);

    LocalDate currentDate = startDate;

    list = new StringList ();
    while (!currentDate.isAfter(endDate)) {
      if (currentDate.getDayOfWeek().getValue() != 7) { // 7 = Sunday
        String dateStr = currentDate.format(formatter);
        list.append (dateStr);
      }
      currentDate = currentDate.plusDays(1);
    }
  } 
  catch (Exception e) {
    println ("Error obtaining days between", fromDate, toDate, e);
  }
  return list;
}
