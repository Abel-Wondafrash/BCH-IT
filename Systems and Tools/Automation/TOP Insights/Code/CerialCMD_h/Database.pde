import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

class Database implements Runnable {
  private String dirPath;
  private String setPath;
  private String backupDirPath;
  private String nameSuffix = "";
  private String tableName, tableDefinition;

  private StringList queryQueue;

  private Connection conn;
  private Statement stmt;

  private Integer lastHour;
  private int UPDATE_PERIOD = 1000;
  private int BACKUP_PERIOD = 60*60*1000;

  Database (String dirPath) {
    this.dirPath = dirPath;

    queryQueue = new StringList ();
  }
  Database setPath (String setPath) {
    this.setPath = setPath;
    return this;
  }
  Database setBackupDir (String backupDirPath) {
    this.backupDirPath = backupDirPath;
    return this;
  }
  Database setNameSuffix (String nameSuffix) {
    this.nameSuffix = nameSuffix;
    return this;
  }

  void start () {
    new Thread (this).start ();
  }
  void setTableName (String tableName) {
    this.tableName = tableName;
  }
  void setTableDetails (String tableName, String tableDefinition) {
    this.tableName = tableName;
    this.tableDefinition = tableDefinition;
  }
  void setTableDefinition (String tableDefinition) {
    this.tableDefinition = tableDefinition;
  }

  String getPath () {
    if (setPath == null) return dirPath + getCurrentDir () + getCurrentName ();
    return dirPath + setPath;
  }
  String getBackupPath () {
    return backupDirPath + getCurrentDir () + "bkup_T" + getTimeNow ("h_a") + "_-_" + getCurrentName ();
  }
  String getURL () {
    return "jdbc:sqlite:" + getPath ();
  }
  String getCurrentName () {
    return getDateToday ("dd_MMM_yyyy") + ".db";
  }
  String getCurrentDir () {
    return nameSuffix + "/" + getDateToday ("yyyy/MMM/");
  }

  File getDBfile () {
    File dbFile = new File (getPath ());
    if (dbFile.exists ()) return dbFile;
    return null;
  }
  File getBackupFile () {
    File backup = new File (getBackupPath ());
    if (backup.exists ()) return backup;
    return null;
  }

  boolean exists () {
    return new File (getPath ()).exists ();
  }
  boolean connect () {
    try {
      // Create dir and sub-dirs if missing
      new File (getPath ()).getParentFile ().mkdirs ();

      // Establish a connection to the database
      conn = DriverManager.getConnection (getURL ());
      //System.out.println ("Connection to SQLite has been established.");

      setJournalMode (JOURNAL_MODE_WAL);
      return true;
    } 
    catch (SQLException e) {
      System.out.println (e.getMessage());
    }

    return false;
  }
  boolean disconnect () {
    // Close the statement and connection
    try {
      if (conn != null) conn.close();
      //System.out.println("Connection to SQLite has been closed.");
      return true;
    } 
    catch (SQLException ex) {
      System.out.println(ex.getMessage());
      return false;
    }
  }
  void execute (String query) {
    queueQuery (query);
  }
  boolean execute (String query, boolean forceExecute) {
    if (!forceExecute) {
      execute (query);
      return false;
    }

    try {
      stmt = conn.createStatement();
      stmt.execute (query);
      stmt.close();
      return true;
    } 
    catch (Exception e) {
      System.err.println (query);
      System.err.println ("Error executing command: " + e);
      return false;
    }
  }
  boolean colHasVal (String column, String value) {
    String response = getResponse ("SELECT 'true' FROM " + tableName + " WHERE " + column + "='" + value + "'" + " LIMIT 1");
    return response != null && response.equals ("true");
  }
  boolean isDBupdateRequired () {
    if (lastHour != null && lastHour == hour ()) return false;
    println ("Updating DB");
    lastHour = hour ();
    return true;
  }
  boolean isIntact () {
    String response = getResponse ("PRAGMA integrity_check;");
    return response != null && response.equals ("ok");
  }
  boolean isBackupTime () {
    File backup = getBackupFile();
    File dbFile = getDBfile ();
    if (backup == null || dbFile == null) return true;

    long dbModifiedTime = dbFile.lastModified();
    long lastBackupTime = backup.lastModified();
    long timeDifference = dbModifiedTime - lastBackupTime;

    if (timeDifference > BACKUP_PERIOD) return true;
    return false;
  }

  String getColVal (String column, String value, String fromColumn) {
    return getResponse ("SELECT " + fromColumn + " FROM " + tableName + " WHERE " + column + "='" + value + "' LIMIT 1");
  }
  String getResponse (String query) {
    if (conn == null) return null;

    String response = null;

    try {
      PreparedStatement pstmt = conn.prepareStatement(query);
      ResultSet rs = pstmt.executeQuery();
      response = rs.getString (1);
    }
    catch (Exception e) {
      //System.err.println ("Error fetching response\n> " + e);
      //System.err.println ("Query:" + query);
    }

    return response;
  }
  String getJournalMode () {
    return getResponse ("PRAGMA journal_mode;");
  }

