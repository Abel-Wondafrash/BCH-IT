class State implements Cloneable {
  private final static String _UNKNOWN = "UNK";
  private final static String _NORMAL = "NRM";
  private final static String _SLOW = "SLW";
  private final static String _SMALL_STOP = "SST";
  private final static String _STOP = "DWN";

  private String state;

  State () {
    setUnknown ();
  }
  
  void setState (String state) {
    this.state = state;
  }
  String getState () {
    return state;
  }

  boolean isUnknown () {
    return state.equals (_UNKNOWN);
  }
  boolean isNormal () {
    return state.equals (_NORMAL);
  }
  boolean isSlow () {
    return state.equals (_SLOW);
  }
  boolean isSmallStop () {
    return state.equals (_SMALL_STOP);
  }
  boolean isStop () {
    return state.equals (_STOP);
  }

  void setUnknown () {
    state = _UNKNOWN;
  }
  void setNormal () {
    state = _NORMAL;
  }
  void setSlow () {
    state = _SLOW;
  }
  void setSmallStop () {
    state = _SMALL_STOP;
  }
  void setStop () {
    state = _STOP;
  }
  
  protected State clone () {
    try {
      return (State) super.clone ();
    }
    catch (CloneNotSupportedException e) {
      throw new AssertionError ();
    }
  }
}
