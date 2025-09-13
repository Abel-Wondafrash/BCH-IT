import java.util.List;
import java.util.Arrays;
import java.util.LinkedHashMap;

class IDs {
  static final String IMAGE_EXTENSION = ".tif";
  static final String FRONT_PREFIX = "1 - Front - ";
  static final String BACK_PREFIX = "2 - Back - ";

  String dirPath;

  int ID_WIDTH = int (161), ID_HEIGHT = int (257);
  static final int maxCOLs = 5, maxROWs = 2;
  int COLs, ROWs;
  int IDsPerSheet;

  List <PImage> fronts, backs;
  List <LinkedHashMap <PImage, PImage>> sheets;

  IDs (String dirPath) {
    this.dirPath = dirPath;

    ID_WIDTH *= SCALE;
    ID_HEIGHT *= SCALE;
    
    COLs = PAGE_WIDTH / ID_WIDTH;
    ROWs = PAGE_HEIGHT / ID_HEIGHT;
    IDsPerSheet = COLs * ROWs;
    println ("IDs Per Sheet:", IDsPerSheet, COLs, ROWs);

    LinkedHashMap <PImage, PImage> sides = getSidesImage (dirPath);
    if (sides == null || sides.isEmpty()) return;

    // Resize Images
    for (int i = 0; i < sides.size (); i ++) sides.keySet ().toArray (new PImage [0]) [i].resize (ID_WIDTH, ID_HEIGHT);
    for (int i = 0; i < sides.size (); i ++) sides.values ().toArray (new PImage [0]) [i].resize (ID_WIDTH, ID_HEIGHT);

    fronts = new ArrayList <PImage> ();
    backs = new ArrayList <PImage> ();
    fronts.addAll (Arrays.asList (sides.keySet ().toArray (new PImage [0])));
    backs.addAll (Arrays.asList (sides.values ().toArray (new PImage [0])));

    // Sheets
    sheets = new ArrayList <LinkedHashMap <PImage, PImage>> ();
    for (int s = 0; s < getSheetsCount (); s ++) {
      LinkedHashMap <PImage, PImage> sheet = new LinkedHashMap <PImage, PImage> ();
      for (int i = 0; i < IDsPerSheet; i ++) {
        int index = s*IDsPerSheet + i;
        
        if (index + 1 > size ()) break;
        
        sheet.put (fronts.get (index), backs.get (index));
      }
      sheets.add (sheet);
    }
  }

  PImage getFront (int index) {
    if (index + 1 > fronts.size ()) return null;

    return fronts.get (index);
  }
  PImage getBack (int index) {
    if (index + 1 > backs.size ()) return null;

    return backs.get (index);
  }

  boolean isEmpty () {
    return fronts == null || fronts.isEmpty() || backs == null || backs.isEmpty ();
  }

  int size () {
    if (fronts == null || fronts.isEmpty() || backs == null || backs.isEmpty ()) return -1;
    return fronts.size ();
  }
  int getSheetsCount () {
    return max (size ()/IDsPerSheet, 1);
  }
  
  LinkedHashMap <PImage, PImage> getSheet (int index) {
    return sheets.get (index);
  }

  LinkedHashMap <PImage, PImage> getSidesImage (String dirPath) {
    List <StringDict> sidesPaths = getSidesPaths (dirPath);
    if (sidesPaths == null || sidesPaths.isEmpty ()) return null;

    LinkedHashMap <PImage, PImage> sides = new LinkedHashMap <PImage, PImage> ();

    StringDict frontPaths = sidesPaths.get (0);
    StringDict backPaths = sidesPaths.get (1);

    for (int i = 0; i < frontPaths.size (); i ++)
      sides.put (loadImage (frontPaths.valueArray () [i]), loadImage (backPaths.valueArray () [i]));

    return sides;
  }

  List <StringDict> getSidesPaths (String dirPath) {
    File dir = new File (dirPath);

    StringDict fronts = new StringDict ();
    StringDict backs = new StringDict ();

    String fileName, filePath;
    for (File file : dir.listFiles ()) {
      fileName = file.getName ();
      if (!file.isFile () || !fileName.endsWith (IMAGE_EXTENSION)) continue;

      fileName = fileName.replace (IMAGE_EXTENSION, "");
      filePath = file.getAbsolutePath();

      if (fileName.startsWith (FRONT_PREFIX)) fronts.set (fileName.replace (FRONT_PREFIX, ""), filePath);
      else if (fileName.startsWith (BACK_PREFIX)) backs.set (fileName.replace (BACK_PREFIX, ""), filePath);
    }

    fronts.sortKeys ();
    backs.sortKeys ();

    if (fronts.size () == 0 || backs.size () == 0 || fronts.size () != backs.size ()) return null;

    return Arrays.asList (fronts, backs);
  }
}
