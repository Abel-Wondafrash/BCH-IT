import com.sun.jna.Native;
import com.sun.jna.platform.win32.User32;
import com.sun.jna.platform.win32.WinUser;
import com.sun.jna.Memory;
import com.sun.jna.Pointer;
import com.sun.jna.platform.win32.WinDef;
import com.sun.jna.WString;

String getFocusedWindowTitle() {
  char[] buffer = new char[1024];

  WinDef.HWND hwnd = User32.INSTANCE.GetForegroundWindow();
  User32.INSTANCE.GetWindowText(hwnd, buffer, buffer.length);

  return Native.toString(buffer);
}

List<String> getWindowTextContent(String windowTitle) {
  WinDef.HWND hwnd = User32.INSTANCE.FindWindow(null, windowTitle);
  final List<String> contentList = new ArrayList<String>();

  if (hwnd != null) {
    User32.INSTANCE.EnumChildWindows(hwnd, new User32.WNDENUMPROC() {
      @Override
        public boolean callback(WinDef.HWND hwndChild, Pointer data) {
        char[] buffer = new char[4096];
        User32.INSTANCE.GetWindowText(hwndChild, buffer, buffer.length);
        String text = Native.toString(buffer).trim();
        if (!text.isEmpty()) {
          contentList.add(text);
        }
        return true;
      }
    }
    , null);
  }

  return contentList;
}

List<FieldInfo> getWindowFieldsDetailed(String windowTitle) {
  WinDef.HWND hwnd = User32.INSTANCE.FindWindow(null, windowTitle);
  final List<FieldInfo> fields = new ArrayList<FieldInfo>();
  final Map<String, Integer> classCounter = new HashMap<String, Integer>();

  if (hwnd != null) {
    User32.INSTANCE.EnumChildWindows(hwnd, new User32.WNDENUMPROC() {
      @Override
        public boolean callback(WinDef.HWND hwndChild, Pointer data) {
        char[] textBuffer = new char[1024];
        char[] classBuffer = new char[1024];

        // Get window text
        User32.INSTANCE.GetWindowText(hwndChild, textBuffer, textBuffer.length);
        String text = Native.toString(textBuffer);

        // Get class name
        User32.INSTANCE.GetClassName(hwndChild, classBuffer, classBuffer.length);
        String className = Native.toString(classBuffer);

        // Count occurrence of this class name to compute ClassNN
        int count = classCounter.getOrDefault(className, 0) + 1;
        classCounter.put(className, count);
        String classNN = className + count;  // e.g., Edit1, Button2

        // Get handle as string
        String handleStr = String.format("0x%08X", Pointer.nativeValue(hwndChild.getPointer()));

        // Get window rectangle
        WinDef.RECT rect = new WinDef.RECT();
        User32.INSTANCE.GetWindowRect(hwndChild, rect);

        if (text != null && className != null && !className.trim().isEmpty()) {
          fields.add(new FieldInfo(
            text.trim(), 
            className.trim(), 
            handleStr.trim(), 
            hwndChild, 
            rect.left, 
            rect.top, 
            rect.right - rect.left, 
            rect.bottom - rect.top, 
            classNN // NEW FIELD
            ));
        }

        return true;
      }
    }
    , null);
  }

  return fields;
}


boolean winExists(String title) {
  WinDef.HWND hwnd = User32.INSTANCE.FindWindow(null, title);
  return hwnd != null;
}
boolean hasFieldText (String windowTitle, String [] fieldTexts) {
  for (String fieldText : fieldTexts) {
    if (!hasFieldText (windowTitle, fieldText)) return false;
  }
  return fieldTexts.length != 0;
}
boolean hasFieldText (String windowTitle, String fieldText) {
  WinDef.HWND hwnd = User32.INSTANCE.FindWindow(null, windowTitle);
  WinDef.HWND labelHwnd = User32.INSTANCE.FindWindowEx(hwnd, null, null, fieldText);

  return labelHwnd != null;
}
boolean winContainsText (String windowTitle, String text) {
  return getWindowTextContent (windowTitle).contains (text);
}
boolean winContainsText (String windowTitle, String text []) {
  List <String> contents = getWindowTextContent (windowTitle);

  for (String each : text) if (!contents.contains (each)) return false;

  return true;
}
boolean winContainsText (String windowTitle, String text, int index) {
  List <String> contents = getWindowTextContent (windowTitle);
  if (index < 0 || contents.size () < index) return false;
  return contents.get (index).equals (text);
}

