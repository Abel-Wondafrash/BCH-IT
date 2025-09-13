RobotTools robot;
static final String WIN_VBB = "Inventory Beginning Balances";
static final String WIN_FIND = "Find";

void setup () {
  surface.setVisible (false);
  robot = new RobotTools ();

  Field inv = new Field (52, 205, 131, 17);
  //delay (2000);

  String path = dataPath ("") + "/cb_inv_beg_bal-aug12.csv";
  int delayAfterSetting = 200;

  Table table = loadTable (path, "header");
  //String codes [] = table.getStringColumn ("partner_code");
  String labels [] = table.getStringColumn ("label");
  String quantities [] = table.getStringColumn ("quantity");
  String costs [] = table.getStringColumn ("unit_cost");

  String classes [] = {"ABD_Qty1", "ABD_UnitPrice1"};
  for (int i = 0; i < labels.length; i ++) { // names.length
    println (nf (i + 1, 3), "of", nf (labels.length, 3), nfc ((i + 1.0)/labels.length, 2), "%\t", labels [i], quantities [i], costs [i]);
    String values [] = {quantities [i], costs [i]};
    if (quantities [i].trim ().isEmpty() || float (quantities [i]) == 0) continue;

    //println ("Waiting for", WIN_VBB, "to exist");
    winWaitUntilExist (WIN_VBB);
    setForeground(WIN_VBB);
    winWaitUntilForeground(WIN_VBB);
    robot.press(new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_B});
    delay (100);
    robot.mouseMoveAndClick(126, 126);
    delay (100);
    winWaitUntilForeground (WIN_FIND);
    robot.typeString (labels [i]);
    delay (100);
    robot.press(new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_O});
    winWaitUntilForeground (WIN_VBB);
    robot.press(new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_P});
    delay (100);
    
    robot.TAB ();
    robot.TAB ();
    robot.typeString (values [0]);
    robot.TAB ();
    robot.typeString (values [1]);
    robot.TAB ();
    robot.ENTER ();
    delay (delayAfterSetting);
    //robot.TAB ();
    //robot.ENTER ();

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
