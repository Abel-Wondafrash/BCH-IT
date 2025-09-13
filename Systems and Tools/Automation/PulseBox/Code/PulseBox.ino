#include "RotaryEncoder.h"
RotaryEncoder rotary;

void setup() {
  rotary.init();
  rotary.setScale (1); // Target CPR / Actual CPR
}

void loop() {
  rotary.update();
}
