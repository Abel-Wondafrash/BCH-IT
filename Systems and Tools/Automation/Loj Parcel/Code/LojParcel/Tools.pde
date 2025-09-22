import java.util.Date;
import java.time.ZoneId;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
Date now;
public long getNowEpoch () {
  now = new Date ();
  return now.getTime();
}
LocalDateTime getLocalDateTime (Long epochMillis) {
  Instant instant = Instant.ofEpochMilli (epochMillis);
  return LocalDateTime.ofInstant (instant, ZoneId.of("UTC+3"));
}
String getFormattedDate (Long epochMillis) {
  DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd-MMM-yyyy");
  return getLocalDateTime (epochMillis).format(formatter);
}
String getDate (Long epochMillis, String pattern) {
  DateTimeFormatter formatter = DateTimeFormatter.ofPattern (pattern);
  return getLocalDateTime (epochMillis).format(formatter);
}
String getNow (String pattern) {
  DateTimeFormatter formatter = DateTimeFormatter.ofPattern (pattern);
  return getLocalDateTime (getNowEpoch ()).format(formatter);
}
String getDateToday (String pattern) {
  return getDate (getNowEpoch (), pattern);
}

String getDigits (String input) {
  String digits = "";
  if (input == null) return "";

  for (char c : input.toCharArray()) if (Character.isDigit(c)) digits += c;
  return digits;
}

// Random String Generator
import org.apache.commons.lang3.RandomStringUtils;
String abbreviate (String input, int length) {
  return StringUtils.abbreviate(input, length);
}
