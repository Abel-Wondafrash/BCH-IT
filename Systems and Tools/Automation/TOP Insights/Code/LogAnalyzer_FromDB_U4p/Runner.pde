class Runner implements Runnable {
  private int prevDay;
  
  Runner () {
    new Thread (this).start ();
  }
  
  public void run () {
    while (true) {
      if (prevDay != day () && updateDB ()) prevDay = day ();
      
      nodes.update ();
      nodes.setMetrics ();
      
      delay (DB_UPDATE_PERIOD);
    }
  }
}

boolean updateDB () {
  Long nowEpoch = getNowEpoch ();
  String selectedDate = getFormattedDateTime (nowEpoch, DATE_PATTERN);
  //String selectedDate = "02_Sep_2025";
  String selectedMonth = getFormattedDateTime (nowEpoch, MONTH_PATTERN);
  String selectedPath = dbDir + "/" + site + "/" + year () + "/" + selectedMonth + "/" + selectedDate + ".db";
  
  println ("Selected Date:", selectedDate, selectedMonth);
  //println (selectedPath);
  
  db = new Database (selectedPath);
  if (!db.exists ()) {
    System.err.println ("DB Does NOT Exist\n>> " + selectedPath);
    delay (DB_RECHECK_PERIOD);
    return false;
  }

  Long dawnTime = getDawnEpoch (selectedDate, DATE_PATTERN);
  Records plannedStops = new Records ("PLANNED STOPS").setDateMillis (dawnTime).setTimePattern (TIME_PATTERN_MILLIS);
  //plannedStops.add ("08:00:00:000 AM", "08:59:59:999 AM");
  //plannedStops.add ("07:00:00:000 PM", "07:59:59:999 PM");

  // Scheduled Loss Times
  Records scheduledLossTime = new Records ("SCHEDULED LOSS TIME").setDateMillis (dawnTime);
  //scheduledLossTime.add ("10:00:00 AM", "11:00:00 AM");

  // Nodes
  nodes = new Nodes (db)
    .setScheduledLossTime (scheduledLossTime)
    .setPlannedStops (plannedStops)
    .setDawnTime (dawnTime);
  nodes.init ();
  
  return true;
}
