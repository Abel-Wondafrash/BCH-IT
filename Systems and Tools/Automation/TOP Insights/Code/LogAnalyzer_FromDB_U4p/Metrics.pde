class Metrics {
  private Long dawnTime;
  private Records allTime, scheduledLossTime;
  private Records plannedProductionTime;

  private Node node, nextNode;

  private boolean isPresentDay;

  Metrics (Long dawnTime) {
    this.dawnTime = dawnTime;
    isPresentDay = isMillisPresentDay (dawnTime);
    setAllTime (); // All Time
  }

  private void setAllTime () {
    allTime = new Records ("ALL TIME").setDateMillis (dawnTime).setTimePattern (TIME_PATTERN_MILLIS);
    allTime.add ("12:00:00:000 AM", "11:59:59:999 PM", "ALL TIME");
  }
  void setScheduledLossTimes (Records scheduledLossTime) {
    this.scheduledLossTime = scheduledLossTime;
  }
  void setNode (Node node) {
    this.node = node;
  }
  void setNextNode (Node nextNode) {
    this.nextNode = nextNode;
  }

  void update () {
    plannedProductionTime = new Records ();
    plannedProductionTime.add (allTime.getStartTime (0), isPresentDay? getNowEpoch () : allTime.getEndTime (0));
    plannedProductionTime.deduct (scheduledLossTime);
  }
  
  Node getNode () {
    return this.node;
  }

  Long getAllTime () {
    return allTime.getTotalDuration ();
  }

  // Availability
  Long getUnknownTime () {
    return node == null? null : node.getTotalUnknownTime ();
  }
  Long getPlannedProductionTime () {
    return plannedProductionTime.getTotalDuration ();
  }
  Long getPlannedStopTime () {
    return node == null? null : node.getPlannedStops ().getTotalDuration();
  }
  Long getUnplannedStopTime () {
    return node == null? null : node.getUnplannedStops ().getTotalDuration();
  }
  Long getAvailabilityLoss () {
    Long pst = getPlannedStopTime (), ust = getUnplannedStopTime ();
    if (pst == null || ust == null) return null;
    return pst + ust;
  }
  Long getRuntime () {
    Long ppt = getPlannedProductionTime (), avl = getAvailabilityLoss ();
    if (ppt == null || avl == null) return null;
    return ppt - avl;
  }
  Float getAvailability () {
    Long ppt = getPlannedProductionTime (), runtime = getRuntime ();
    if (runtime == null || ppt == null || ppt == 0l) return null;
    return runtime.floatValue () / ppt.floatValue ();
  }

  // Performance
  Long getSlowCycles () {
    return node == null? null : node.getSlowCycles ().getTotalDuration () - node.getSlowCycles ().size ()*node.idealCycleTime;
  }
  Long getSmallStops () {
    return node == null? null : node.getSmallStops ().getTotalDuration ();
  }
  Long getPerformanceLoss () {
    Long slowCycles = getSlowCycles (), smallStops = getSmallStops ();
    if (slowCycles == null || smallStops == null) return null;
    return slowCycles + smallStops;
  }
  Long getNetRuntime () {
    Long runtime = getRuntime (), performanceLoss = getPerformanceLoss ();
    if (runtime == null || performanceLoss == null) return null;
    return runtime - performanceLoss;
  }
  Float getPerformance () {
    Long runtime = getRuntime (), netRuntime = getNetRuntime ();
    if (netRuntime == null || runtime == null) return null;
    if (runtime == 0l) return 1f;
    return netRuntime.floatValue () / runtime.floatValue ();
  }

  // Quality
  Integer getTotalCount () {
    return node.getTotalCount ();
  }
  Integer getTotalUnitCount () {
    return node.getTotalUnitCount ();
  }
  Integer getRawGoodCount () {
    if (nextNode == null) return getTotalCount ();
    return nextNode.getTotalCount ();
  }
  Integer getGoodCount () {
    if (nextNode == null) getTotalCount ();
    Integer goodCount = max (0, getRawGoodCount ()) - max (0, getReworkCount ()) - max (0, getRejectCount ());

    return goodCount < 0? -1 : goodCount;
  }
  Integer getReworkCount () {
    if (nextNode == null) return 0;
    Integer reworkCount = max (0, getRawGoodCount ()) - max (0, getTotalCount ());
    return reworkCount < 0? -1 : reworkCount;
  }
  Integer getRejectCount () {
    if (nextNode == null) return 0;
    Integer rejectCount = max (0, getTotalCount ()) - max (0, getRawGoodCount ());
    return rejectCount < 0? -1 : rejectCount;
  }
  Float getQuality () {
    if (nextNode == null) return 1f;
    Integer totalCount = getTotalCount ();
    Integer goodCount = getGoodCount ();
    if (goodCount <= 0 || totalCount == 0) return 0f;
    return goodCount*1.0 / totalCount;
  }
  Long getFullyProductiveTime () {
    if (nextNode == null) return getNetRuntime ();
    Float quality = getQuality ();
    double fpt = Double.parseDouble (quality * getNetRuntime () + "");
    return (long) fpt;
  }
  Long getQualityLoss () {
    if (nextNode == null) return 0l;
    return getNetRuntime () - getFullyProductiveTime ();
  }

  // OEE
  Float getOEE () {
    return getAvailability () * getPerformance () * getQuality ();
  }

  // Cycle Counts: AVA
  int getRuntimeCounts () {
    return node.idealCycles.size () + node.slowCycles.size () + node.smallStops.size ();
  }
  int getAvailabilityLossCounts () {
    return getUnplannedStopTimeCounts () + getPlannedStopTimeCounts ();
  }
  int getUnplannedStopTimeCounts () {
    return node.stops.size ();
  }
  int getPlannedStopTimeCounts () {
    return node.plannedStops.size ();
  }
  // Cycle Counts: PRF
  int getNetRuntimeCounts () {
    return node.idealCycles.size ();
  }
  int getPerformanceLossCounts () {
    return getSmallStopCounts () + getSlowCycleCounts ();
  }
  int getSlowCycleCounts () {
    return node.slowCycles.size ();
  }
  int getSmallStopCounts () {
    return node.smallStops.size ();
  }
  // Cycle Counts: QUA
  int getFullyProductiveTimeCounts () {
    return node.idealCycles.size ();
  }

  // Percentages: AVA
  float getRuntimePercentage () {
    Long runtime = getRuntime ();
    Long allTime = getAllTime ();
    if (runtime == null || allTime == 0) return 0;
    return runtime.floatValue () / allTime.floatValue ();
  }
  float getAvailabilityLossPercentage () {
    Long avl = getAvailabilityLoss ();
    Long allTime = getAllTime ();
    if (avl == null || allTime == null || allTime == 0l) return 0;
    return avl.floatValue () / allTime.floatValue ();
  }
  float getUnplannedStopTimePercentage () {
    Long ust = getUnplannedStopTime ();
    Long allTime = getAllTime ();
    if (ust == null || allTime == null || allTime == 0l) return 0;
    return ust.floatValue () / allTime.floatValue ();
  }
  float getPlannedStopTimePercentage () {
    Long pst = getPlannedStopTime ();
    Long allTime = getAllTime ();
    if (pst == null || allTime == null || allTime == 0l) return 0;
    return pst.floatValue () / allTime.floatValue ();
  }

  // Percentages: PRF
  float getNetRuntimePercentage () {
    Long netRuntime = getNetRuntime ();
    Long allTime = getAllTime ();
    if (netRuntime == null || allTime == 0) return 0;
    return netRuntime.floatValue () / allTime.floatValue ();
  }
  float getPerformanceLossPercentage () {
    Long plp = getPerformanceLoss ();
    Long allTime = getAllTime ();
    if (plp == null || allTime == 0) return 0;
    return plp.floatValue () / allTime.floatValue ();
  }
  float getSlowCyclesPercentage () {
    Long slc = getSlowCycles ();
    Long allTime = getAllTime ();
    if (slc == null || allTime == 0) return 0;
    return slc.floatValue () / allTime.floatValue ();
  }
  float getSmallStopsPercentage () {
    Long sms = getSmallStops ();
    Long allTime = getAllTime ();
    if (sms == null || allTime == 0) return 0;
    return sms.floatValue () / allTime.floatValue ();
  }

  // Percentages: QUA
  float getFullyProductiveTimePercentage () {
    Long fullyPT = getFullyProductiveTime ();
    Long allTime = getAllTime ();
    if (fullyPT == null || allTime == 0) return 0;
    return fullyPT.floatValue () / allTime.floatValue ();
  }
  float getQualityLossPercentage () {
    Long quaLoss = getQualityLoss ();
    Long allTime = getAllTime ();
    if (quaLoss == null || allTime == 0) return 0;
    return quaLoss.floatValue () / allTime.floatValue ();
  }
  float getGoodPercentage () {
    Integer goodCount = getGoodCount ();
    Integer totalCount = getTotalCount ();
    if (goodCount == null || totalCount == null || totalCount == 0) return 0;
    return goodCount.floatValue () / totalCount.floatValue ();
  }
  float getRejectPercentage () {
    Integer rejectCount = getRejectCount ();
    Integer totalCount = getTotalCount ();
    if (rejectCount == null || totalCount == null || totalCount == 0) return 0;
    return rejectCount.floatValue () / totalCount.floatValue ();
  }
}
