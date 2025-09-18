import java.util.Date;
import java.time.ZoneId;
import org.apache.commons.lang3.StringUtils;

// Robot and Clipboard
import java.awt.Robot;
import java.awt.Toolkit;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import java.awt.datatransfer.*;

import java.util.HashMap;
import java.util.Map;

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

String removeMultiSpace (String content) {
  return content.replaceAll("\\s+", " ").trim ();
}
String getLetters (String input) {
  if (input == null) return null;

  input = removeMultiSpace (input).trim ();
  if (input.isEmpty()) return null;

  String letters = "";
  for (char c : input.toCharArray ()) {
    if (Character.isAlphabetic (c)) letters += c;
  }

  return letters;
}
String getPositiveInt (String input) {
  if (input == null) return null;

  String integer = "";
  for (char c : input.toCharArray ()) if (Character.isDigit (c)) integer += c;

  return integer;
}
String getNumber (String input) {
  if (input == null) return null;

  input = removeMultiSpace (input).trim ();
  if (input.isEmpty()) return null;

  String number = "";
  for (char c : input.toCharArray ()) {
    if (number.contains (".") && c == '.') return null;
    if (Character.isDigit (c) || c == '.' || c == '-') number += c;
  }

  if (number.contains("-") && !number.startsWith("-")) return null;
  if (number.contains(".") && (number.startsWith (".") || number.endsWith ("."))) return null;

  return number;
}
String getAlphaNumerics (String input) {
  if (input == null) return null;

  input = input.replace (" ", "");
  if (input.isEmpty()) return null;

  String alphas = "";
  for (char c : input.toCharArray ()) {
    if (Character.isAlphabetic (c) || Character.isDigit (c)) alphas += c;
  }

  return alphas.toUpperCase ();
}

import java.math.BigInteger;
public static boolean isValidInteger (String str) {
  if (str == null || str.isEmpty()) return false;
  try {
    new BigInteger(str);
    return true;
  } 
  catch (NumberFormatException e) {
    return false;
  }
}

import java.math.BigDecimal;
import java.text.DecimalFormat;

String nfcBig (double value, int dp) {
  return nfcBig (Double.toString (value), dp);
}
String nfcBig (float value, int dp) {
  return nfcBig (Float.toString (value), dp);
}
String nfcBig (String value, int dp) {
  return nfcBig (value, dp, "0");
}
String nfcBig (String value, int dp, String patternStr) {
  // Convert to BigDecimal via String to avoid float inaccuracies
  BigDecimal num = new BigDecimal(value);

  // Round to specified decimal places
  num = num.setScale(dp, BigDecimal.ROUND_HALF_UP);

  // Build a dynamic DecimalFormat pattern based on dp
  StringBuilder pattern = new StringBuilder (patternStr);
  if (dp > 0) {
    pattern.append(".");
    for (int i = 0; i < dp; i++) pattern.append("0");
  }

  DecimalFormat formatter = new DecimalFormat(pattern.toString());
  return formatter.format(num);
}

String nfBig (double value, int dp) {
  return nfBig (Double.toString (value), dp);
}
String nfBig (float value, int dp) {
  return nfBig (Float.toString (value), dp);
}
String nfBig (String value, int dp) {
  // Convert to BigDecimal via String to avoid float inaccuracies
  BigDecimal num = new BigDecimal(value);

  // Round to specified decimal places
  num = num.setScale(dp, BigDecimal.ROUND_HALF_UP);

  // Build a dynamic DecimalFormat pattern based on dp
  StringBuilder pattern = new StringBuilder("0");
  if (dp > 0) {
    pattern.append(".");
    for (int i = 0; i < dp; i++) pattern.append("0");
  }

  DecimalFormat formatter = new DecimalFormat(pattern.toString());
  return formatter.format(num);
}

