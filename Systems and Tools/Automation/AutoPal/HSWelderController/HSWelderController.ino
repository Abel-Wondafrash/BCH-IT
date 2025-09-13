#include "RotaryEncoder.h"
RotaryEncoder rotary;

#include "Digital.h"
Digital button (A0, INPUT_PULLUP);
Digital state (10, OUTPUT);
Digital fRelay (A3, OUTPUT), rRelay (A4, OUTPUT), cRelay (A5, OUTPUT);
Digital fProx (5, INPUT_PULLUP, false), rProx (6, INPUT_PULLUP, false);

boolean isRunning, direction = true; // direction = true => Forward
const int DIRN_CHANGE_DELAY = 500, CUT_PULSE_DELAY = 500;
float cutLength = 20.0; // in cm

void setup() {
  Serial.begin(9600);
  rotary.init ();
}

void loop() {
  if (button.isPressed ()) {
    state.setState (!isRunning);
    if (isRunning) rRelay.off (), fRelay.off (), cRelay.off ();
    else fRelay.on ();

    while (button.isPressed ());
    delay (250);
    isRunning = !isRunning;
    rotary.resetCount ();
  }

  if (!isRunning) return;
  if (fProx.isTriggered () && rProx.isTriggered ()) { // 24V source out or faulty sensors
    fRelay.off (), rRelay.off (), cRelay.off ();
    return;
  }

  if (fProx.isTriggered () && fRelay.isOn ()) // Forward Off | Reverse On
    fRelay.off (), delay (DIRN_CHANGE_DELAY), rRelay.on ();
  else if (rProx.isTriggered () && rRelay.isOn ()) // Forward On | Reverse Off
    rRelay.off (), delay (DIRN_CHANGE_DELAY), fRelay.on ();

  if (rotary.getLength () >= cutLength) {
    cRelay.on (), delay (CUT_PULSE_DELAY), cRelay.off ();
    rotary.resetCount ();
  }

  Serial.println (rotary.getLength ());
}
