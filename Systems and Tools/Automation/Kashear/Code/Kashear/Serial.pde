import processing.serial.*;
Serial serial;

import javax.swing.JOptionPane;

void serialEvent (Serial s) {
  String code = serial.readString ();
  if (code == null || code.isEmpty ()) return;
  code = code.replace (str (serialBufferUntilChar), "");

  try {
    if (!IS_MODE_DIRECT) {
      code = JOptionPane.showInputDialog("Enter SO Number:");
      if (code == null) return;
      code = code.trim ();
    }
    String response = verifyOrderValidity (code);
    if (response == null) {
      println ("Data Entered '" + SALES_ORDER_PREFIX + code + "'");
      cLogger.log ("Data Entered '" + SALES_ORDER_PREFIX + code + "'");
    }
    else {
      cLogger.log ("Error during data entry: " + response);
      JOptionPane.showMessageDialog(null, response, "Error", JOptionPane.ERROR_MESSAGE);
      System.err.println (response);
    }
    println ();
  }
  catch (Exception e) {
    println ("Error during entry:", e);
    cLogger.log ("Error during entry: " + e);
  }
}
