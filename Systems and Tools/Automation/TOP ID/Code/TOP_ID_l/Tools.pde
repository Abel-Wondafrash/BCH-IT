import java.util.Date;
import java.time.format.DateTimeFormatter;
import java.time.Instant;
import java.time.LocalDateTime;
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

Date now;
public long getNowEpoch () {
  now = new Date ();
  return now.getTime();
}

String getFormattedDate (Long epochMillis) {
  DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd-MMM-yyyy");
  return getLocalDateTime (epochMillis).format(formatter);
}

LocalDateTime getLocalDateTime (Long epochMillis) {
  Instant instant = Instant.ofEpochMilli (epochMillis);
  return LocalDateTime.ofInstant (instant, ZoneId.of("UTC+3"));
}

PImage crop (PImage image, int x, int y, int w, int h) {
  PGraphics pg = createGraphics (w, h);

  pg.beginDraw ();
  pg.copy (image, x, y, w, h, 0, 0, w, h);
  pg.endDraw ();

  return pg;
}

String toTitleCase (String input) {
  String output = "";
  
  if (input == null) return null;
  
  input = input.toLowerCase ().trim ();
  if (input.isEmpty()) return "";
  
  String split [] = split (input, " ");
  for (String each : split) {
    output += str(each.charAt (0)).toUpperCase ();

    if (each.length () > 1) output += each.substring (1, each.length ());

    output += " ";
  }

  return output.trim ();
}

String toNameStr (String input) {
  if (input == null) return null;

  input = removeMultiSpace (input).trim ();
  if (input.isEmpty()) return null;

  String name = "";
  for (char c : input.toCharArray ()) {
    if (Character.isAlphabetic (c) || c == ' ') name += c;
    else name += "-";
  }

  return  name;
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
String getDigits (String input) {
  if (input == null) return null;

  input = removeMultiSpace (input).trim ();
  if (input.isEmpty()) return null;

  String digits = "";
  for (char c : input.toCharArray ()) {
    if (Character.isDigit (c)) digits += c;
  }

  return digits;
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
String getIDnumber (String input) {
  if (input == null) return null;
  
  input = StringUtils.reverse (input);
  
  String alphas = "";
  for (char c : input.toCharArray ()) {
    if (c == 'C' || c == 'T') {
      alphas += c;
      break;
    }
    
    if (Character.isDigit (c)) alphas += c;
  }
  alphas = StringUtils.reverse (alphas);
  
  return alphas;
}

class RobotTools {
  Robot robot;
  Map<Character, Integer[]> keyMap;

  RobotTools () {
    keyMap = createKeyMap();

    try {
      robot = new Robot();
    }
    catch (Exception e) {
      println(e.getMessage());
      exit();
    }
  }
  void press (Integer keys []) {
    for (int key : keys) robot.keyPress (key);
    for (int key : keys) robot.keyRelease (key);
    delay (40);
  }
  void press (int key) {
    robot.keyPress (key);
    robot.keyRelease (key);
    delay (40);
  }
  void TAB () {
    robot.keyPress(KeyEvent.VK_META);
    robot.keyRelease(KeyEvent.VK_TAB);
    delay(40);
  }
  void SPACE () {
    robot.keyPress(KeyEvent.VK_SPACE);
    robot.keyRelease(KeyEvent.VK_SPACE);
    delay(40);
  }
  void ALT () {
    robot.keyPress(KeyEvent.VK_ALT);
    robot.keyRelease(KeyEvent.VK_ALT);
    delay(40);
  }
  void ENTER () {
    robot.keyPress(KeyEvent.VK_ENTER);
    robot.keyRelease(KeyEvent.VK_ENTER);
    delay(40);
  }
  void toClipboard (String s) {
    StringSelection stringSelection = new StringSelection(s);
    Clipboard clpbrd = Toolkit.getDefaultToolkit().getSystemClipboard();
    clpbrd.setContents(stringSelection, null);
  }
  void mouseMoveAndClick(int x, int y) {
    robot.mouseMove(x, y);
    delay(40);
    robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
    robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
    delay(40);
  }
  void typeString(String text) {
    for (int i = 0; i < text.length(); i++) {
      char c = text.charAt(i);
      typeCharacter(c);
    }
  }

  void typeCharacter(char character) {
    // Get key codes for the character
    boolean isUpperCase = Character.isUpperCase (character);
    character = Character.toLowerCase (character);

    Integer [] keyCodes = keyMap.get (character);
    if (keyCodes == null) {
      System.out.println("Unsupported character: " + character);
      return;
    }

    boolean pressShift = keyCodes [0] == KeyEvent.VK_SHIFT || isUpperCase;
    if (pressShift) robot.keyPress (KeyEvent.VK_SHIFT);

    // Type the character
    for (Integer keyCode : keyCodes) {
      if (keyCode == KeyEvent.VK_SHIFT) continue;

      robot.keyPress(keyCode);
      robot.keyRelease(keyCode);
    }
    if (pressShift) robot.keyRelease(KeyEvent.VK_SHIFT);
  }

  Map<Character, Integer []> createKeyMap() {
    // Create a map of characters to their corresponding key codes
    Map<Character, Integer []> keyMap = new HashMap<Character, Integer []>();
    // Alphabets
    for (char c = 'a'; c <= 'z'; c ++) keyMap.put (c, new Integer [] {(65 + c - 'a')});
    // Numbers
    for (char c = '0'; c <= '9'; c ++) keyMap.put (c, new Integer [] {(48 + c - '0')});

    // Special Characters
    keyMap.put(' ', new Integer[]{KeyEvent.VK_SPACE});
    keyMap.put('.', new Integer[]{KeyEvent.VK_PERIOD});
    keyMap.put(',', new Integer[]{KeyEvent.VK_COMMA});
    keyMap.put('-', new Integer[]{KeyEvent.VK_MINUS});
    keyMap.put('=', new Integer[]{KeyEvent.VK_EQUALS});

    char symbols [] = {'!', '@', '#', '$', '%', '^', '&', '*', '(', ')'};
    char values  [] = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '0'};
    for (int a = 0; a < symbols.length; a ++)
      keyMap.put(symbols [a], new Integer[]{KeyEvent.VK_SHIFT, int (values [a])});

    return keyMap;
  }
  String getClipboardContent () {
    Clipboard c = Toolkit.getDefaultToolkit().getSystemClipboard();
    Transferable t = c.getContents(this);

    // Check if Clipboard content type is String
    boolean isContentString = t.isDataFlavorSupported(DataFlavor.stringFlavor);
    if (!isContentString) return null;

    try {
      return (String) t.getTransferData(DataFlavor.stringFlavor);
    } 
    catch (Exception e) {
      e.printStackTrace();
    }
    return null;
  }
  int [] pixelRGB (float x, float y) {
    int RGBs [] = new int [3];
    String col = robot.getPixelColor(int(x), int(y)).toString();
    col = col.replace("java.awt.Color[", "").replace("]", "").replace("r=", "").replace("g=", "").replace("b=", "");
    String sd [] = split(col, ",");
    RGBs = int(sd);
    return RGBs;
  }
  color pixelColor (float x, float y) {
    int RGBs [] = pixelRGB (x, y);
    color pxlColor = color(RGBs [0], RGBs [1], RGBs [2]);
    println(pxlColor);
    return pxlColor;
  }
}
