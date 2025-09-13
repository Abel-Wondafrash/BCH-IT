class Logger {
  processing.data.Table table;
  String tableRootPath;
  String tablePath;
  String logFilePrefix;

  Logger (String logTableRootPath) {
    this.tableRootPath = logTableRootPath;
  }
  
  void log (String content) {
    processing.data.StringList contents = new processing.data.StringList ();
    contents.append (content);
    log (contents);
  }
  void log (processing.data.StringList contents) {
    table = getTable ();
    if (table == null) return;

    for (String content : contents) {
      TableRow row = table.addRow ();
      
      row.setString ("timestamp", getDateToday("MMM d, yyyy - HH:mm:ss"));
      row.setString ("log", content); // key, value
    }
    
    try {
      saveTable (table, tablePath);
    } catch (Exception e) {
      println (e);
      exit ();
      return;
    }
  }
  void log (StringDict contents []) {
    table = getTable ();
    if (table == null) return;

    for (StringDict content : contents) {
      TableRow row = table.addRow ();
      
      for (String key : content.keys ()) row.setString (key, content.get (key)); // key, value
    }
    
    saveTable (table, tablePath);
  }
  
  Logger setLogFileName (String logFilePrefix) {
    this.logFilePrefix = logFilePrefix;
    return this;
  }
  String getLogPath () {
    return tableRootPath + getDateToday ("/yyyy/MMM/MMM_dd_yyyy/") + (logFilePrefix == null? "" : logFilePrefix + " - ") + appName + " Log.csv";
  }

  boolean logTableExists (String logTablePath) {
    return new File (logTablePath).exists ();
  }
  boolean changeTable () {
    return tablePath == null || !getLogPath ().equals (tablePath);
  }

  processing.data.Table getTable () {
    if (!changeTable ()) return table;

    // Renew Table Path
    tablePath = getLogPath ();

    try {
      if (logTableExists (tablePath)) return loadTable (tablePath, "header");

      table = new processing.data.Table ();
      //table.setColumnTitles(LOG_HEADERS);

      saveTable (table, tablePath);
      return table;
    }
    catch (Exception e) {
      println ("Error getting log table:", e);
      return null;
    }
  }
}
