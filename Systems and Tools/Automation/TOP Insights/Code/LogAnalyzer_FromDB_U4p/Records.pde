class Records implements Cloneable {
  List <Long> startTimes, endTimes, durations;
  List <String> notes;

  Long totalDuration = 0l, absMin, absMax;
  Long subtrahend = 0l;

  String label = "RECORD";
  String formattedDate, datePattern = "MMM dd, yyyy", timePattern = TIME_PATTERN;

  Records () {
    startTimes = new ArrayList <Long> ();
    endTimes = new ArrayList <Long> ();
    durations = new ArrayList <Long> ();
    notes = new ArrayList <String> ();
  }
  Records (String label) {
    this ();
    this.label = label;
  }
  Records setLabel (String label) {
    this.label = label;
    return this;
  }
  Records setDateMillis (Long dateMillis) {
    formattedDate = getFormattedDate (dateMillis);
    return this;
  }
  Records setTimePattern (String timePattern) {
    this.timePattern = timePattern;
    return this;
  }

  void add (String startTimeStr, String endTimeStr) {
    add (startTimeStr, endTimeStr, null);
  }
  void add (String startTimeStr, String endTimeStr, String note) {
    if (formattedDate == null) return;

    Long startTime = dateTimeToEpoch (formattedDate + " " + startTimeStr, datePattern + " " + timePattern);
    Long endTime = dateTimeToEpoch (formattedDate + " " + endTimeStr, datePattern + " " + timePattern);
    add (startTime, endTime, note);
  }
  void add (Long startTime, Long endTime) {
    add (startTime, endTime, null);
  }
  void add (Long startTime, Long endTime, String note) {
    if (startTime == null || endTime == null) return;

    Long duration = endTime - startTime;

    startTimes.add (startTime);
    endTimes.add (endTime);
    durations.add (duration);
    notes.add (note);

    absMin = absMin == null? startTime : minLong (absMin, startTime);
    absMax = absMax == null? endTime : maxLong (absMax, endTime);

    totalDuration += duration;
  }
  void deduct (Records subtrahend) {
    this.subtrahend = subtrahend.getTotalDuration();
  }

  boolean isEmpty () {
    return size () == 0;
  }
  boolean isInRange (Long epochTime) {
    if (absMin == null || absMax == null) return false;
    if (epochTime < absMin || epochTime > absMax) return false; // Out of range

    for (int i = 0; i < size (); i ++) if (epochTime >= startTimes.get (i) && epochTime <= endTimes.get (i)) return true;
    return false;
  }
  boolean isBounding (Long fromEpoch, Long toEpoch) {
    if (isEmpty () || fromEpoch == null || toEpoch == null) return false;

    for (int i = 0; i < size (); i ++) if (startTimes.get (i) >= fromEpoch && endTimes.get (i) <= toEpoch) return true;

    return false;
  }

  Record getBounds (Long fromEpoch, Long toEpoch) {
    if (!isBounding (fromEpoch, toEpoch)) return null;

    for (int i = 0; i < size (); i ++)
      if (startTimes.get (i) >= fromEpoch && endTimes.get (i) <= toEpoch)
        return new Record (startTimes.get (i), endTimes.get (i), notes.get (i));

    return null;
  }
  Record getLast () {
    if (isEmpty ()) return null;

    int index = size () - 1;
    return new Record (startTimes.get (index), endTimes.get (index), notes.get (index));
  }

  Long getLastDuration () {
    if (isEmpty ()) return null;

    int index = size () - 1;
    return getDuration (index);
  }
  Long getLowerBound (Long epochTime) {
    if (!isInRange (epochTime)) return null;
    for (int i = 0; i < size (); i ++) if (epochTime >= startTimes.get (i) && epochTime <= endTimes.get (i)) return startTimes.get (i);
    return null;
  }
  Long getUpperBound (Long epochTime) {
    if (!isInRange (epochTime)) return null;
    for (int i = 0; i < size (); i ++) if (epochTime >= startTimes.get (i) && epochTime <= endTimes.get (i)) return endTimes.get (i);
    return null;
  }
  Long getStartTime (int index) {
    if (size () < index + 1) return null;
    return startTimes.get (index);
  }
  Long getEndTime (int index) {
    if (size () < index + 1) return null;
    return endTimes.get (index);
  }
  Long getDuration (int index) {
    if (size () < index + 1) return null;
    return durations.get (index);
  }
  Long getTotalDuration () {
    return totalDuration - subtrahend;
  }

  String getNote (int index) {
    if (size () < index + 1) return null;
    return notes.get (index);
  }

  int size () {
    return startTimes.size ();
  }

  protected Records clone () {
    try {
      // Shallow copy
      Records clone = (Records) super.clone ();

      // Deep copy the mutable lists to avoid shared references
      clone.startTimes = new ArrayList <Long> (this.startTimes);
      clone.endTimes = new ArrayList <Long> (this.endTimes);
      clone.durations = new ArrayList <Long> (this.durations);
      clone.notes = new ArrayList <String> (this.notes);

      return clone;
    } 
    catch (CloneNotSupportedException e) {
      throw new AssertionError ();
    }
  }
}

class Record implements Cloneable {
  Long startTime, endTime, duration;
  String note;
  
  Record () {
  }
  Record (Long startTime, Long endTime) {
    this.startTime = startTime;
    this.endTime = endTime;
  }
  Record (Long startTime, Long endTime, String note) {
    this (startTime, endTime);
    this.note = note;
  }
  
  Record setStartTime (Long startTime) {
    this.startTime = startTime;
    return this;
  }
  Record setEndTime (Long endTime) {
    this.endTime = endTime;
    return this;
  }
  Record setNote (String note) {
    this.note = note;
    return this;
  }

  Long getStartTime () {
    return startTime;
  }
  Long getEndTime () {
    return endTime;
  }
  Long getDuration () {
    return endTime - startTime;
  }
  
  Float getFraction () {
    Float fraction = getDuration () * 1.0 / (24 * 3600 * 1000);
    return float (nfc (fraction, 3));
  }
  
  String getNote () {
    return note;
  }
  
  protected Record clone () {
    try {
      return (Record) super.clone ();
    } 
    catch (CloneNotSupportedException e) {
      throw new AssertionError ();
    }
  }
}
