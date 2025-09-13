import java.util.LinkedHashMap;

class Nodes {
  private List <String> codenames, allCodenames;
  private List <Node> nodes;
  private List <Metrics> metrics;
  private Database db;
  private Settings settings;

  private LinkedHashMap <String, Node> clones;

  private Long dawnTime;
  private LongDict lastTimes;
  private Records scheduledLossTime, plannedStops;
  
  private boolean running = false;
  
  Nodes () {
  }

  Nodes (Database db) {
    this.db = db;
    this.allCodenames = db.getTablesList ();

    // Initializations
    settings = new Settings ();
    lastTimes = new LongDict ();
  }
  Nodes setScheduledLossTime (Records scheduledLossTime) {
    this.scheduledLossTime = scheduledLossTime;
    return this;
  }
  Nodes setPlannedStops (Records plannedStops) {
    this.plannedStops = plannedStops;
    return this;
  }
  Nodes setDawnTime (Long dawnTime) {
    this.dawnTime = dawnTime;
    return this;
  }

  void init () {
    codenames = new ArrayList <String> ();
    nodes = new ArrayList <Node> ();
    clones = new LinkedHashMap <String, Node> ();
    metrics = new ArrayList <Metrics> ();

    for (String codename : settings.getCodenames ()) { // Codenames in order set by Settings
      if (!allCodenames.contains (codename)) continue;
      if (!codenames.contains (codename)) codenames.add (codename);

      Setting setting = settings.getSetting (codename);
      Node node = new Node (codename)
        .setSetting (setting)
        .setPlannedStops (plannedStops)
        .setDawnTime (dawnTime)
        .setCountMultiplier (setting.getCountMultiplier ())
        .setMinProcessingTime (setting.getMinProcessingTime ());
      nodes.add (node);

      Metrics _metrics = new Metrics (dawnTime);
      _metrics.setScheduledLossTimes (scheduledLossTime);
      _metrics.setNode (node);
      _metrics.update();
      metrics.add (_metrics);
    }
  }
  void update () {
    boolean hasUpdate = false;

    db.connect ();
    for (String codename : settings.getCodenames ()) { // Codenames in order set by Settings
      if (!allCodenames.contains (codename)) continue;

      String queryCondition = lastTimes.hasKey (codename)? " WHERE UNIX > " + lastTimes.get (codename) : "";
      LinkedHashMap <String, String> entries = db.getResponses ("SELECT UNIX,STATE  FROM '" + codename + "'" + queryCondition, "UNIX", "STATE");

      // Keep record of last entry times
      if (entries != null && !entries.isEmpty ()) {
        List <String> keys = new ArrayList <String> (entries.keySet ());
        lastTimes.set (codename, Long.parseLong (keys.get (keys.size () - 1)));
      }

      Node node = hasClone (codename)? getClone (codename) : getNode (codename);

      if (!node.isDawnClassified ()) {
        String uptoTimestamp = getNowEpoch () + "";
        if (entries != null && !entries.isEmpty ()) {
          List <String> startTimes = new ArrayList <String> (entries.keySet ());
          uptoTimestamp = startTimes.get (0);
        }
        node.setStartValues (dawnTime, Long.parseLong (uptoTimestamp));
      }
      node.setEntries (entries);
      clones.put (codename, node.clone ()); // Keep node's clone
      node.setEndValues ();

      setNode (codename, node);
      getMetrics (codename).setNode (node);
      getMetrics (codename).update ();
      hasUpdate = true;
    }
    db.disconnect ();

    if (hasUpdate && isServerAvailable ()) sendData (getData ());
  }

