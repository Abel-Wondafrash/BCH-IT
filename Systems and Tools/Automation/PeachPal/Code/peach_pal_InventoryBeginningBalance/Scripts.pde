void pressFind () {
  String ahkPath = "C:\\Users\\Administrator\\AppData\\Local\\Programs\\AutoHotkey\\v2\\AutoHotkey64.exe";
  String scriptPath = dataPath("scripts/click_find.ahk");
  String button = "BITMAPBUTTON3"; // winContainsText (WIN_VBB, "LOOKUP")? "BITMAPBUTTON4" : "BITMAPBUTTON3";
  String script = "ControlClick(\"" + button + "\", \"" + WIN_VBB + "\", \"\", \"Left\", 1, \"NA\")";

  File scriptDir = new File(dataPath("scripts"));
  if (!scriptDir.exists()) scriptDir.mkdirs();
  saveStrings(scriptPath, new String[]{ script });

  try {
    Process p = Runtime.getRuntime().exec(new String[]{ahkPath, scriptPath});
  } 
  catch (IOException e) {
    e.printStackTrace();
  }
}

void setControlText(String winTitle, String classNN, String value) {
  String ahkPath = "C:\\Users\\Administrator\\AppData\\Local\\Programs\\AutoHotkey\\v2\\AutoHotkey64.exe";
  String scriptPath = dataPath("scripts/set_control_text" + ".ahk");

  // Build the AHK v2 script
  String script = String.format(
    "WinActivate(\"%s\")\nControlSetText(\"%s\", \"%s\", \"%s\")",
    winTitle, value, classNN, winTitle
  );

  File scriptDir = new File(dataPath("scripts"));
  if (!scriptDir.exists()) scriptDir.mkdirs();
  saveStrings(scriptPath, new String[]{ script });

  try {
    Process p = Runtime.getRuntime().exec(new String[]{ahkPath, scriptPath});
  } catch (IOException e) {
    e.printStackTrace();
  }
}
