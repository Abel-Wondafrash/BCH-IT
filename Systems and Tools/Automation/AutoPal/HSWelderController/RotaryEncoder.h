#ifndef ROTARYENCODER_H
#define ROTARYENCODER_H

class RotaryEncoder {
  private:
    static int pinA; // Our first hardware interrupt pin (digital pin 2)
    static int pinB; // Our second hardware interrupt pin (digital pin 3)

    volatile byte aFlag = 0; // Flag for expecting a rising edge on pinA
    volatile byte bFlag = 0; // Flag for expecting a rising edge on pinB
    volatile uint16_t reading = 0; // Stores raw interrupt pin readings

    long encoderPos = 0; // Current encoder position
    long oldEncPos = 0; // Last encoder position

    const float diameter = 16.0; // cm
    const float countsPerRev = 1600.0; // 400 PPR * 4 (quadrature)


    // Static pointer to the instance for use in ISRs
    static RotaryEncoder* instance;

    // Static ISR methods
    static void methodA() {
      if (instance) {
        cli(); // Disable interrupts
        instance->reading = PIND & 0xC; // Read pinA and pinB
        if (instance->reading == B00001100 && instance->aFlag) {
          instance->encoderPos--; // Decrement position
          instance->bFlag = 0;
          instance->aFlag = 0;
        } else if (instance->reading == B00000100) {
          instance->bFlag = 1; // Expect pinB transition
        }
        sei(); // Enable interrupts
        instance->oldEncPos = instance->encoderPos;
      }
    }

    static void methodB() {
      if (instance) {
        cli(); // Disable interrupts
        instance->reading = PIND & 0xC; // Read pinA and pinB
        if (instance->reading == B00001100 && instance->bFlag) {
          instance->encoderPos++; // Increment position
          instance->bFlag = 0;
          instance->aFlag = 0;
        } else if (instance->reading == B00001000) {
          instance->aFlag = 1; // Expect pinA transition
        }
        sei(); // Enable interrupts
        instance->oldEncPos = instance->encoderPos;
      }
    }

  public:
    void init() {
      pinMode(pinA, INPUT_PULLUP); // Set pinA as input with pull-up
      pinMode(pinB, INPUT_PULLUP); // Set pinB as input with pull-up

      // Set the instance pointer
      instance = this;

      // Attach interrupts to static methods
      attachInterrupt(digitalPinToInterrupt(pinA), methodA, RISING);
      attachInterrupt(digitalPinToInterrupt(pinB), methodB, RISING);
    }
    void resetCount () {
      encoderPos = 0;
    }
    long getCount() {
      return encoderPos;
    }
    double getLength() {
      const float circumference = PI * diameter; // cm per revolution
      return getCount() * (circumference / countsPerRev); // Distance in cm
    }
};

// Static member definitions
int RotaryEncoder::pinA = 2;
int RotaryEncoder::pinB = 3;
RotaryEncoder* RotaryEncoder::instance = nullptr;

#endif
