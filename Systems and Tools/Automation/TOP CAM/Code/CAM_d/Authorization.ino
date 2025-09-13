boolean assignAuthorities () {
  // Open the file for reading
  File file = SD.open(AUTH_PATH);

  if (!file) {
    Serial.println("Missing or Corrupted " + AUTH_PATH);
    return false;
  }

  while (file.available()) {
    String data = file.readStringUntil ('\n');
    data.trim ();
    
    if (data.length () < 10) continue;
    data = encryption.decrypt (data);
    authorities.append (data);
  }
  file.close();
  
  if (authorities.isEmpty ()) {
    Serial.println ("No Authorities Found in " + AUTH_PATH);
    return false;
  }

  return true;
}

void authorization (int state) {
  if (lastState.equals (OPENED) && contacts.isOn ()) {
    processClosing ();
    return;
  }

  if (state == STATE_READY) {
    rgb.allOff ();
    rgb.blueOn ();

    if (contacts.isOn () && !lastState.equals (OPENED)) bruteForced = true;
    if (!bruteForced) return;

    Serial.println ("<BF-" + FORCED_ONLINE + "-BF>");
    saveSD ("<BF-" + FORCED_ONLINE + "-BF>");
    putString (0, FORCED_ENTRY);
    putString (100, FORCED_ONLINE);
    bruteForceType = FORCED_ONLINE;
  }

  else if (state == STATE_DENIED) {
    rgb.allOff ();
    for (int a = 0; a < 3; a ++) rgb.blinkRed (500);
  }

  else if (state == STATE_GRANTED) {
    processOpening ();
    if (contacts.isOn ()) processClosing (); // Door is Opened
  }
}

void processOpening () {
  relay.on (); // Hold Lock (UNLOCK);
  Serial.println ("<UN-" + rfid.getID () + "-UN>");
  saveSD ("<UN-" + rfid.getID () + "-UN>");

  long startTime = millis ();
  int lit = 1;
  rgb.allOff ();
  while (millis () - startTime < WAIT_UNLOCKED) {
    rgb.green (lit);
    long remainingTime = millis () - startTime;
    int blinkTime = map (remainingTime, 0, WAIT_UNLOCKED, 500, 80);
    lit = (remainingTime / blinkTime) % 2;

    if (contacts.isOn ()) {
      Serial.println ("<OP-" + rfid.getID () + "-OP>");
      saveSD ("<OP-" + rfid.getID () + "-OP>");
      break; // Door is Open
    }
  }

  relay.off (); // Release Lock | Here because Timeout or Door being Open
  Serial.println ("<LK-" + rfid.getID () + "-LK>");
  saveSD ("<LK-" + rfid.getID () + "-LK>");
  if (contacts.isOn ()) putString (0, OPENED); // Door Already Open
}
void processClosing () {
  rgb.allOff ();
  while (contacts.isOn ()) { // Wait until door is Closed
    rgb.blinkGreen (1000);
  }
  putString (0, CLOSED);
  Serial.println ("<CL-" + rfid.getID () + "-CL>");
  saveSD ("<CL-" + rfid.getID () + "-CL>");
}

int getState () {
  if (authorities.isEmpty ()) return STATE_READY;

  rfid.scan ();
  String tagID = rfid.getID ();
  tagID.trim ();
  if (tagID == "") return STATE_READY;

  // Denied Access
  if (!authorities.contains (tagID)) return STATE_DENIED;

  // Granted Access
  return STATE_GRANTED;
}

boolean commandedToReset () {
  return fileExists (RST_PATH);
}
void unreset () {
  SD.remove (RST_PATH);
  delay (500);
}