processing.data.StringList getWrappedLines (String str, float maxWidth, PFont font, float textSize) {
  String [] words = splitTokens (str, " ");
  processing.data.StringList lines = new processing.data.StringList ();
  String currentLine = "";

  textFont (font, textSize);

  for (String word : words) {
    if (textWidth(currentLine + (currentLine.length() > 0 ? " " : "") + word) <= maxWidth)
      currentLine += (currentLine.length() > 0 ? " " : "") + word;
    else {
      lines.append(currentLine);
      currentLine = word;
    }
  }
  if (currentLine.length() > 0) lines.append(currentLine);

  return lines;
}

import com.ibm.icu.text.RuleBasedNumberFormat;
import java.util.Locale;

String numberToWords (String numberStr) {
  BigDecimal amount = new BigDecimal(numberStr).setScale(2, BigDecimal.ROUND_HALF_UP);
  long birr = amount.longValue();
  int cents = amount.remainder(BigDecimal.ONE).movePointRight(2).intValue();

  RuleBasedNumberFormat formatter = new RuleBasedNumberFormat(Locale.ENGLISH, RuleBasedNumberFormat.SPELLOUT);

  String birrWords = formatter.format(birr);
  String centsWords = formatter.format(cents);

  return titleCase (birrWords) + " " + CURRENCY_NAME_BILL + " and  " +
    titleCase (centsWords) + "  " + CURRENCY_NAME_CENTS + " Only";
}
String titleCase(String input) {
  input = input.replaceAll("-", " ");
  String[] words = input.trim().split("\\s+");
  StringBuilder result = new StringBuilder();
  for (int i = 0; i < words.length; i++) {
    String word = words[i];
    if (word.equalsIgnoreCase ("and")) continue;
    result.append(Character.toUpperCase(word.charAt(0)))
      .append(word.substring(1).toLowerCase());
    if (i < words.length - 1) result.append(" ");
  }
  return result.toString().replace (",", "");
}

// File Checksum
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Paths;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class FileChecksum {
  private final ByteBuffer buffer;
  private final MessageDigest md;
  private static final String DEFAULT_ALGORITHM = "MD5";
  private static final int DEFAULT_BUFFER_SIZE = 8192;

  public FileChecksum() throws NoSuchAlgorithmException {
    this(DEFAULT_ALGORITHM, DEFAULT_BUFFER_SIZE);
  }

  public FileChecksum(String algorithm, int bufferSize) throws NoSuchAlgorithmException {
    this.md = MessageDigest.getInstance(algorithm);
    this.buffer = ByteBuffer.allocateDirect(bufferSize); // Direct buffer for performance
  }

  public String get(String filePath) {
    if (!new File(filePath).exists()) return null;
    md.reset(); // Reset the digest before processing a new file

    Path path = Paths.get(filePath);
    try { // Use try-with-resources
      FileChannel channel = FileChannel.open(path);
      while (channel.read(buffer) != -1) {
        buffer.flip();
        md.update(buffer);
        buffer.clear();
      }

      // Get the hash's bytes
      byte[] mdbytes = md.digest();

      // Convert the byte to hex format
      StringBuilder sb = new StringBuilder();
      for (byte b : mdbytes) { // Simplified loop using enhanced for loop
        sb.append(String.format("%02x", b));
      }

      return sb.toString();
    } 
    catch (IOException e) {
      System.err.println("Exception in obtaining file checksum for " + filePath + ": " + e.getMessage());
      cLogger.log ("Exception in obtaining file checksum for " + filePath + ": " + e.getMessage());
      return null;
    }
  }
}

FileChecksum checksum;
boolean isFileCreationComplete(String path, int timeout) {
  if (!new File(path).exists()) return false;

  long startTime = millis();
  String lastChecksum = null;

  while (millis() - startTime < timeout) {
    String currentChecksum = checksum.get(path);
    if (currentChecksum == null) return false; // File inaccessible
    if (lastChecksum != null && lastChecksum.equals(currentChecksum)) {
      return true; // Checksum stable
    }
    lastChecksum = currentChecksum;
    delay(200); // Increase delay to reduce resource contention
  }

  return false; // Timeout reached, file not stable
}

// Random String Generator
import org.apache.commons.lang3.RandomStringUtils;
