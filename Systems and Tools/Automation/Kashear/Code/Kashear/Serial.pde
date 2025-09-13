import processing.serial.*;
Serial serial;

import javax.swing.JOptionPane;

void serialEvent (Serial s) {
  String code = serial.readString ();
  if (code == null || code.isEmpty ()) return;
  code = code.replace (str (bufferUntilChar), "");

  try {
    if (!isModeDirect) {
      code = JOptionPane.showInputDialog("Enter SO Number:");
      if (code == null) return;
      code = code.trim ();
    }
    String response = verifyOrderValidity (code);
    if (response == null) println ("Data Entered '" + SOV_PREFIX + code + "'");
    else {
      JOptionPane.showMessageDialog(null, response, "Error", JOptionPane.ERROR_MESSAGE);
      System.err.println (response);
    }
    println ();
  }
  catch (Exception e) {
    println ("Error during entry:", e);
  }
}