  Integer getRowCount () {
    return getRowCount (tableName);
  }
  Integer getRowCount (String tableName) {
    String query = "SELECT COUNT(*) FROM " + tableName;
    String response = getResponse (query);

    return response == null? null : Integer.parseInt(response);
  }

  void setJournalMode (String mode) {
    String query = "PRAGMA journal_mode=" + mode + ";";
    execute (query, true);
  }
  void createTableIfMissing (String tableName, String tableDefinition) {
    execute ("CREATE TABLE IF NOT EXISTS '" + tableName + "' " + tableDefinition + "", true);
  }
  void set (String col, String val) {
    set (new String [] {col}, new String [] {val});
  }
  void set (String cols [], String vals []) {
    set (tableName, cols, vals);
  }
  void set (String tableName, String cols [], String vals []) {
    set (tableName, cols, vals, false);
  }
  void set (String tableName, String cols [], String vals [], boolean forceExecution) {
    if (cols.length != vals.length) return;

    // Curate query
    for (int i = 0; i < vals.length; i ++) vals [i] = "'" + vals [i] + "'";
    String query = "INSERT INTO '" + tableName + "'" +
      " (" + join (cols, ", ") + ") " + "VALUES" + // Columns
      " (" + join (vals, ", ") + ");"; // Values

    execute (query, forceExecution);
  }
  void update (String tableName, String col, String val, String condition) {
    update (tableName, new String [] {col}, new String [] {val}, condition);
  }
  void update (String tableName, String cols [], String vals [], String condition) {
    update (tableName, cols, vals, condition, false);
  }
  void update (String tableName, String cols [], String vals [], String condition, boolean forceExecution) {
    if (cols.length != vals.length) return;

    // Curate query
    String query = "UPDATE '" + tableName + "' SET";
    for (int i = 0; i < vals.length; i ++) query += (i == 0? " " : ", ") + cols [i] + "=" +  "'" + vals [i] + "'";
    query += " WHERE " + condition + ";";

    execute (query, forceExecution);
  }

  void queueQuery (String query) {
    queryQueue.append (query);
  }
  void createTables () {
    // Create tables
    for (Node node : nodes.nodes) if (node.isValid ()) createTableIfMissing (node.getCodename (), LOGS_TABLE_DEFINITION);
    createTableIfMissing (STATES_TABLE_NAME, STATES_TABLE_DEFINITION);
    createTableIfMissing (ACTIVITY_TABLE_NAME, ACTIVITY_TABLE_DEFINITION);

    // Set initial data
    Integer rows = getRowCount (STATES_TABLE_NAME);
    if (rows == null || rows > 0) return;

    String timestamp = getNowEpoch () + "";
    for (Node node : nodes.nodes) if (node.isValid ())
      set (
        STATES_TABLE_NAME, 
        statesHeadersTypes, 
        new String [] {node.getCodename (), timestamp + "", "-1" + ""}, // Timestamp, Value 
        true);
  }
  void run () {
    while (true) {
      if (exit != null && exit.equals (true)) exit ();

      StringList temp_queryQueue = new StringList ();
      for (int i = 0; i < queryQueue.size (); i ++) temp_queryQueue.append (queryQueue.get (i));
      queryQueue.clear ();

      if (temp_queryQueue.size () > 0) {
        connect ();
        if (isDBupdateRequired ()) createTables ();

        while (temp_queryQueue.size () > 0) {
          execute (temp_queryQueue.get (0), true);
          temp_queryQueue.remove (0);
        }

        boolean isIntact = isIntact ();
        disconnect ();

        if (!isIntact) restore ();
        else if (isBackupTime ()) backup ();
      }

      delay (UPDATE_PERIOD);
    }
  }

  void backup () {
    println ("> Backup started");
    File from = new File (getPath ());
    File to = new File (getBackupPath ());
    copyFile (from, to);
    println ("> Backup completed", getDateTimestamp ());
  }
  void restore () {
    System.err.println ("> DB Corrupted (" + getPath () + ")");
    println ("> Attempting to Restore");

    LongDict backups = new LongDict ();
    File backupsDir = new File (getBackupPath()).getParentFile ();
    backupsDir.mkdirs ();
    for (File backup : backupsDir.listFiles ()) {
      if (backup.isFile () && backup.getName ().endsWith (".db"))
        backups.add (backup.getAbsolutePath (), backup.lastModified());
    }
    backups.sortValuesReverse ();
    // No Backups Found
    if (backups.size () == 0) {
      println ("> No point to restore to. Creating new DB");
      getDBfile().delete ();
      connect ();
      createTables ();
      disconnect ();
      println ("> Restore complete", getDateTimestamp ());
      return;
    }
    // Restore to latest backup
    println ("> Restoring from most recent backup");
    File latestBackup = new File (backups.keyArray () [0]);
    println ("> ", latestBackup.getAbsolutePath ());
    copyFile (latestBackup, getDBfile ());
    println ("> Restore complete", getDateTimestamp ());
  }
}

boolean loadJDBCdriver () {
  try {
    Class.forName("org.sqlite.JDBC"); // Load the SQLite JDBC driver
    return true;
  }
  catch (ClassNotFoundException e) {
    System.err.println("SQLite JDBC driver not found.");
    e.printStackTrace();
    return false;
  }
}
