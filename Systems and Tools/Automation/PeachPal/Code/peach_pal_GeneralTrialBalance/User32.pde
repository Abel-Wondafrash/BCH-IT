import com.sun.jna.Native;
import com.sun.jna.platform.win32.User32;
import java.util.List;
import com.sun.jna.platform.win32.WinUser;
import com.sun.jna.Memory;
import com.sun.jna.Pointer;

String getFocusedWindowTitle() {
  char[] buffer = new char[1024];

  WinDef.HWND hwnd = User32.INSTANCE.GetForegroundWindow();
  User32.INSTANCE.GetWindowText(hwnd, buffer, buffer.length);

  return Native.toString(buffer);
}

Field getWinLoc (String windowTitle) {
  WinDef.HWND hwnd = User32.INSTANCE.FindWindow(null, windowTitle);
  if (hwnd != null) {
    WinDef.RECT rect = new WinDef.RECT();
    if (User32.INSTANCE.GetWindowRect(hwnd, rect)) {
      return new Field (rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
    }
  }
  return null; // Window not found or rect could not be retrieved
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

        // Get handle
        String handleStr = String.format("0x%08X", Pointer.nativeValue(hwndChild.getPointer()));

        // Get window rectangle (coordinates and dimensions)
        WinDef.RECT rect = new WinDef.RECT();
        User32.INSTANCE.GetWindowRect(hwndChild, rect);

        if ((text != null && !text.trim().isEmpty()) || (className != null && !className.trim().isEmpty())) {
          fields.add(new FieldInfo(
            text.trim(), 
            className.trim(), 
            handleStr.trim (), 
            hwndChild, 
            rect.left, // x coordinate
            rect.top, // y coordinate
            rect.right - rect.left, // width
            rect.bottom - rect.top    // height
            ));
        }

        return true; // continue enumeration
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
void winWaitUntilExist (String title) {
  while (!winExists (title)) {
    delay (500);
  }
}
void winWaitIfExist (String title) {
  while (winExists (title)) {
    delay (500);
  }
}
void winWaitUntilForeground (String title) {
  String fTitle = null;
  while (fTitle == null || fTitle.isEmpty()) {
    fTitle = getFocusedWindowTitle ();
    if (fTitle != null && fTitle.equals (title)) break;
    delay (500);
  }
}
void fieldWaitUntilExist (String title, String fieldText) {
  while (!hasFieldText (title, fieldText)) {
    delay (500);
  }
}
void winWaitUntilContains (String title, String text, int index) {
  while (!winContainsText (title, text, index)) {
    delay (500);
  }
}
void winWaitUntilContains (String title, String texts []) {
  while (!winContainsText (title, texts)) {
    delay (500);
  }
}

boolean isWinForeground(String winTitle) {
  String fTitle = getFocusedWindowTitle();
  return fTitle != null && fTitle.equals(winTitle);
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

  public FieldInfo(String text, String className, String handle, WinDef.HWND hwnd, int x, int y, int width, int height) {
    this.text = text;
    this.className = className;
    this.hwnd = hwnd;
    this.handle = handle;

    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  int getX () {
    return x;
  }
  int getY () {
    return y;
  }
  int getW () {
    return width;
  }
  int getH () {
    return height;
  }

  public String getText() {
    return text;
  }
  public String getClassName() {
    return className;
  }
  public WinDef.HWND getHwnd() {
    return hwnd;
  }
  public String getHandle () {
    return handle;
  }

  @Override
    public String toString() {
    return "FieldInfo{" +
      "text='" + text + '\'' +
      ", className='" + className + '\'' +
      ", hwnd=" + hwnd +
      ", x=" + x +
      ", y=" + y +
      ", width=" + width +
      ", height=" + height +
      '}';
  }
}
