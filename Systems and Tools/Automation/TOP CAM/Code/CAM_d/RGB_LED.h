class RGB_LED {
  public:
    int RGB [3];

    RGB_LED () {
    }
    RGB_LED (int r, int g, int b) {
      RGB [0] = r;
      RGB [1] = g;
      RGB [2] = b;

      for (int p = 0; p < 3; p ++)
        pinMode (RGB [p], OUTPUT);
    }

    void red (bool state) {
      digitalWrite (RGB [0], state);
    }
    void redOn () {
      red (HIGH);
    }
    void redOff () {
      red (LOW);
    }
    bool redState () {
      return digitalRead (RGB [0]);
    }

    void green (bool state) {
      digitalWrite (RGB [1], state);
    }
    void greenOn () {
      green (HIGH);
    }
    void greenOff () {
      green (LOW);
    }
    bool greenState () {
      return digitalRead (RGB [1]);
    }

    void blue (bool state) {
      digitalWrite (RGB [2], state);
    }
    void blueOn () {
      blue (HIGH);
    }
    void blueOff () {
      blue (LOW);
    }
    bool blueState () {
      return digitalRead (RGB [2]);
    }

    void allOn () {
      redOn ();
      greenOn ();
      blueOn ();
    }
    void allOff () {
      redOff ();
      greenOff ();
      blueOff ();
    }

    void blinkRed (int mill) {
      redOn (), delay (mill);
      redOff (), delay (mill);
    }
    void blinkGreen (int mill) {
      greenOn (), delay (mill);
      greenOff (), delay (mill);
    }
    void blinkBlue (int mill) {
      blueOn (), delay (mill);
      blueOff (), delay (mill);
    }

    void blinkAll (int mill) {
      redOn ();
      greenOn ();
      blueOn ();
      delay (mill);
      redOff ();
      greenOff ();
      blueOff ();
      delay (mill);
    }
};
