import processing.serial.*;

class Cerial implements Runnable {
  private static final String DELIMITER_DEVICE_UNAVAILABLE = "is not currently available.";
  private static final String DELIMITER_DEVICE_DOES_NOT_EXIST = "Illegal device name";

  private static final String COMMAND_GET_DEVICE_STATE = "cmd.exe /c mode";
  private static final String COMMAND_GET_DEVICES = "wmic path Win32_SerialPort get deviceID /format:csv";

  private static final int baudRate = 57600;
  private static final int pollPeriod = 5000;
  private static final int activityPollPeriod = 10000;

  private String setDeviceID;

  private char SERIAL_DELIMITER = '\n';

  private Boolean isOverdue; // Device has been disconnected or heard from for far too long
  private boolean isPluggedIn;
  private boolean isConnected;
  private boolean wasOverdue;

  private StringList availableDeviceIDs;

  private Periodically periodicalPolling, periodicalActivePolling;

  private Serial serial;
  private PApplet parent;

  Cerial (PApplet parent, String setDeviceID) {
    this.parent = parent;
    this.setDeviceID = setDeviceID;

    availableDeviceIDs = new StringList ();
    periodicalPolling = new Periodically (pollPeriod);
    periodicalActivePolling = new Periodically (activityPollPeriod);
  }

  void start () {
    if (periodicalPolling.isFirstTime ()) attemptToConnect ();
    new Thread (this).start ();
  }

  StringList update () {
    availableDeviceIDs = new StringList ();

    String response [] = getCMDresponse (COMMAND_GET_DEVICES);
    if (response == null || response.length < 2) return null;

    String rawHeader = response [0];
    String [] headers = split (rawHeader, ",");

    for (int i = 1; i < response.length; i ++) { // Set i = 1 to jump to 0 | i.e header
      String details [] = split (response [i], ",");
      availableDeviceIDs.appendUnique (new SerialPort (headers, details).getDeviceID ());
    }

    return availableDeviceIDs;
  }
  boolean isPluggedIn (boolean latest) {
    if (!latest) return isPluggedIn;

    if (setDeviceID == null || setDeviceID.isEmpty()) return false;
    if (availableDeviceIDs == null || availableDeviceIDs.size () == 0) return false;

    isPluggedIn = availableDeviceIDs.hasValue (setDeviceID);
    return isPluggedIn;
  }
  boolean isPluggedIn () {
    return isPluggedIn (false);
  }
  boolean isDetected () {
    if (setDeviceID == null || setDeviceID.isEmpty()) return false;

    String command = COMMAND_GET_DEVICE_STATE + " " + setDeviceID;
    String response [] = getCMDresponse (command);

    if (response == null || response.length == 0) return false;
    if (response [0].startsWith (DELIMITER_DEVICE_DOES_NOT_EXIST)) return false;

    return true;
  }
  boolean isAvailable () {
    if (setDeviceID == null || setDeviceID.isEmpty()) return false;

    String command = COMMAND_GET_DEVICE_STATE + " " + setDeviceID;
    String response [] = getCMDresponse (command);

    if (response == null || response.length == 0) return false;

    if (response [0].endsWith (DELIMITER_DEVICE_UNAVAILABLE)) return false;

    return true;
  }
  boolean isConnected (boolean latest) {
    if (!latest) return isConnected;

    isConnected = isPluggedIn (true) && isDetected () && !isAvailable ();
    return isConnected;
  }
  boolean isConnected () {
    return isConnected (false);
  }
  Boolean isOverdue () {
    return isOverdue;
  }
  boolean wasOverdue () {
    if (!wasOverdue) return false;
    
    wasOverdue = false;
    return true;
  }

  void run () {
    while (true) {
      attemptToConnect ();
      delay (pollPeriod);
    }
  }

  void attemptToConnect () {
    update ();
    
    isOverdue = periodicalActivePolling.isPastTime ();
    if (isOverdue) wasOverdue = true;

    if (availableDeviceIDs == null || availableDeviceIDs.size () == 0) {
      if ((!isPluggedIn (true) || !isConnected (true)) && periodicalActivePolling.isPastTime ()) {
        isOverdue = true;
        wasOverdue = true;
      }
      if (serial != null) serial.dispose ();
      periodicalPolling.reset ();
      return;
    }

    if (isPluggedIn (true) && !isConnected (true)) {
      if (serial != null) serial.dispose ();
      connect ();
    }

    periodicalPolling.reset ();
  }

  boolean connect () {
    try {
      serial = new Serial (parent, setDeviceID, baudRate);
      serial.bufferUntil (SERIAL_DELIMITER);
      println ("Connected to", setDeviceID);
      return true;
    }
    catch (Exception e) {
      System.err.println ("Error Connecting to " + setDeviceID + "\n> " + e);
      return false;
    }
  }

  String read () {
    return serial.readStringUntil (SERIAL_DELIMITER);
  }
}

void serialEvent (Serial s) {
  String data = cerial.read ();

  if (data == null) return;

  try {
    data = data.trim ();
    if (data.isEmpty()) return;

    handleSerialReads (data);
    nodesStates = "";
    for (Node node : nodes.nodes) {
      if (node == null || node.val == null) continue;

      nodesStates += node.pin + " | " + node.val + " \n";
    }
  }
  catch (Exception e) {
    println ("Error Handling Scans:", e);
  }
}

public void handleSerialReads (String data) {
  if (data == null) return;

  data = data.replaceAll ("[\n\r]", "");

  try {
    Long timestamp = getNowEpoch ();
    nodes.update (data, timestamp);
  } 
  catch (Exception e) {
    println ("Error Serial Event:", e);
  }
}
