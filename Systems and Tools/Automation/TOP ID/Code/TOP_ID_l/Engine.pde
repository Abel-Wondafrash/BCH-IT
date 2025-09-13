void engine () {
  surface.setVisible (false);

  String mainDir = System.getProperty ("user.home") + "/desktop/";

  tablePath = mainDir + tableName;
  String title = new File (tablePath).getName ().replace (".csv", "");
  photosPath = mainDir + "Photos - " + title + "/";
  outputPath = mainDir + "IDs - " + title + "/";
  allIDpath = outputPath + "_All/";
  
  println (photosPath, " Exists: ", new File (photosPath).exists ());

  entry = new DataEntry ();

  Table table = loadTable (tablePath, "header");
  int lastTime = millis ();
  if (mode.equals (Modes.GENERATE)) generateIDs (table, photosPath, outputPath);
  else if (mode.equals (Modes.ENTRY)) enterIDs (table, allIDpath);
  println ((millis () - lastTime)/1000.0, "s");
}

void enterIDs (Table table, String allIDpath) {
  println ("Starting entry in 5s ...");
  delay (5000);

  entry.initialize ();

  String names [] = table.getStringColumn ("Name");
  String positions [] = table.getStringColumn ("Position");
  String IDs [] = table.getStringColumn ("ID");

  for (int a = names.length - 1; a >= 0; a --) {
    String name = names [a];
    String position = positions [a];
    String ID = IDs [a].trim ();
    
    println (name, position, ID);

    // Clean up elements
    name = removeMultiSpace (name).trim ();
    name = toTitleCase (name);

    position = removeMultiSpace (position).trim ();
    //position = toTitleCase (position);

    //String IDletters = getLetters (ID);
    //if (IDletters.equals ("C") || IDletters.equals ("T")) ;
    //else ID = getDigits (ID);
    ID = getAlphaNumerics (ID);
    println ("ID", ID);

    if (name == null || position == null || ID == null) {
      System.err.println ("Invalid element: " + "Name: " + name + " Position: " + position + " ID: " + ID);
      continue;
    }

    name = toNameStr (name);
    String frontPath = allIDpath + "1 - Front - " + ID + " - " + name + ".tif";
    String backPath = allIDpath + "2 - Back - " + ID + " - " + name + ".tif";

    File front = new File (frontPath);
    File back = new File (backPath);
    if (!front.exists() || !back.exists ()) {
      System.err.println ("Missing ID: " + "Front (" + front.exists () + ") | " + "Back (" + back.exists () + ")");
      println ("\tFront: " + name);
      println ("\tBack: " + name);
      continue;
    }

    entry.enter (front, back);

    println (a + 1, "of", names.length, name + " - Entered");
  }

  println ("All Done");
}

void generateIDs (Table table, String photosPath, String outputPath) {
  qrGen = new ZXING4P ();

  String dataPath = dataPath ("") + "/";
  fonts = new Fonts (dataPath);

  card = new Card ();
  person = new Person ();

  PImage frontTemplate = loadImage (dataPath + "template/TOP ID Front V2.jpg");
  PImage backTemplate = loadImage (dataPath + "template/TOP ID Back V2.jpg");
  PImage frontTemplateContract = loadImage (dataPath + "template/TOP ID Front V2 Contract.jpg");
  PImage backTemplateContract = loadImage (dataPath + "template/TOP ID Back V2 Contract.jpg");
  PImage frontTemplateTemporary = loadImage (dataPath + "template/TOP ID Front V2 Temporary.jpg");
  PImage backTemplateTemporary = loadImage (dataPath + "template/TOP ID Back V2 Temporary.jpg");

  //surface.setSize (int (card.width*2 + 10), int (card.height));
  //surface.setLocation ((displayWidth - width)/2, (displayHeight - height)/2); 

  String names [] = table.getStringColumn ("Name");
  String positions [] = table.getStringColumn ("Position");
  String IDs [] = table.getStringColumn ("ID");
  StringDict photosInDir = new StringDict ();
  for (File file : new File (photosPath).listFiles ()) {
    if (!file.isFile()) continue;
    String name = file.getName ();
    for (String fileFormat : supportedImageFormats)
    if (name.toLowerCase ().endsWith("." + fileFormat))
      photosInDir.set (name.substring (0, name.lastIndexOf(".")), file.getAbsolutePath());
  }
  
  for (int a = 0; a < names.length; a ++) {
    String name = names [a];
    String position = positions [a];
    String ID = IDs [a];

    // Clean up elements
    name = removeMultiSpace (name).trim ();
    name = toTitleCase (name);

    position = removeMultiSpace (position).trim ();
    //position = toTitleCase (position);

    ID = getAlphaNumerics (ID);
    ID = getIDnumber (ID);
    boolean isContract = false;
    boolean isPermanent = false;
    
    //if (ID != null && ID.startsWith ("C")) {
    //  card.setTemplate (frontTemplateContract, backTemplateContract);
    //  isContract = true;
    //}
    //else if (ID != null && ID.startsWith ("T")) {
    //  card.setTemplate (frontTemplateTemporary, backTemplateTemporary);
    //}
     {
      card.setTemplate (frontTemplate, backTemplate);
      isPermanent = true;
      ID = getDigits (ID);
    }

    if (name == null || position == null || ID == null) {
      System.err.println ("Invalid element: " + "Name: " + name + " Position: " + position + " ID: " + ID);
      continue;
    }

    if (!photosInDir.hasKey(ID)) {
      System.err.println ("Missing Photo: " + ID);
      continue;
    }
    
    String photoPath = photosInDir.get (ID);
    PImage photo = loadImage (photoPath);

    person.setName (name);
    person.setPosition (position);
    person.setIDnumber (ID);
    person.setPhoto (photo);

    card.clear ();
    card.setPerson (person);
    card.generate ();
    PImage front = card.getFront ();
    PImage back = card.getBack ();

    name = toNameStr (name);
    // outputPath + (a + 1) + " - " +  ID + " - " + name + "/" // Categorized (for manual entry) 
    String exportDirs [] = {outputPath + "_All/"}; // All (automated)
    for (String dir : exportDirs) {
      String frontName = dir + "1 - Front - " + ID + " - " + name + ".tif";
      String backName = dir + "2 - Back - " + ID + " - " + name + ".tif";

      front.save (frontName);
      back.save  (backName);
    }

    println (name + " - Done");
  }

  println ("All Done");
}

void tablePath (File selectedFile) {
  if (selectedFile == null || !selectedFile.exists ()) return;

  if (!selectedFile.isFile () || !selectedFile.getName ().toLowerCase ().endsWith (".csv")) return;

  tablePath = selectedFile.getAbsolutePath ();
  println ("Table Path:", tablePath);
}

Fonts fonts;
Card card;
Person person;
DataEntry entry;

String tablePath;
String photosPath, outputPath;
String allIDpath;
String supportedImageFormats [] = {"png", "jpg", "jpeg"};
