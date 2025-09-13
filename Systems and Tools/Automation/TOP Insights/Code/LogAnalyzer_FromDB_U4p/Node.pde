// NO [F]: PRESENT > HIGH -- ABSENT > LOW 
// NC [T]: PRESENT > LOW  -- ABSENT > HIGH

class Node implements Cloneable {
  private Integer val, minProcessingTime;
  private Long lastEntryTime, countableLastEntryTime;
  private Long cycleTime, processingTime, feedTime;
  private Long lastTimestamp;
  private Long dawnTime, duskTime;

  private String codename, name;

  private float slowCyclePercentage = 0.25;

  private int idealCycleTime;
  private int slowCycleThreshold, stopTimeThreshold;
  private int totalCount, countMultiplier = 1;

  private boolean outputState, isPresentDay, isDawnClassified;

  private Records plannedStops, unknowns, idealCycles, slowCycles, smallStops, stops;
  private State state, prevState;

  private List <Record> timeline;

  Node (String codename) {
    this.codename = codename;

    plannedStops = new Records ();
    unknowns = new Records ();
    idealCycles = new Records ();
    slowCycles = new Records ();
    smallStops = new Records ();
    stops = new Records ();
    state = new State ();
    prevState = new State ();
    timeline = new ArrayList <Record> ();
  }
  Node setSetting (Setting setting) {
    setIdealCycleTime (setting.getIdealCycleTime());
    setSlowCycleThreshold (setting.getSlowCycleThreshold ());

    this.name = setting.getName ();
    return this;
  }
  Node setIdealCycleTime (int idealCycleTime) {
    this.idealCycleTime = idealCycleTime;
    this.slowCycleThreshold = int ((1 + slowCyclePercentage) * idealCycleTime);
    this.stopTimeThreshold = STOP_TIME_THRESHOLD + idealCycleTime;

    return this;
  }
  Node setSlowCycleThreshold (int slowCycleThreshold) {
    this.slowCycleThreshold = slowCycleThreshold;
    return this;
  }
  Node setPlannedStops (Records plannedStops) {
    this.plannedStops = plannedStops;
    return this;
  }
  // States
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
  Node setDawnTime (Long dawnTime) {
    this.dawnTime = dawnTime;
    this.duskTime = getDuskTime (dawnTime);
    isPresentDay = isMillisPresentDay (dawnTime);
    return this;
  }
  Node setMinProcessingTime (Integer minProcessingTime) {
    this.minProcessingTime = minProcessingTime;
    return this;
  }
  Node setCountMultiplier (int countMultiplier) {
    this.countMultiplier = countMultiplier;
    return this;
  }

  String getCodename () {
    return codename;
  }
  String getName () {
    return name;
  }

  boolean isValid () {
    return !codename.isEmpty ();
  }
  boolean isNormallyOpen () {
    return outputState == false;
  }
  boolean isNormallyClosed () {
    return outputState == true;
  }
  boolean isBlocked (int val) {
    return isNormallyOpen ()? val == 0 : val == 1;
  }
  boolean isPresentDay () {
    return isPresentDay;
  }
  boolean isDawnClassified () {
    return isDawnClassified == true;
  }

