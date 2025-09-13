class DataEntry {
  RobotTools robot;

  String LOAD_FROM_FILE = "Load From File";
  String FILE_NAME = "File &name:";
  String EDIT_IMAGE = "Edit Image";
  String OPEN_TEMPLATE = "Open Template";

  DataEntry () {
    robot = new RobotTools ();
  }

  void initialize () {
    // Go to End
    robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_END});
    delay (1000);
  }

  void enter (File front, File back) {
    boolean entered = enter (back);
    println ("Entered:", entered);
    if (entered) enter (front);
  }
  boolean enter (File file) {
    robot.toClipboard (file.getAbsolutePath ());
    robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_SHIFT, KeyEvent.VK_L});

    // Ensure win exists before pasting
    winWaitUntilExist (LOAD_FROM_FILE);
    fieldWaitUntilExist (LOAD_FROM_FILE, FILE_NAME);

    // Focus on "File name:" textField
    robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_SHIFT, KeyEvent.VK_L});
    // Paste  
    robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_V});
    //robot.typeString (file.getName ());

    robot.press (KeyEvent.VK_ENTER);
    winWaitIfExist (LOAD_FROM_FILE);

    // Edit Image
    winWaitUntilExist (EDIT_IMAGE);
    winWaitUntilContains (EDIT_IMAGE, new String [] {"Rotate", "OK"});

    for (int a = 0; a < 3; a ++) robot.press (KeyEvent.VK_TAB);

    robot.press (KeyEvent.VK_ENTER);
    winWaitIfExist (EDIT_IMAGE);

    // Save to update
    robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_S});
    // Open Templates window to check whether saving has finished
    robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_O});

    // Wait until Open Template is lauched
    winWaitUntilExist (OPEN_TEMPLATE);
    // Close "Open Template"
    robot.press (new Integer [] {KeyEvent.VK_ESCAPE});
    // Wait until "Open Template" closes
    winWaitIfExist (OPEN_TEMPLATE);

    robot.press (new Integer [] {KeyEvent.VK_SHIFT, KeyEvent.VK_TAB});

    return true;
  }
}
