import com.sun.jna.Native;
import com.sun.jna.platform.win32.User32;
import com.sun.jna.platform.win32.WinDef;

String getFocusedWindowTitle() {
  char[] buffer = new char[1024];

  WinDef.HWND hwnd = User32.INSTANCE.GetForegroundWindow();
  User32.INSTANCE.GetWindowText(hwnd, buffer, buffer.length);

  return Native.toString(buffer);
}
String getWindowTextContent(String windowTitle) {
  WinDef.HWND hwnd = User32.INSTANCE.FindWindow(null, windowTitle);
  final StringBuilder contentBuilder = new StringBuilder();

  if (hwnd != null) {
    User32.INSTANCE.EnumChildWindows(hwnd, new User32.WNDENUMPROC() {
      @Override
        public boolean callback (WinDef.HWND hwndChild, Pointer data) {
        char[] buffer = new char[4096];
        User32.INSTANCE.GetWindowText(hwndChild, buffer, buffer.length);
        contentBuilder.append(Native.toString(buffer)).append("\n");
        return true;
      }
    }
    , null);
  }

  return contentBuilder.toString();
}

boolean winExists(String title) {
  WinDef.HWND hwnd = User32.INSTANCE.FindWindow(null, title);
  return hwnd != null;
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
  String content = getWindowTextContent (windowTitle);
  
  for (String each : text) if (!content.contains (each)) return false;
  
  return true;
}

void setForeground (String windowTitle) {
  WinDef.HWND hwnd = User32.INSTANCE.FindWindow (null, windowTitle);
  User32.INSTANCE.SetForegroundWindow (hwnd);
  println (getFocusedWindowTitle());
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
void fieldWaitUntilExist (String title, String fieldText) {
  while (!hasFieldText (title, fieldText)) {
    delay (500);
  }
}
void winWaitUntilContains (String title, String texts []) {
  while (!winContainsText (title, texts)) {
    delay (500);
  }
}