void setForeground (String windowTitle) {
  WinDef.HWND hwnd = User32.INSTANCE.FindWindow (null, windowTitle);
  User32.INSTANCE.SetForegroundWindow (hwnd);
}
void closeWindowByTitle(String windowTitle) {
  WinDef.HWND hwnd = User32.INSTANCE.FindWindow(null, windowTitle);
  if (hwnd != null) {
    User32.INSTANCE.PostMessage(hwnd, WinMessages.WM_CLOSE, new WinDef.WPARAM(0), new WinDef.LPARAM(0));
  }
}

boolean winWaitUntilExist (String title, long timeout) {
  long startTime = millis ();
  while (!winExists (title)) {
    delay (500);
    if (millis () - startTime > timeout) return false;
  }
  return true;
}
boolean winWaitIfExist (String title, long timeout) {
  long startTime = millis ();
  while (winExists (title)) {
    delay (500);
    if (millis () - startTime > timeout) return false;
  }
  return true;
}
boolean isWinForeground(String title) {
  String fTitle = getFocusedWindowTitle();
  return fTitle != null && fTitle.equals(title);
}
boolean winWaitUntilForeground(String title, long timeout) {
  long startTime = millis();
  while (!isWinForeground(title)) {
    if (millis() - startTime > timeout) return false;
    delay(500);
  }
  return true;
}

boolean fieldWaitUntilExist (String title, String fieldText, long timeout) {
  long startTime = millis ();
  while (!hasFieldText (title, fieldText)) {
    delay (500);
    if (millis () - startTime > timeout) return false;
  }
  return true;
}
boolean winWaitUntilContains (String title, String text, int index, long timeout) {
  long startTime = millis ();
  while (!winContainsText (title, text, index)) {
    delay (500);
    if (millis () - startTime > timeout) return false;
  }
  return true;
}
boolean winWaitUntilContains (String title, String text, long timeout) {
  long startTime = millis ();
  while (!getWindowTextContent (title).contains(text)) {
    delay (500);
    if (millis () - startTime > timeout) return false;
  }
  return true;
}
boolean winWaitUntilContains (String title, String texts [], long timeout) {
  long startTime = millis ();
  while (!winContainsText (title, texts)) {
    delay (500);
    if (millis () - startTime > timeout) return false;
  }
  return true;
}

public class FieldInfo {
  private String text;
  private String className;
  private String handle;
  private WinDef.HWND hwnd;
  private int x;
  private int y;
  private int width;
  private int height;
  private String classNN; // <-- NEW FIELD

  public FieldInfo(String text, String className, String handle, WinDef.HWND hwnd, 
    int x, int y, int width, int height, String classNN) {
    this.text = text;
    this.className = className;
    this.handle = handle;
    this.hwnd = hwnd;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.classNN = classNN;
  }

  boolean isEditable () {
    return classNN != null && classNN.toUpperCase ().contains (".EDIT.");
  }
  boolean isSelectable () {
    return classNN != null && classNN.toLowerCase ().contains (".app.") && !isEditable ();
  }

  // Getters
  public int getX() {
    return x;
  }
  public int getY() {
    return y;
  }
  public int getW() {
    return width;
  }
  public int getH() {
    return height;
  }
  public String getText() {
    return text;
  }
  public String getClassName() {
    return className;
  }
  public String getClassNN() {
    return classNN;
  }
  public WinDef.HWND getHwnd() {
    return hwnd;
  }
  public String getHandle() {
    return handle;
  }

  @Override
    public String toString() {
    return "FieldInfo{" +
      "text='" + text + '\'' +
      ", className='" + className + '\'' +
      ", classNN='" + classNN + '\'' + // <-- Include in toString()
      ", handle='" + handle + '\'' +
      ", hwnd=" + hwnd +
      ", x=" + x +
      ", y=" + y +
      ", width=" + width +
      ", height=" + height +
      '}';
  }
}
