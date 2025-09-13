int PAGE_WIDTH = 842, PAGE_HEIGHT = 595;
static final int SCALE = 4;

IDs ids;

void setup () {
  PAGE_WIDTH *= SCALE;
  PAGE_HEIGHT *= SCALE;

  selectFolder ("Select a dir contining IDs", "folderGrabber", new File (System.getProperty ("user.home") + "/desktop/"));
}

void folderGrabber (File file) {
  if (!file.isDirectory()) return;

  String dirPath = file.getAbsolutePath ();
  String outputPath = file.getParent() + "/Output/";

  println ("Getting IDs ...");
  ids = new IDs (dirPath);

  println ("IDs:", ids.size ());
  println ("Sheets:", ids.getSheetsCount());

  println ("Generating PDF");
  for (int i = 0; i < ids.getSheetsCount(); i ++) {
    println ("> Sheet ", i + 1, "of", ids.getSheetsCount ());
    saveSheet (ids.getSheet (i), outputPath + "IDs - Sheet " + (i + 1) + ".pdf");
  }
  println ("Done");

  exit ();
}

void saveSheet (LinkedHashMap <PImage, PImage> sheet, String path) {
  List <PImage> fronts = new ArrayList <PImage> (Arrays.asList (sheet.keySet ().toArray(new PImage [0])));
  List <PImage> backs = new ArrayList <PImage> (Arrays.asList (sheet.values ().toArray(new PImage [0])));

  PImage front = getPage (fronts, true);
  PImage back  = getPage (backs, false);

  createPDF (front, back, path);
}

PGraphics page;
PImage getPage (List <PImage> content, boolean isFront) {
  page = createGraphics (PAGE_WIDTH, PAGE_HEIGHT);

  page.beginDraw ();
  page.background (255);
  page.imageMode (CORNER);

  int gapX = 3, gapY = 3;
  println ("CR:", ids.COLs, ids.ROWs);
  int startX = (PAGE_WIDTH - ids.COLs*ids.ID_WIDTH - (ids.COLs - 1)*gapX)/2;
  int startY = (PAGE_HEIGHT - ids.ROWs*ids.ID_HEIGHT - (ids.ROWs - 1)*gapY)/2;
  println ("PG:", PAGE_WIDTH, PAGE_HEIGHT);
  println ("ID:", ids.ID_WIDTH, ids.ID_HEIGHT);
  println (startX, startY);

main:
  for (int r = 0; r < ids.ROWs; r ++) {
    for (int c = 0; c < ids.COLs; c ++) {
      if (content.isEmpty()) continue main;

      int x = startX + (ids.getSheetsCount() > 1 || isFront? c : (ids.COLs - 1 - c))*(ids.ID_WIDTH  + gapX);
      int y = startY + r*(ids.ID_HEIGHT + gapY);

      page.image (content.get (0), x, y);

      content.remove (0);
    }
  }

  page.endDraw ();

  return page.get ();
}
