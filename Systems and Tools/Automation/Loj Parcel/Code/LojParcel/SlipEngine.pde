class SlipEngine implements Runnable {
  private final BlockingQueue<Path> slips;
  private ParcelParser parcel;

  SlipEngine(BlockingQueue<Path> slips) {
    this.slips = slips;
    parcel = new ParcelParser ();
  }

  public void start() {
    Thread t = new Thread(this, "SlipEngineThread");
    t.setDaemon(true); // Not to block JVM shutdown
    t.start();
  }

  @Override
    public void run() {
    try {
      while (!Thread.currentThread().isInterrupted()) {
        processSlip();
      }
    } 
    catch (Exception e) {
      System.err.println("Error in SlipEngine: " + e);
      cLogger.log ("Error in SlipEngine: " + e);
    }
  }

  private void processSlip() throws Exception {
    Path path = slips.take(); // blocks until a path is available
    if (!path.toFile().exists()) {
      System.err.println ("Queued file missing: " + path.toString ());
      cLogger.log ("Queued file missing: " + path.toString ());
      return;
    }
    
    if (!parcel.parse(path.toString ())) {
      System.err.println ("Error occurred during parcel parsing");
      cLogger.log ("Error occurred during parcel parsing");
      return;
    }

    String randStr = RandomStringUtils.randomAlphanumeric(SLIP_RANDOM_CODE_LENGTH);
    String genPath = paths_.getTempDir () + getDateToday("yyyy/MMM/MMM_dd_yyyy/") + parcel.getBatchReference() + "-" + randStr + ".png";
    generator.generate(parcel, genPath);

    File slipImg = new File (genPath);
    if (!slipImg.exists ()) {
      System.err.println ("Generator failed to create slip image");
      cLogger.log ("Generator failed to create slip image");
      return;
    }
    if (!printer.print(slipImg)) {
      System.err.println ("Error Printing " + parcel.getBatchReference());
      cLogger.log ("Error Printing " + parcel.getBatchReference());
    }
    
    println (parcel.getBatchReference() + " Sent to Printer | " + printer.printerName);
    cLogger.log (parcel.getBatchReference() + " Sent to Printer | " + printer.printerName);
    
    // Clean temp image
    slipImg.delete ();
  }
}
