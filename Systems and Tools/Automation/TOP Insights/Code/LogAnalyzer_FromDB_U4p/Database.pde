import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.DatabaseMetaData;

import java.util.List;

class Database implements Runnable {
  private String setPath;
  private String tableName;
  private List <String> tablesList;

  private Connection conn;
  private Statement stmt;

  private int UPDATE_PERIOD = 1000;

  Database (String setPath) {
    this.setPath = setPath;

    if (!exists ()) return;

    connect ();
    tablesList = getTablesList (true);
    disconnect ();
  }

  void start () {
    new Thread (this).start ();
  }

  String getPath () {
    return setPath;
  }
  String getURL () {
    return "jdbc:sqlite:" + getPath ();
  }
  List <String> getTablesList () {
    return tablesList;
  }
  List <String> getTablesList (boolean reload) {
    if (reload == false) return tablesList;
    
    List <String> list = new ArrayList <String> ();
    try {
      DatabaseMetaData metaData = conn.getMetaData();
      ResultSet tables = metaData.getTables (null, null, "%", new String [] {"TABLE"});
      while (tables.next()) list.add (tables.getString ("TABLE_NAME"));
    }
    catch (Exception e) {
      println ("Error getting tables list", e);
    }

    return list;
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
  boolean execute (String query) {
    try {
      stmt = conn.createStatement();
      stmt.execute (query);
      stmt.close();
      return true;
    } 
    catch (Exception e) {
      System.err.println ("Error executing command:" + e);
      return false;
    }
  }
  boolean colHasVal (String column, String value) {
    String response = getResponse ("SELECT 'true' FROM " + tableName + " WHERE " + column + "='" + value + "'" + " LIMIT 1");
    return response != null && response.equals ("true");
  }
  boolean isIntact () {
    String response = getResponse ("PRAGMA integrity_check;");
    return response != null && response.equals ("ok");
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
  LinkedHashMap <String, String> getResponses (String query, String key, String val) {
    if (conn == null) return null; // Return an empty array instead of null

    LinkedHashMap <String, String> responses = new LinkedHashMap <String, String> ();
    
    try {
      PreparedStatement pstmt = conn.prepareStatement(query);
      ResultSet rs = pstmt.executeQuery();

      while (rs.next()) responses.put (rs.getString (key), rs.getString (val));
    }
    catch (SQLException e) {
      e.printStackTrace(); // Log the error for debugging
    }

    return responses;
  }
  String getJournalMode () {
    return getResponse ("PRAGMA journal_mode;");
  }

  Integer getRowCount () {
    return getRowCount (tableName);
  }
  Integer getRowCount (String tableName) {
    String query = "SELECT COUNT(*) FROM " + "'" + tableName + "'";
    String response = getResponse (query);

    return response == null? null : Integer.parseInt(response);
  }

  void setJournalMode (String mode) {
    String query = "PRAGMA journal_mode=" + mode + ";";
    execute (query);
  }

  //void createTables () {
  //  // Create tables
  //  for (Node node : nodes.nodes) if (node.isValid ()) createTableIfMissing (node.getCodename (), LOGS_TABLE_DEFINITION);
  //  createTableIfMissing (ACTIVITY_TABLE_NAME, ACTIVITY_TABLE_DEFINITION);
  //}
  void run () {
    while (true) {

      delay (UPDATE_PERIOD);
    }
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
