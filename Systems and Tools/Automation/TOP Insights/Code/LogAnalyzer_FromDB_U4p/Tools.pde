// Time
// Date
import java.util.Date;
import java.time.ZoneId;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

Date now;

public long getNowEpoch () {
  now = new Date ();
  return now.getTime();
}

Long dateTimeToEpoch (String dateTimeString, String pattern) {
  try {
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern (pattern);
    LocalDateTime localDateTime = LocalDateTime.parse(dateTimeString, formatter);

    // Convert LocalDateTime to ZonedDateTime with system default Time Zone
    ZoneId zoneId = ZoneId.systemDefault ();
    ZonedDateTime zonedDateTime = localDateTime.atZone (zoneId);

    Instant instant = zonedDateTime.toInstant (); // Convert ZonedDateTime to Instant
    return instant.toEpochMilli (); // Return milliseconds since epoch
  } 
  catch (Exception e) {
    System.err.println ("Error converting date to UNIX: " + e);
    return null;
  }
}
Long dateToEpoch (String dateString, String pattern) {
  return dateTimeToEpoch (dateString + " 12:00:00 AM", pattern + " hh:mm:ss a");
}
Long getDawnEpoch (String dateString, String pattern) {
  try {
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern (pattern);
    LocalDate localDate = LocalDate.parse (dateString, formatter);

    // Convert LocalDate to ZonedDateTime with system default Time Zone
    ZoneId zoneId = ZoneId.systemDefault();
    ZonedDateTime zonedDateTime = localDate.atStartOfDay (zoneId);

    Instant instant = zonedDateTime.toInstant(); // Convert ZonedDateTime to Instant
    return instant.getEpochSecond()*1000;
  } 
  catch (Exception e) {
    System.err.println ("Error converting date to UNIX: " + e);
    return null;
  }
}
Long getNextDawn (Long currentDayMillis) {
  LocalDateTime dateTime = Instant.ofEpochMilli (currentDayMillis)
    .atZone(ZoneId.systemDefault())
    .toLocalDateTime();

  // Move to the start of the next day
  LocalDateTime nextDayStart = dateTime.toLocalDate().plusDays(1).atStartOfDay();

  // Convert LocalDateTime back to UNIX timestamp (milliseconds)
  return nextDayStart.atZone (ZoneId.systemDefault()).toInstant ().toEpochMilli ();
}
Long getDuskTime (Long currentDayMillis) {
  return getNextDawn (currentDayMillis) - 1;
}

import java.time.Duration;
public static String getFormattedDuration(long millis) {
  // Ensure millis is non-negative
  if (millis < 0) return null;

  Duration duration = Duration.ofMillis(millis);

  // Extract components
  long totalSeconds = duration.getSeconds();
  long seconds = totalSeconds % 60;
  long minutes = (totalSeconds / 60) % 60;
  long hours = (totalSeconds / (60 * 60)) % 24;
  long days = (totalSeconds / (60 * 60 * 24)) % 30; // Approximate days in a month
  long months = (totalSeconds / (60 * 60 * 24 * 30)) % 12; // Approximate months in a year
  long years = totalSeconds / (60 * 60 * 24 * 365); // Approximate years
  long millisPart = millis % 1000; // Remaining milliseconds

  // Format the output
  String formatted = (years > 0 ? years + "yr " : "") +
    (months > 0 ? months + "mo " : "") +
    (days > 0 ? days + "d " : "") +
    (hours > 0 ? hours + "hr " : "") +
    (minutes > 0 ? minutes + "m " : "") +
    (seconds > 0 ? nfs ((int) seconds, 2).trim () + "s " : "")
    //+ (millisPart > 0 ? millisPart + "ms" : "")
  ;

  // Handle the case where all components are zero
  if (formatted.trim().isEmpty()) {
    formatted = "0ms";
  }

  return formatted.trim();
}
LocalDateTime getLocalDateTime (Long epochMillis) {
  Instant instant = Instant.ofEpochMilli (epochMillis);
  return LocalDateTime.ofInstant (instant, ZoneId.of("UTC+3"));
}
String getFormattedDateTime (Long epochMillis, String pattern) {
  DateTimeFormatter formatter = DateTimeFormatter.ofPattern(pattern);
  return getLocalDateTime (epochMillis).format(formatter);
}
String getFormattedTime (Long epochMillis) {
  return getFormattedDateTime (epochMillis, "hh:mm:ss a");
}
String getFormattedDate (Long epochMillis) {
  return getFormattedDateTime (epochMillis, "MMM dd, yyyy");
}

boolean isMillisPresentDay (Long millis) {
  return getFormattedDate (millis).equals (getFormattedDate (getNowEpoch ()));
}

List <Long> stringToLongList (List <String> input) {
  List <Long> output = new ArrayList <Long> ();

  for (String number : input) {
    try {
      output.add (Long.parseLong (number));
    } 
    catch (Exception e) {
      output.add (null);
    }
  }

  return output;
}
List <Integer> stringToIntegerList (List <String> input) {
  List <Integer> output = new ArrayList <Integer> ();

  for (String number : input) {
    try {
      output.add (Integer.parseInt (number));
    } 
    catch (Exception e) {
      output.add (null);
    }
  }

  return output;
}

Long minLong (Long val1, Long val2) {
  if (val1 == null || val2 == null) return null;

  return val1 < val2? val1 : val2;
}
Long maxLong (Long val1, Long val2) {
  if (val1 == null || val2 == null) return null;

  return val1 > val2? val1 : val2;
}
