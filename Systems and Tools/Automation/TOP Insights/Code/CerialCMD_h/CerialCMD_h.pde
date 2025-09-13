Cerial cerial;
Nodes nodes;
Database dbLogs;
NirCMD nircmd;
Sound sound;

String nodesStates = "";

void setup () {
  size (240, 600);

  cerial = new Cerial (this, "COM3");
  nodes = new Nodes (pins, codenames);
  nircmd = new NirCMD ();
  sound = new Sound ();
  //sound.mute ();

  final String appParentDir = System.getProperty ("user.home") + "/Documents/_Amber Flashes/";
  final String dbLogsDir = appParentDir + "Logs/";
  final String dbBackupsDir = appParentDir + "Backups/";

  // Database
  loadJDBCdriver ();
  setLogTableDefinition ();
  setStatesTableDefinition ();
  setLogActivityTableDefinition ();
  dbLogs = new Database (dbLogsDir).setBackupDir (dbBackupsDir).setNameSuffix (SITE_NAME);
  dbLogs.setTableDefinition (LOGS_TABLE_DEFINITION); // Headers to create a missing table with
  
  nodes.setDB (dbLogs);
  
  dbLogs.start ();
  nodes.start ();
  cerial.start ();
}

void draw () {
  background (cerial.isOverdue () == null? #0000FF : cerial.isOverdue()? #FF0000 : #000000);
  
  textSize (25);
  textAlign (CENTER, TOP);
  fill (255);
  text (nodesStates, width*0.5, 50);
}

Boolean exit = null;
void keyPressed () {
  if (keyCode == ESC) key = 0;
  if (exit == null && key == 'x') exit = false;
}
void keyReleased () {
  if (key == 'x') exit = null;
  if (key == 'i' && exit != null && exit == false) exit = true;
}
