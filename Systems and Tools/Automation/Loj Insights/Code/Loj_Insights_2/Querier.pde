import java.sql.*;

class Querier {
  // Database connection details
  String url = "jdbc:postgresql://localhost:5432/TOP_2018";
  String user = "openpg";
  String password = "openpgpwd"; // Add your password if needed

  boolean valid;
  String query;

  Querier (String queryPath, String lineToReplace, String lineToReplaceWith) {
    File queryFile = new File (queryPath);
    if (!queryFile.exists ()) {
      println ("Query File Does Not Exist:", queryPath);
      return;
    }

    try {
      String queryRaw [] = loadStrings (queryPath);
      if (queryRaw == null || queryRaw.length < 1) {
        println ("Empty Query");
        return;
      }
      query = join (queryRaw, "\n");
    }
    catch (Exception e) {
      println ("Error loading query file:", queryPath);
      return;
    }

    query = query.replace (lineToReplace, lineToReplaceWith);
    valid = true;
  }

  String getQuery () {
    return query;
  }

  boolean isValid () {
    return valid;
  }

  Table getOutput () {
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    Table table = new Table();
    boolean success = false;

    try {
      Class.forName("org.postgresql.Driver");
      conn = DriverManager.getConnection(url, user, password);
      stmt = conn.createStatement();
      rs = stmt.executeQuery(getQuery());

      ResultSetMetaData rsmd = rs.getMetaData();
      int columnsNumber = rsmd.getColumnCount();

      // Add column titles
      for (int i = 1; i <= columnsNumber; i++) {
        table.addColumn(rsmd.getColumnName(i));
      }

      // Add rows
      while (rs.next()) {
        TableRow newRow = table.addRow();
        for (int i = 1; i <= columnsNumber; i++) {
          newRow.setString(rsmd.getColumnName(i), rs.getString(i));
        }
      }

      success = true; // Mark as successful
    } 
    catch (Exception e) {
      println("Error fetching data:");
      e.printStackTrace();
    } 
    finally {
      // Always close resources
      try {
        if (rs != null) rs.close();
      } 
      catch (SQLException se) {
        println("Error closing ResultSet:");
        se.printStackTrace();
      }

      try {
        if (stmt != null) stmt.close();
      } 
      catch (SQLException se) {
        println("Error closing Statement:");
        se.printStackTrace();
      }

      try {
        if (conn != null) conn.close();
      } 
      catch (SQLException se) {
        println("Error closing Connection:");
        se.printStackTrace();
      }

      // Return null if anything went wrong
      if (!success) table = null;
    }

    return table;
  }
}
