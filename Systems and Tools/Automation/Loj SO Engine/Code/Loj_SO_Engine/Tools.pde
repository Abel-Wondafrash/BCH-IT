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

// Files
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

boolean copyFile (File fromFile, File toFile) {
  return copyFile (fromFile, toFile, false);
}
boolean copyFile (String fromPath, String toPath) {
  return copyFile (new File (fromPath), new File (toPath));
}
boolean moveFile (File fromFile, File toFile) {
  return copyFile (fromFile, toFile, true);
}
boolean moveFile (String fromPath, String toPath) {
  return moveFile (new File (fromPath), new File (toPath));
}
boolean copyFile (File fromFile, File toFile, boolean delete) {
  try {
    createMissingParentDirs (fromFile.getAbsolutePath ());
    createMissingParentDirs (toFile.getAbsolutePath ());

    Files.copy(fromFile.toPath (), 
      toFile.toPath(), 
      StandardCopyOption.REPLACE_EXISTING);

    if (delete) Files.delete (fromFile.toPath ());

    return true;
  }
  catch (Exception e) {
    println ("Error Moving File:", e, delete);
    println ("\t", fromFile.toPath ());
    println ("\t", toFile.toPath ());
    cLogger.log ("Error Moving File: " + e + " " + delete + " " + fromFile.toPath () + " " + toFile.toPath ());
    return false;
  }
}
boolean copyFile (String fromPath, String toPath, boolean delete) {
  return copyFile (new File (fromPath), new File (toPath), delete);
}

void createMissingParentDirs (String path) {
  File file = new File (path);
  File parent = file.getParentFile();
  if (parent.exists()) return;

  parent.mkdirs ();
}

// Network
import java.net.InetAddress;
boolean connectedToNetwork () {
  try {
    String homeIP = InetAddress.getLoopbackAddress().getHostAddress ();
    return !homeIP.equals (InetAddress.getLocalHost ().getHostAddress ());
  } 
  catch (Exception e) {
    println ("Error checking if connected to network:", e);
    cLogger.log ("Error checking if connected to network: " + e);
    return false;
  }
}

// Time
// Date
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
  return LocalDateTime.ofInstant (instant, ZoneId.of ("UTC+3"));
}
String getDate (Long epochMillis, String pattern) {
  DateTimeFormatter formatter = DateTimeFormatter.ofPattern (pattern);
  return getLocalDateTime (epochMillis).format(formatter);
}
String getDateToday (String pattern) {
  return getDate (getNowEpoch (), pattern);
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

// Random String Generator
import org.apache.commons.lang3.RandomStringUtils;
String abbreviate (String input, int length) {
  return StringUtils.abbreviate(input, length);
}

import org.apache.commons.lang3.math.NumberUtils;
boolean isValidNum (String numStr) {
  return NumberUtils.isCreatable(numStr);
}

String getOrDash (String value) {
  return value == null? GET_OR_DASH_DEFAULT : value;
}

String getDigits (String input) {
  String digits = "";
  if (input == null) return "";

  for (char c : input.toCharArray()) if (Character.isDigit(c)) digits += c;
  return digits;
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

boolean containsNull (String elements []) {
  if (elements == null) return true;

  for (String element : elements) if (element == null) return true;

  return false;
}
class NullValidator {
  processing.data.StringDict elements;

  NullValidator () {
    elements = new processing.data.StringDict ();
  }

  NullValidator add (String tag, String element) {
    elements.set (tag, element);
    return this;
  }
  NullValidator clear () {
    elements.clear ();
    return this;
  }

  boolean containsNull () {
    return getNullTags ().length != 0;
  }
  String [] getNullTags () {
    String nullTags [] = new String [0];

    for (String tag : elements.keys ())
      if (elements.get (tag) == null) nullTags = append (nullTags, tag);

    return nullTags;
  }
}

import java.math.BigDecimal;
import java.text.DecimalFormat;

import java.math.BigDecimal;
import java.text.DecimalFormat;

String nfcBig (double value, int dp) {
  return nfcBig (Double.toString (value), dp);
}
String nfcBig (float value, int dp) {
  return nfcBig (Float.toString (value), dp);
}
String nfcBig (String value, int dp) {
  // Convert to BigDecimal via String to avoid float inaccuracies
  BigDecimal num = new BigDecimal(value);

  // Round to specified decimal places
  num = num.setScale(dp, BigDecimal.ROUND_HALF_UP);

  // Build a dynamic DecimalFormat pattern based on dp
  StringBuilder pattern = new StringBuilder("#,##0");
  if (dp > 0) {
    pattern.append(".");
    for (int i = 0; i < dp; i++) pattern.append("0");
  }

  DecimalFormat formatter = new DecimalFormat(pattern.toString());
  return formatter.format(num);
}
