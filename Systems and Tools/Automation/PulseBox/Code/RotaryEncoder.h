#ifndef ROTARYENCODER_H
#define ROTARYENCODER_H

#include <Arduino.h>

class RotaryEncoder {
  private:
    static const int pinA = 2; // Input encoder A
    static const int pinB = 3; // Input encoder B

    static const int outA = 5; // Output to PLC A
    static const int outB = 8; // Output to PLC B

    volatile byte aFlag = 0;
    volatile byte bFlag = 0;
    volatile uint16_t reading = 0;

    volatile long encoderPos = 0;
    long oldEncPos = 0;

    // Scaling
    float scale = 1.0;
    float fractionalSteps = 0.0;
    long lastEncoderCount = 0;
    int SIGNAL_DURATION = 100;

    // Pointer for ISR
    static RotaryEncoder* instance;

    // ISR handlers
    static void methodA() {
      if (instance) {
        cli();
        instance->reading = PIND & 0xC;
        if (instance->reading == B00001100 && instance->aFlag) {
          instance->encoderPos--;
          instance->bFlag = 0;
          instance->aFlag = 0;
        } else if (instance->reading == B00000100) {
          instance->bFlag = 1;
        }
        sei();
        instance->oldEncPos = instance->encoderPos;
      }
    }

    static void methodB() {
      if (instance) {
        cli();
        instance->reading = PIND & 0xC;
        if (instance->reading == B00001100 && instance->bFlag) {
          instance->encoderPos++;
          instance->bFlag = 0;
          instance->aFlag = 0;
        } else if (instance->reading == B00001000) {
          instance->aFlag = 1;
        }
        sei();
        instance->oldEncPos = instance->encoderPos;
      }
    }

  public:
    void init() {
      pinMode(pinA, INPUT_PULLUP);
      pinMode(pinB, INPUT_PULLUP);

      pinMode(outA, OUTPUT);
      pinMode(outB, OUTPUT);
      digitalWrite(outA, LOW);
      digitalWrite(outB, LOW);

      instance = this;
      attachInterrupt(digitalPinToInterrupt(pinA), methodA, RISING);
      attachInterrupt(digitalPinToInterrupt(pinB), methodB, RISING);
    }

    void setScale(float s) {
      if (s > 0.0) scale = s;
    }

    void resetCount() {
      encoderPos = 0;
      oldEncPos = 0;
      lastEncoderCount = 0;
      fractionalSteps = 0.0;
    }

    void update() {
      long currentCount = encoderPos;
      long delta = currentCount - lastEncoderCount;

      float scaledSteps = delta * scale + fractionalSteps;
      int stepsToEmit = (int)scaledSteps;
      fractionalSteps = scaledSteps - stepsToEmit;

      if (stepsToEmit != 0) {
        generateQuadrature(stepsToEmit);
        lastEncoderCount = currentCount;
      }
    }

    void generateQuadrature(int steps) {
      static const byte quadStates[4][2] = {
        {LOW, LOW},
        {HIGH, LOW},
        {HIGH, HIGH},
        {LOW, HIGH}
      };
      static int state = 0;

      int direction = (steps > 0) ? 1 : -1;

      for (int i = 0; i < abs(steps); i++) {
        state = (state + direction + 4) % 4;
        digitalWrite(outA, quadStates[state][0]);
        digitalWrite(outB, quadStates[state][1]);
        delayMicroseconds(SIGNAL_DURATION); // Adjust for signal timing
      }
    }
};

// Static member initialization
RotaryEncoder* RotaryEncoder::instance = nullptr;

#endif
