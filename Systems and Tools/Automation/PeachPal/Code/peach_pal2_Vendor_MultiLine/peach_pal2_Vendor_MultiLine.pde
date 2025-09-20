RobotTools robot;
String path = "C:/Users/Administrator/Documents/Peach-Sep20/";
//static final String WIN_VBB = "Vendor Beginning Balances";
static final String WIN_VBB = "Vendor Beginning Balances";
static final String WIN_FIND = "Find";

void setup () {
  surface.setVisible (false);
  robot = new RobotTools ();

  Field inv = new Field (20, 132, 130, 16);

  path += "ven_multiple_lines.csv";
  int delayAfterSetting = 400;

  Table table = loadTable (path, "header");
  //String codes [] = table.getStringColumn ("partner_code");
  String names [] = table.getStringColumn ("name");
  String dates [] = table.getStringColumn ("date");
  String inv_no [] = table.getStringColumn ("inv_no");
  String balas [] = table.getStringColumn ("balance");
  delay (2000);

  String classes [] = {"ABD_Edit1", "ABD_EditDate1", "ABD_Dollars1", "BBD_EditAcnt1"};
  String prevName = null;
  for (int i = 100; i < names.length; i ++) { // names.length
    println (nf (i + 1, 3), "of", nf (names.length, 3), nfc ((i + 1.0)*100/names.length, 3), "%\t", names [i], balas [i]);
    String values [] = {inv_no [i], dates [i], balas [i], "120101"};
    if (float (balas [i]) == 0) continue;

    if (prevName == null || !prevName.equals (names [i])) {
      //println ("Waiting for", WIN_VBB, "to exist");
      winWaitUntilExist (WIN_VBB);
      setForeground(WIN_VBB);
      winWaitUntilForeground(WIN_VBB);
      robot.press(new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_B});
      delay (200);
      pressFind ();
      delay (200);
      winWaitUntilForeground (WIN_FIND);
      robot.typeString (names [i]);
      delay (200);
      robot.press(new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_O});
      winWaitUntilForeground (WIN_VBB);
      //robot.press(new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_V});
      robot.press(new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_P});
      delay (200);
      robot.moveMouseAndClick (inv);
      delay (200);
    }
    
    prevName = names [i];

    while (true) {
      robot.toClipboard("_");
      delay (200);

      robot.press(new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_C});
      delay (200);
      String content = robot.getClipboardContent();
      if (content == null) {
        print ("NULL CONTENT");
        continue;
      }

      if (content.trim ().equals ("_") || content.trim ().isEmpty()) break;
      robot.DOWN();
      delay (200);
    }

    delay (300);
    setControlText (WIN_VBB, classes [0], values [0]);
    delay (delayAfterSetting);
    robot.ENTER ();

    setControlText (WIN_VBB, classes [1], values [1]);  
    delay (delayAfterSetting);
    robot.ENTER ();
    robot.ENTER ();

    setControlText (WIN_VBB, classes [2], values [2]);
    delay (delayAfterSetting);
    robot.ENTER ();

    setControlText (WIN_VBB, classes [3], values [3]);
    delay (delayAfterSetting);
    robot.ENTER ();
  }

  exit ();
}

void type (String data []) {
  robot.toClipboard(data [0]);
  robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_V});

  robot.TAB ();
  delay (100);

  robot.typeString ("7");
  robot.press(KeyEvent.VK_SLASH);
  robot.typeString ("8");
  robot.press(KeyEvent.VK_SLASH);
  robot.typeString ("2025");

  robot.TAB ();
  delay (100);

  robot.TAB ();
  robot.toClipboard(data [3]);
  robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_V});
  delay (100);

  robot.TAB ();
  delay (100);

  robot.toClipboard(data [4]);
  delay (400);
  robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_V});
  delay (100);  

  robot.ENTER ();
  delay (100);
}
