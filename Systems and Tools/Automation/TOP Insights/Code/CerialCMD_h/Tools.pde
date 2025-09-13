import java.io.BufferedReader;
import java.io.InputStreamReader;

import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

String [] getCMDresponse (String command) {
  try {
    if (command == null || command.isEmpty()) return null;

    String line;
    String processList = "";

    Process p = java.lang.Runtime.getRuntime().exec (command);
    BufferedReader input =
      new BufferedReader(new InputStreamReader(p.getInputStream()));
    while ((line = input.readLine()) != null) {
      if (!line.isEmpty()) processList += line + "\n";
    }
    if (processList.length () > 0) processList = processList.substring (0, processList.length () - 1);

    input.close();

    String [] output = split (processList, "\n");
    return output.length == 0? null : output;
  } 
  catch (Exception e) {
    println ("Error executing a command: " + e);
  }

  return null;
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
String getTime (Long epochMillis, String pattern) {
  DateTimeFormatter formatter = DateTimeFormatter.ofPattern (pattern);
  return getLocalDateTime (epochMillis).format (formatter);
}
String getTime (Long epochMillis) {
  return getTime (epochMillis, "h_a");
}
String getTimeNow (String pattern) {
  return getTime (getNowEpoch (), pattern);
}
String getDateTimestamp () {
  return "[" + getDateToday("dd MMM yyyy") + " " + getTimeNow ("h:mm:ss a") + "]";
}

// File
void copyFile (File fromFile, File toFile) {
  copyFile (fromFile, toFile, false);
}
void moveFile (File fromFile, File toFile) {
  copyFile (fromFile, toFile, true);
}
void copyFile (File fromFile, File toFile, boolean delete) {
  try {
    toFile.mkdirs ();
    Files.copy(fromFile.toPath (), 
      toFile.toPath(), 
      StandardCopyOption.REPLACE_EXISTING);
    if (delete) fromFile.delete ();
  }
  catch (Exception e) {
    println ("Error Moving File:", e);
  }
}

// Nir CMD
class NirCMD {
  String path = "";

  NirCMD () {
    File dataFile = new File (dataPath (""));
    String toolsPath = dataFile.getParent () + "/tools";
    path = toolsPath + "/nircmd.exe";
  }
  
  void setVolume (float volume) {
    int volumeValue = int (65535*0.01*volume);
    String command = "\"" + path + "\" " + "setsysvolume " + volumeValue;
    launch (command);
  }
}
