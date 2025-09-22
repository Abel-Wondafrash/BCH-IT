Fonts fonts;
Shapes shapes;
Generator generator;
RasterImagePrint printer;
Paths_ paths_;
FileWatcher fWatcher;
SlipEngine engine;

void setup () {
  size (300, 140);
  surface.setTitle ("Loj Parcel - Initiating .");
  background (#036DFF);

  // Paths
  paths_ = new Paths_ ();
  String dnaConfigPath = paths_.dnaConfigPath; // Load local config first
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
}
