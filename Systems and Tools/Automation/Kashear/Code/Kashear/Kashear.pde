// With Config

RobotTools robot;
Fields fields;
Querier qDetails, qGetFS, qSetFS, qGetPO;
Paths_ paths_;
OdooClient oc;
Fonts fonts;
Shapes shapes;
Generator aGen;
Printer printer;
PDF_Toolkit pdf_toolkit;
Timeouts timeouts;

void setup () {
  println ("Initiating ...");
  size (140, 140);
  surface.setVisible (true);

  if (displayWidth != SET_DISPLAY_WIDTH && displayHeight != SET_DISPLAY_HEIGHT) {
    showCMDerror ("Unsupported screen size");
    return;
  }

  paths_ = new Paths_ ();
  String dnaConfigPath = paths_.dnaConfigPath; // Load local config first
  KashearDNAconfig localConfig = new KashearDNAconfig (dnaConfigPath); // Get main config path
  if (!localConfig.init ()) {
    exit ();
    return;
  }

  String configPath = localConfig.getKashearConfigPath(); // Load main config
  MainConfigurations config = new MainConfigurations(configPath);
  if (!config.init ()) {
    exit ();
    return;
  }

  timeouts = new Timeouts ();
  updateConstantsWithConfig (config);

  initScanner (config.getQrScannerPort(), config.getQrScannerBaudRate());
  robot = new RobotTools ();
  qDetails = new Querier (config.getQueryGetQuotationDetailsPath());
  qGetFS = new Querier (config.getQueryGetClientOrderRefByCode());
  qSetFS = new Querier (config.getQuerySetClientOrderRefByCode());
  qGetPO = new Querier (config.getQueryGetPartnerActiveOrdersByCode());
  printer = new Printer (config.getAttachmentPrinterName());
  printer.showVerbose();

  // Paths
  fonts = new Fonts (config.getResPath());
  shapes = new Shapes (config.getResPath());

  if (!fonts.init () || !shapes.init ()) {
    exit ();
    return;
  }

  // Init Checksum
  try {
    checksum = new FileChecksum ();
  } 
  catch (Exception e) {
    System.err.println("Algorithm not found: " + e.getMessage());
    exit ();
    return;
  }

  aGen = new Generator ().setWatermark (shapes.attachment);
  pdf_toolkit = new PDF_Toolkit (PDRectangle.A4, 150);
  oc = new OdooClient(DB_NAME);

  if (!oc.isAuthenticated()) {
    JOptionPane.showMessageDialog(null, Error.authErrorMessage, "Login Error", JOptionPane.ERROR_MESSAGE);
    exit ();
    return;
  }

  delay (2000);
  surface.setVisible (false);

  println ("Started");
  println ("DB: " + DB_NAME + " | " + "USER: " + KASHEAR_ODOO_EMAIL);
}

void draw () {
}
