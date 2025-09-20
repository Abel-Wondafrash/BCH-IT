// Robot and Clipboard
import java.awt.Robot;
import java.awt.Toolkit;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import java.awt.datatransfer.*;

import java.util.HashMap;
import java.util.Map;

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
    robot.keyPress(KeyEvent.VK_TAB);
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
  void DOWN () {
    robot.keyPress(KeyEvent.VK_DOWN);
    robot.keyRelease(KeyEvent.VK_DOWN);
    delay(40);
  }
  void toClipboard (String s) {
    StringSelection stringSelection = new StringSelection(s);
    Clipboard clpbrd = Toolkit.getDefaultToolkit().getSystemClipboard();
    clpbrd.setContents(stringSelection, null);
  }
  void mouseMove(Field field) {
    mouseMove(field.getX (), field.getY (), field.getW (), field.getH ());
  }
  
  void mouseMove(int x, int y) {
    robot.mouseMove(x, y);
    delay(40);
  }
  void mouseMove (int x, int y, int w, int h) {
    mouseMove (x + w/2, y + h/2);
  }
  void moveMouseAndClick (Field field) {
    mouseMoveAndClick(field.getX (), field.getY (), field.getW (), field.getH ());
  }
  void mouseMoveAndClick(int x, int y) {
    robot.mouseMove(x, y);
    delay(40);
    robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
    robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
    delay(40);
  }
  void mouseMoveAndClick (int x, int y, int w, int h) {
    mouseMoveAndClick (x + w/2, y + h/2);
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
    keyMap.put('/', new Integer[]{KeyEvent.VK_SLASH});

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
