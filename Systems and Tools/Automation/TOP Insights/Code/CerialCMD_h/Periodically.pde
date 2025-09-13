class Periodically {
  long period = 1000;

  long lastTime;
  long originalTime;
  long totalRuntime;
  long lastPausedTimestamp;
  long totalPausedTime;

  int fullTimeCounter;
  int halfTimeCounter;

  boolean state;
  boolean isFirstTime = true;
  boolean originalState;
  boolean running;

  long millis () {
    return getNowEpoch ();
  }

  Periodically () {
    lastTime = millis ();
    originalTime = lastTime;
  }
  Periodically (float period) {
    this (PApplet.parseInt (period));
  }
  Periodically (long period) {
    this.period = period;
    lastTime = millis ();
    originalTime = lastTime;
  }
  Periodically (long period, boolean state) {
    this.state = state;
    originalState = state;

    this.period = period;
    lastTime = millis ();
    originalTime = lastTime;
  }

  public void start () {
    if (running) return;
    lastTime = millis ();
    running = true;
    fullTimeCounter = 0;
    halfTimeCounter = 0;
  }
  public void stop () {
    running = false;
  }
  void pause () {
    if (!isRunning ()) return;

    totalRuntime += millis () - lastTime;
    lastPausedTimestamp = millis ();
    lastTime = millis ();
    running = false;
  }
  void resume () {
    if (isRunning ()) return;

    totalPausedTime += getLastPausedDuration ();
    lastTime = millis ();
    running = true;
  }
  
  long getLastPausedDuration () {
    if (!isRunning ()) return millis () - lastPausedTimestamp;

    return 0;
  }
  long getTotalPausedTime () {
    return (isRunning ()? 0 : getLastPausedDuration ()) + totalPausedTime;
  }

  public void setPeriod (long period) {
    this.period = period;
  }
  public void setPastTime () {
    lastTime -= period;
    state = !state;
  }
  public void reset () {
    lastTime = millis ();
    lastPausedTimestamp = millis ();
    state = originalState;
    totalRuntime = 0;
    totalPausedTime = 0;
    fullTimeCounter = 0;
    halfTimeCounter = 0;
  }
  void renew (Long nowTime) {
    originalTime = nowTime;
    reset ();
  }
  void renew () {
    renew (millis ());
  }

  public boolean isRunning () {
    return running;
  }

  double getTotalRuntime () {
    return (isRunning ()? millis () - lastTime : 0) + totalRuntime;
  }

  public double getElapsedTime () {
    return millis () - lastTime;
  }
  public double getOriginalElapsedTime () {
    return millis () - originalTime;
  }
  public double getRemainingTime () {
    return period - getElapsedTime ();
  }
  public int getRemainingMillis () {
    int remainingMillis = int (getRemainingTime () + "");
    return max (0, remainingMillis);
  }
  public int getRemainingSeconds () {
    return getRemainingMillis () / 1000;
  }
  
  public boolean cycle (float timingFactor) {
    if (getElapsedTime () >= period*timingFactor) reset ();
    else return false;
    
    return true;
  }
  
  public boolean isFirstTime () {
    if (!isFirstTime) return false;
    
    isFirstTime = false;
    return true;
  }
  public boolean getState () {
    itsTime ();
    return state;
  }
  public boolean itsTime () {
    if (isPastTime ()) {
      lastTime = millis ();
      state = !state;
      fullTimeCounter ++;
      return true;
    }
    return false;
  }
  public boolean itsHalfTime () {
    if (isPastHalfTime ()) {
      lastTime = millis ();
      state = !state;
      halfTimeCounter ++;

      return true;
    }

    return false;
  }
  public boolean isPastTime () {
    return getElapsedTime () > period;
  }
  public boolean isPastOriginalTime () {
    return getOriginalElapsedTime () > period;
  }
  public boolean isPastHalfTime () {
    return getElapsedTime () > period/2.0f;
  }

  public float progress () {
    int elapsedTime = PApplet.parseInt (getElapsedTime () + "");
    return map (constrain (elapsedTime, 0, period), 0, period, 0, 100);
  }
}
