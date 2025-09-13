// NO [F]: PRESENT > HIGH -- ABSENT > LOW 
// NC [T]: PRESENT > LOW  -- ABSENT > HIGH

class Node {
  private int pin = -1;
  private Integer val;
  private Long lastEntryTime;
  private Long cycleTime, processingTime, feedTime;
  private Long metrics [];

  private String codename;

  private boolean outputState = false;
  private boolean valChanged = false;

  Node (int pin, String codename) {
    this.pin = pin;
    this.codename = codename;
  }

  Node setState (boolean outputState) {
    this.outputState = outputState;
    return this;
  }
  Node setNormallyOpen () {
    outputState = false;
    return this;
  }
  Node setNormallyClosed () {
    outputState = true;
    return this;
  }

  String getCodename () {
    return codename;
  }

  boolean isValid () {
    return pin != -1 && !codename.isEmpty ();
  }
  boolean isNormallyOpen () {
    return outputState == false;
  }
  boolean isNormallyClosed () {
    return outputState == true;
  }
  boolean isValChanged () {
    return valChanged;
  }

  void setValue (Integer val, Long nowTimestamp) {
    valChanged = false;
    if (val == null || this.val != null && this.val == val) return; // No change in value
    //boolean blocked = isNormallyOpen ()? val == 0 : val == 1;
    valChanged = true;
    this.val = val;
  }

  int getPin () {
    return pin;
  }
  int getVal () {
    return val;
  }
  Long [] getMetrics () {
    return metrics;
  }
  void clearMetrics () {
    metrics = null;
  }
}
