class Digital {
  public:
    int pin;
    int mode;
    
    boolean reverseState;

    Digital () {
    }
    Digital (int pin, int mode) {
      this -> pin = pin;
      this -> mode = mode;
      pinMode (pin, mode);

      if (mode == INPUT_PULLUP)
        reverseState = true;
    }
    Digital (int pin, int mode, boolean reverseState) {
      this -> pin = pin;
      this -> mode = mode;
      this -> reverseState = reverseState;
      
      pinMode (pin, mode);
    }

    void on () {
      digitalWrite (pin, HIGH);
    }
    void off () {
      digitalWrite (pin, LOW);
    }
    void setState (bool state) {
      digitalWrite (pin, state);
    }
    void flipState() {
      setState (!isOn ());
    }

    int val () {
      int value = digitalRead (pin);
      
      return (reverseState == true? 1 - value : value);
    }

    bool isOn () {
      return val ();
    }
    bool isOff () {
      return !isOn ();
    }
    bool getState() {
      return val ();
    }
    bool isTriggered () {
      return val ();
    }
    bool isPressed () {
      return val ();
    }
};
