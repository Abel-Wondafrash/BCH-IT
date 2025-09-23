Fonts fonts;
Shapes shapes;
Generator generator;
RasterImagePrint printer;
Paths_ paths_;
FileWatcher fWatcher;
SlipEngine engine;
Logger cLogger;
OneInstance appLock;

void setup () {
  size (300, 140);
  surface.setTitle ("Loj Parcel - Initiating .");
  background (#036DFF);

  appLock = new OneInstance ();
  if (!appLock.acquire("program.lock")) {
    appLock.showAlreadyRunningMessage();
    appLock.release ();
    exit();
    return;
  }

  // Paths
  paths_ = new Paths_ ();
  cLogger = new Logger (paths_.logDir).setLogFileName ("C_");

  String dnaConfigPath = paths_.getDNAconfigPath (); // Load local config first
  DNAconfig localConfig = new DNAconfig (dnaConfigPath); // Get DNA (main) config path
  if (!localConfig.init ()) {
    exit ();
    return;
  }

  surface.setTitle ("Loj Parcel - Initiating ..");
  // Main Configurations
  String configPath = localConfig.getConfigPath(); // Load main config
  MainConfigurations config = new MainConfigurations(configPath);
  if (!config.init ()) {
    exit ();
    return;
  }

  surface.setTitle ("Loj Parcel - Initiating ...");
  // File Watcher
  fWatcher = new FileWatcher (config.getXmlTargetPath());
  if (!fWatcher.init()) {
    exit ();
    return;
  }
  fWatcher.start ();

  surface.setTitle ("Loj Parcel - Initiating ....");
  // Fonts & Shapes
  fonts = new Fonts (config.getResPath());
  shapes = new Shapes (config.getResPath());
  if (!fonts.init () || !shapes.init ()) {
    exit ();
    return;
  }

  // Generator
  generator = new Generator ().setLogo (shapes.logoFull);
  printer = new RasterImagePrint ().setPrinterName(config.getSlipPrinterName());
  engine = new SlipEngine (fWatcher.getPathQueue());
  engine.start ();

  surface.setVisible (false);
  println ("Ready");
  cLogger.log ("Ready");
}