  JSONObject getPlantData () {
    String dateStamp = getFormattedDateTime (dawnTime, "EEE, MMM dd, yyyy");

    JSONObject plantData = new JSONObject ();
    plantData.setString ("datestamp", dateStamp);
    plantData.setString ("site", "TOP 1");
    plantData.setString ("line", "L1");
    plantData.setString ("product", "2L WB");

    return plantData;
  }
  JSONObject getData () {
    JSONObject nodesData = new JSONObject ();
    nodesData.setJSONObject ("plant_data", getPlantData ());

    String codenames [] = {"02-BLW", "11-EYM", "05-PKB", "09-PLT"};
    String labels [] = {"BLW", "LBL", "PKR", "PLT"};
    for (int a = 0; a < codenames.length; a ++) {
      String label = labels [a];
      JSONObject nodeData = getNodeData (codenames [a]);
      if (nodeData != null) nodesData.setJSONObject (label, nodeData);
    }

    return nodesData;
  }
  JSONObject getNodeData (String codename) {
    if (codename == null) return null;

    Metrics metrics = getMetrics (codename);
    JSONObject overviews = new JSONObject();
    // Fundamentals
    overviews.setFloat("ava", metrics.getAvailability ());
    overviews.setFloat("prf", metrics.getPerformance ());
    overviews.setFloat("qua", metrics.getQuality ());
    overviews.setFloat("oee", metrics.getOEE ());
    overviews.setString ("lst", metrics.node.state.getState ());

    JSONObject details_ava = new JSONObject ();
    // Details: Availability
    details_ava.setString ("runtime", getFormattedDuration (metrics.getRuntime ()));
    details_ava.setInt ("runtime_c", metrics.getRuntimeCounts ());
    details_ava.setFloat ("runtime_p", metrics.getRuntimePercentage ());

    details_ava.setString ("ava_loss", getFormattedDuration (metrics.getAvailabilityLoss ()));
    details_ava.setInt ("ava_loss_c", metrics.getAvailabilityLossCounts ());
    details_ava.setFloat ("ava_loss_p", metrics.getAvailabilityLossPercentage ());

    details_ava.setString ("unp_stop", getFormattedDuration (metrics.getUnplannedStopTime ()));
    details_ava.setInt ("unp_stop_c", metrics.getUnplannedStopTimeCounts ());
    details_ava.setFloat ("unp_stop_p", metrics.getUnplannedStopTimePercentage ());

    details_ava.setString ("pln_stop", getFormattedDuration (metrics.getPlannedStopTime ()));
    details_ava.setInt ("pln_stop_c", metrics.getPlannedStopTimeCounts ());
    details_ava.setFloat ("pln_stop_p", metrics.getPlannedStopTimePercentage ());

    JSONObject details_prf = new JSONObject ();
    // Details: Performance
    details_prf.setString ("net_runtime", getFormattedDuration (metrics.getNetRuntime ()));
    details_prf.setInt ("net_runtime_c", metrics.getNetRuntimeCounts ());
    details_prf.setFloat ("net_runtime_p", metrics.getNetRuntimePercentage ());

    details_prf.setString ("prf_loss", getFormattedDuration (metrics.getPerformanceLoss ()));
    details_prf.setInt ("prf_loss_c", metrics.getPerformanceLossCounts ());
    details_prf.setFloat ("prf_loss_p", metrics.getPerformanceLossPercentage ());

    details_prf.setString ("slow_cycles", getFormattedDuration (metrics.getSlowCycles ()));
    details_prf.setInt ("slow_cycles_c", metrics.getSlowCycleCounts ());
    details_prf.setFloat ("slow_cycles_p", metrics.getSlowCyclesPercentage ());

    details_prf.setString ("small_stops", getFormattedDuration (metrics.getSmallStops ()));
    details_prf.setInt ("small_stops_c", metrics.getSmallStopCounts ());
    details_prf.setFloat ("small_stops_p", metrics.getSmallStopsPercentage ());

    JSONObject details_qua = new JSONObject ();
    // Details: Quality
    details_qua.setString ("fully_productive_time", getFormattedDuration (metrics.getFullyProductiveTime ()));
    details_qua.setInt ("fully_productive_time_c", metrics.getFullyProductiveTimeCounts ());
    details_qua.setFloat ("fully_productive_time_p", metrics.getFullyProductiveTimePercentage ());

    details_qua.setString ("qua_loss", getFormattedDuration (metrics.getQualityLoss ()));
    details_qua.setInt ("qua_loss_c", metrics.getRejectCount ());
    details_qua.setFloat ("qua_loss_p", metrics.getQualityLossPercentage ());

    details_qua.setInt ("good_c", metrics.getGoodCount ());
    details_qua.setFloat ("good_p", metrics.getGoodPercentage ());

    details_qua.setInt ("reject_c", metrics.getRejectCount ());
    details_qua.setFloat ("reject_p", metrics.getRejectPercentage ());

    JSONObject timeline = new JSONObject ();
    JSONArray fractionArray = new JSONArray();
    Node node = metrics.getNode ();
    for (Record each : node.getRLEtimeline ()) {
      fractionArray.append (new JSONObject ()
        .setString ("s", each.getNote ())
        .setString ("f", each.getFraction () + "")
        );
    }
    timeline.setJSONArray("timeline_data", fractionArray);

    return new JSONObject ()
      .setJSONObject ("overviews", overviews)
      .setJSONObject ("details_ava", details_ava)
      .setJSONObject ("details_prf", details_prf)
      .setJSONObject ("details_qua", details_qua)
      .setJSONObject ("timeline", timeline);
  }

  Metrics getMetrics (String codename) {
    if (!codenames.contains (codename)) return null;
    int index = codenames.indexOf (codename);
    return metrics.get (index);
  }
  void setNode (String codename, Node node) {
    if (!codenames.contains (codename)) return;

    int index = codenames.indexOf (codename);
    nodes.set (index, node);
  }
  Node getNode (String codename) {
    if (!codenames.contains (codename)) return null;
    int index = codenames.indexOf (codename);
    return nodes.get (index);
  }
  Node getNode (int index) {
    if (nodes == null || index < 0 || index + 1 > nodes.size ()) return null;
    return nodes.get (index);
  }
  Node getNext (Node node) {
    if (node == null || !nodes.contains (node)) return null;

    int index = nodes.indexOf (node);
    if (index + 1 >= nodes.size ()) return null;

    return getNode (index + 1);
  }
  Node getClone (String codename) {
    return (Node) clones.get (codename);
  }

  boolean hasClone (String codename) {
    return clones.containsKey (codename);
  }

  Metrics getMetrics (Node node) {
    if (node == null) return null;
    if (!nodes.contains (node)) return null;

    int index = nodes.indexOf (node);
    return metrics.get (index);
  }

  void setMetrics () {
    for (Node node : nodes) {
      Metrics metrics = getMetrics (node);
      if (metrics != null) metrics.setNextNode (getNext (node));
    }
  }
}
