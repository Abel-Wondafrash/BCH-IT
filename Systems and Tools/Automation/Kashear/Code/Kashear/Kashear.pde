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

boolean isModeDirect = true;

void setup () {
  println ("Initiating ...");
  size (140, 140);
  surface.setVisible (true);
  
  if (displayWidth != SET_DISPLAY_WIDTH && displayHeight != SET_DISPLAY_HEIGHT) {
    println ("Unsupported screen size");
    return;
  }

  //initScanner ();
  paths_ = new Paths_ ();
  robot = new RobotTools ();
  qDetails = new Querier (paths_.query_quotationDetailsPath);
  qGetFS = new Querier (paths_.query_get_client_order_ref_by_code);
  qSetFS = new Querier (paths_.query_set_client_order_ref_by_code);
  qGetPO = new Querier (paths_.query_get_partner_active_orders_by_code);
  printer = new Printer ("HP LaserJet Pro 4003 - Finance");
  printer.showVerbose();
  
  // Paths
  fonts = new Fonts (paths_.resPath);
  shapes = new Shapes (paths_.resPath);

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
    JOptionPane.showMessageDialog(null, authErrorMessage, "Login Error", JOptionPane.ERROR_MESSAGE);
    exit ();
    return;
  }
  
  //delay (2000);
  //surface.setVisible (false);
  
  println ("Started");
  println ("DB: " + DB_NAME + " | " + "USER: " + ODOO_USER);
}

void draw () {
}

void keyReleased () {
  if (keyCode == ENTER) JOptionPane.showMessageDialog (null, verifyOrderValidity ("03448"));
}
