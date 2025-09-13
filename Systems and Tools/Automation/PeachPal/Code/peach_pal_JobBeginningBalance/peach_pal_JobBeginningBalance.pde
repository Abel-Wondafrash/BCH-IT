RobotTools robot;
static final String WIN_VBB = "Job Beginning Balances";
static final String WIN_FIND = "Find";

void setup () {
  surface.setVisible (false);
  robot = new RobotTools ();

  Field inv = new Field (52, 205, 131, 17);
  //delay (2000);

  String path = dataPath ("") + "/cb_job_beg_bal-aug12.csv";
  int delayAfterSetting = 400;

  Table table = loadTable (path, "header");
  //String codes [] = table.getStringColumn ("partner_code");
  String labels [] = table.getStringColumn ("label");
  String debit [] = table.getStringColumn ("debit");
  String credit [] = table.getStringColumn ("credit");

  String classes [] = {"ABD_EditDate1", "ABD_Dollars1", "ABD_Dollars1"};
  for (int i = 0; i < labels.length; i ++) { // names.length
    println (nf (i + 1, 3), "of", nf (labels.length, 3), nfc ((i + 1.0)/labels.length, 2), "%\t", labels [i], debit [i], credit [i]);
    String values [] = {debit [i], credit [i]};
    if (float (debit [i]) == 0) continue;

    //println ("Waiting for", WIN_VBB, "to exist");
    winWaitUntilExist (WIN_VBB);
    setForeground(WIN_VBB);
    winWaitUntilForeground(WIN_VBB);
    robot.press(new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_B});
    delay (100);
    pressFind ();
    delay (100);
    winWaitUntilForeground (WIN_FIND);
    robot.typeString (labels [i]);
    delay (100);
    robot.press(new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_O});
    winWaitUntilForeground (WIN_VBB);
    robot.press(new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_P});
    delay (100);

    for (int t = 0; t < 3; t ++) robot.TAB();
    setControlText (WIN_VBB, classes [0], values [0]);
    delay (delayAfterSetting);
    robot.ENTER ();
    
    //break;
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
