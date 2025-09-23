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

// Checksum
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
