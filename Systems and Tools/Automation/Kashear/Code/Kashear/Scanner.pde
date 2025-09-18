void initScanner (String qrScannerPort, int qrScannerBaudRate) {
  try {
    serial = new Serial (this, qrScannerPort, qrScannerBaudRate);
    serial.bufferUntil (serialBufferUntilChar);
  } 
  catch (Exception e) {
    System.err.println ();
    JOptionPane.showMessageDialog(null, 
      e + "\n" + Error.QR_SCANNER_NOT_FOUND + "\n\nMake sure port is: " + qrScannerPort + " and that baud rate is: " + qrScannerBaudRate, 
      "Error", JOptionPane.ERROR_MESSAGE);
    exit ();
    return;
  }
}
