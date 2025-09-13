#include "Constants.h"

#include <SPI.h>
#include <SD.h>

#include "RFID.h"
RFID rfid (10, 9); // SS_PIN = 10, RST_PIN = 9

#include "RGB_LED.h"
RGB_LED rgb (7, 6, 5);

#include "Digital.h"
Digital relay (8, OUTPUT);
Digital contacts (4, INPUT_PULLUP);

#include "StringArray.h"
StringArray authorities;

#include "Encryption.h"
Encryption encryption (XOR_KY);

String lastState, bruteForceType = "";
boolean bruteForced;

void setup() {
  rgb.allOn ();

  Serial.begin (9600);
  Serial.println ("Started");

  saveStateUpdates ();

  rfid.init ();
  rgb.allOff ();
  if (!initSD ()) while (true) rgb.blinkRed (100); // Alert incase of missing or corrupted SD Card
  if (!assignAuthorities ()) while (true) rgb.blinkRed (500); // Alert incase of missing Authorities
  if (commandedToReset ()) {
    for (int a = 0; a < 3; a ++) rgb.blinkAll (1000);
    Serial.println ("COMMANDED TO RESET");
    unreset ();
    putString (0, OPENED);
  }
  Serial.println ("Authorities");
  for (int i = 0; i < authorities.getSize (); i ++) {
    Serial.println (authorities.get (i));
  }

  saveSD ("SYSTEM ON");
}

void loop() {
  if (bruteForced) {
    Serial.println ("<BF-" + bruteForceType + "-BF>");
    rgb.allOff ();
    rgb.blinkRed (800);
    return;
  }

  int state = getState ();
  if (state == STATE_DENIED) {
    rgb.allOff ();
    rgb.redOn ();
    Serial.println ("<DA-" + rfid.getID () + "-DA>");
    saveSD ("<DA-" + rfid.getID () + "-DA>");
  }
  else if (state == STATE_GRANTED) {
    rgb.allOff ();
    rgb.greenOn ();
    Serial.println ("<GA-" + rfid.getID () + "-GA>");
    saveSD ("<GA-" + rfid.getID () + "-GA>");
  }

  authorization (state);
}

void serialEvent () {
  if (!Serial.available ()) return;

  String data = Serial.readStringUntil ('\n');
  data.trim (), data.replace ("\n", ""), data.replace ("\r", "");

  Serial.println (data);
}
