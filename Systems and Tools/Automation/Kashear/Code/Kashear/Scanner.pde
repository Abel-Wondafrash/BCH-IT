void initScanner () {
  try {
    serial = new Serial (this, PORT, BAUD_RATE);
    serial.bufferUntil (bufferUntilChar);
  } 
  catch (Exception e) {
    System.err.println ("QR Reader Not Connected");
    exit ();
    return;
  }
}