  void setEntries (LinkedHashMap <String, String> entries) {
    if (entries == null || entries.isEmpty ()) return; // Nothing to set

    List <Long> _times = stringToLongList (new ArrayList <String> (entries.keySet ()));
    List <Integer> _vals = stringToIntegerList (new ArrayList <String> (entries.values ()));

    for (int i = 0; i < _times.size (); i ++) setValue (_times.get (i), _vals.get (i));
  }
  void setStartValues (Long lastTimestamp, Long nowTimestamp) {
    if (!isPresentDay ()) return;

    classifyAvailabilityLosses (lastTimestamp, nowTimestamp);
    isDawnClassified = true;
  }
  void setEndValues () {
    long nowTimestamp = isPresentDay ()? getNowEpoch () : duskTime; // TODO: Include UNKNOWN TIME
    classifyAvailabilityLosses (lastEntryTime, nowTimestamp);
  }
  void setValue (Long nowTimestamp, Integer val) {
    if (val == null || this.val != null && this.val == val) return; // No change in value

    // Entered
    if (isBlocked (val)) {
      if (lastEntryTime != null && feedTime != null) {
        cycleTime = nowTimestamp - lastEntryTime;
        processingTime = cycleTime - feedTime;

        if (minProcessingTime == null) classifyAvailabilityLosses (lastEntryTime, nowTimestamp);
        else if (processingTime > minProcessingTime) {
          classifyAvailabilityLosses (countableLastEntryTime, nowTimestamp);
          countableLastEntryTime = nowTimestamp;

          if (totalCount == 0) totalCount ++;
        }
      }

      lastEntryTime = nowTimestamp;
      if (countableLastEntryTime == null) countableLastEntryTime = nowTimestamp;
    }
    // Exited
    else if (lastEntryTime != null) {
      feedTime = nowTimestamp - lastEntryTime;
      if (minProcessingTime == null ||
        processingTime != null && processingTime > minProcessingTime) totalCount ++;
    }

    if (this.val == null) unknowns.add (dawnTime, nowTimestamp); // First time unknowns

    lastTimestamp = nowTimestamp;
    this.val = val;
  }
  void classifyAvailabilityLosses (Long lastTimestamp, Long nowTimestamp) {
    if (!plannedStops.isEmpty ()) { // Exclude Planned Stop Times
      boolean lowerInRange = plannedStops.isInRange (lastTimestamp);
      boolean upperInRange = plannedStops.isInRange (nowTimestamp);

      // Both in range
      if (lowerInRange && upperInRange) return;
      // One in range
      if (!lowerInRange && upperInRange) nowTimestamp = plannedStops.getLowerBound (nowTimestamp);
      else if (lowerInRange && !upperInRange) lastTimestamp = plannedStops.getUpperBound (lastTimestamp);
      // Both NOT in range
      else if (plannedStops.isBounding (lastTimestamp, nowTimestamp)) {
        Record bound = plannedStops.getBounds (lastTimestamp, nowTimestamp);
        classifyAvailabilityLosses (lastTimestamp, bound.getStartTime () - 1);
        classifyAvailabilityLosses (bound.getEndTime () + 1, nowTimestamp);
        return;
      }
    }

    if (nowTimestamp == null || lastTimestamp == null) return;

    long elapsedTime = nowTimestamp - lastTimestamp;
    if (elapsedTime >= stopTimeThreshold) { // Stop Time
      stops.add (lastTimestamp, nowTimestamp, getStatus (this.val));
      state.setStop ();
    } else if (elapsedTime > slowCycleThreshold) { // Small Stop
      smallStops.add (lastTimestamp, nowTimestamp, getStatus (this.val));
      state.setSmallStop ();
    } else if (elapsedTime > idealCycleTime) { // Slow Cycle
      slowCycles.add (lastTimestamp, nowTimestamp, null);
      state.setSlow ();
    } else {
      state.setNormal ();
      idealCycles.add (lastTimestamp, nowTimestamp);
    }

    Record record;
    String nowState = state.isStop ()? State._STOP : (state.isSmallStop ()? State._SMALL_STOP : State._NORMAL);
    String prevStateStr = prevState.getState ();
    int lastIndex = max (0, timeline.size () - 1);
    boolean isOldRecord = !timeline.isEmpty () && prevStateStr.equals (nowState);

    // Remove last record if its duration was below TIMELINE_FRACTION : Only to be determined here (when new state comes to be)
    if (!timeline.isEmpty () && !isOldRecord && timeline.get (lastIndex).getDuration () < TIMELINE_FRACTION)
      timeline.remove (lastIndex);

    if (isOldRecord) record = timeline.get (lastIndex);
    else record = new Record ().setStartTime (lastTimestamp).setNote (nowState);
    record.setEndTime (nowTimestamp);

    if (!isOldRecord) timeline.add (record);

    prevState.setState (nowState);
  }
  String getStatus (Integer val) {
    if (val == null) return STATUS_UNKNOWN;
    return isBlocked (val)? STATUS_JAMMED : STATUS_STARVED;
  }

  List <Record> getTimeline () {
    return timeline;
  }
  List <Record> getRLEtimeline () { // Run-Length Encoding
    if (timeline.size () <= 1) return timeline;

    Record firstRecord = timeline.get (0).clone ();
    List <Record> rle = new ArrayList <Record> ();
    rle.add (firstRecord);

    String prevState = firstRecord.getNote ();
    for (int i = 0; i < timeline.size (); i ++) {
      if (i == 0) continue;

      Record record = timeline.get (i);

      if (prevState.equals (record.getNote ())) {
        Record prevRecord = rle.get (rle.size () - 1);
        prevRecord.setEndTime (record.getEndTime ());
      } else {
        rle.add (record);
      }

      prevState = record.getNote ();
    }

    return rle;
  }
  Records getPlannedStops () {
    return plannedStops;
  }
  Records getUnplannedStops () {
    return stops;
  }
  Records getSlowCycles () {
    return slowCycles;
  }
  Records getSmallStops () {
    return smallStops;
  }

  Long getElapsedTime (Long nowTimestamp) {
    if (nowTimestamp == null || lastTimestamp == null) return null;
    return nowTimestamp - lastTimestamp;
  }
  Long getTotalUnknownTime () {
    return unknowns.getTotalDuration ();
  }
  Long getTotalSlowCycleTime () {
    return slowCycles.getTotalDuration ();
  }
  Long getTotalSmallStopTime () {
    return smallStops.getTotalDuration ();
  }
  Long getTotalStopTime () {
    return stops.getTotalDuration ();
  }
  //Long getLastRunningDuration () {
  //  if (!state.isNormal () && !state.isSlow ()) return null;

  //  Record lastStop = stops.getLast ();
  //  Record lastSmallStop = smallStops.getLast ();

  //  Long lastTimestamp = dateToEpoch (selectedDate, "dd_MMM_yyyy");
  //  println ("SDT:", selectedDate, dawnTime);
  //  if (lastStop != null) lastTimestamp = maxLong (lastTimestamp, lastStop.getEndTime ());
  //  if (lastSmallStop != null) lastTimestamp = maxLong (lastTimestamp, lastSmallStop.getEndTime ());

  //  if (isPresentDay ()) return getNowEpoch () - lastTimestamp;
  //  return duskTime - lastTimestamp;
  //}

  int getTotalCount () {
    return totalCount * countMultiplier;
  }
  int getTotalUnitCount () {
    return totalCount;
  }

  protected Node clone () {
    try {
      Node clone = (Node) super.clone ();

      clone.plannedStops = this.plannedStops.clone ();
      clone.unknowns = this.unknowns.clone ();
      clone.slowCycles = this.slowCycles.clone ();
      clone.smallStops = this.smallStops.clone ();
      clone.stops = this.stops.clone ();
      clone.state = this.state.clone ();

      return clone;
    } 
    catch (CloneNotSupportedException e) {
      throw new AssertionError ();
    }
  }
}
