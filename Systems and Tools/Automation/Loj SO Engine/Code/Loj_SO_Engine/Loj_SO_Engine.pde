Fonts fonts;
Shapes shapes;
Generator generator;
Configurations configs;
Issuers issuers;
VoucherProcessor vProcessor;
PDF_Toolkit pdf_toolkit;
Logger oLogger, cLogger; // o: Order | c: Console
Printer printer;
ZXING4P qrGen;
SingleInstance appLock;

boolean rotatePage = false;

void setup () {
  size (400, 140);
  
  surface.setVisible (false);

  generator = new Generator ();
  pdf_toolkit = new PDF_Toolkit (PDRectangle.A5, 150);

  // Paths
  String dataPath = dataPath ("");
  String resPath = new File (dataPath).getParent () + "/res/";

  // Configurations & Issues
  configs = new Configurations(resPath + PATH_PREFERENCES);
  issuers = new Issuers(resPath + PATH_ISSUERS);

  // Assets
  fonts = new Fonts (resPath);
  shapes = new Shapes (resPath);

  // Critical Files Missing Handler
  appLock = new SingleInstance("program.lock");
  if (!configs.init () || !issuers.init () || !fonts.init () || !shapes.init () || !appLock.init ()) {
    appLock.release();
    exit ();
    return;
  }
  
  qrGen = new ZXING4P();

  generator.setLogo (shapes.logoFull);
  generator.setStamp (shapes.stamp);

  // Listener
  String xmlListenPath = configs.getPreferences().getXmlListenPath();
  String xmlArchivePath = configs.getPreferences ().getXmlArchivePath ();
  String loggerRootPath = configs.getPreferences ().getLoggerRootPath ();
  String cLoggerRootPath = configs.getPreferences ().getCloggerRootPath ();
  String selectedPrinterName = configs.getPreferences ().getSelectedPrinterName ();

  vProcessor = new VoucherProcessor (xmlListenPath, xmlArchivePath, VOUCHER_QUEUER_CHECKIN_PERIOD);
  printer = new Printer (selectedPrinterName);
  oLogger = new Logger (loggerRootPath);
  cLogger = new Logger (cLoggerRootPath).setLogFileName ("C_");

  // Init Checksum
  try {
    checksum = new FileChecksum ();
  } 
  catch (NoSuchAlgorithmException e) {
    cLogger.log ("Algorithm not found: " + e.getMessage());
    System.err.println("Algorithm not found: " + e.getMessage());
  }
  
  // Show printer details
  printer.showVerbose ();

  println ("Running");
  cLogger.log ("Running");
}

void draw () {
  background (0);
}

void keyPressed () {
  if (keyCode == ESC) key = 0;
}
