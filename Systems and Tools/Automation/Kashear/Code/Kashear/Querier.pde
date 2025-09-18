import java.sql.*;

class Querier {
  String queryPath;

  Querier (String queryPath) {
    this.queryPath = queryPath;
  }

  String getQuery () {
    File queryFile = new File (queryPath);
    if (!queryFile.exists ()) {
      println ("Query File Does Not Exist:", queryPath);
      cLogger.log ("Query File Does Not Exist: " + queryPath);
      return null;
    }
    String query;

    try {
      String queryRaw [] = loadStrings (queryPath);
      if (queryRaw == null || queryRaw.length < 1) {
        println ("Empty Query");
        cLogger.log ("Empty Query");
        return null;
      }

      query = join (queryRaw, "\n");
    }
    catch (Exception e) {
      println ("Error loading query file:", queryPath);
      cLogger.log ("Error loading query file: " + queryPath + " " + e);
      return null;
    }

    return query;
  }
  String getQuery (String lineToReplace, String lineToReplaceWith) {
    return getQuery ().replace (lineToReplace, lineToReplaceWith);
  }
  String getQuery (String linesToReplace [], String linesToReplaceWith []) {
    if (linesToReplace == null || linesToReplaceWith == null) return null;
    if (linesToReplace.length != linesToReplaceWith.length) return null;

    String query = getQuery ();
    for (int i = 0; i < linesToReplace.length; i ++)
      query = query.replace (linesToReplace [i], linesToReplaceWith [i]);

    return query;
  }

  boolean isValid () {
    return getQuery () != null;
  }

  processing.data.Table getOutput(String query) {
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    processing.data.Table table = new processing.data.Table();
    boolean success = false;

    try {
      Class.forName("org.postgresql.Driver");
      String dbURL = "jdbc:postgresql://" + DB_IP + ":" + DB_PORT + "/" + DB_NAME;;
      conn = DriverManager.getConnection(dbURL, DB_USER, DB_PASS);
      stmt = conn.createStatement();

      boolean hasResultSet = stmt.execute(query);

      if (!hasResultSet) return table;

      rs = stmt.getResultSet();
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

      success = true;
    }
    catch (org.postgresql.util.PSQLException e) {
      println("Connection failed: " + e.getMessage());
      cLogger.log ("Connection failed: " + e.getMessage());
    } 
    catch (Exception e) {
      println("Error fetching data:");
      cLogger.log ("Error fetching data:" + e);
      e.printStackTrace();
    } 
    finally {
      try {
        if (rs != null) rs.close();
        if (stmt != null) stmt.close();
        if (conn != null) conn.close();
      } 
      catch (SQLException se) {
        se.printStackTrace();
      }

      if (!success) table = null;
    }

    return table;
  }
}

processing.data.Table getVoucherDetails (String voucherCode) {
  if (!isValidInteger (voucherCode)) {
    println ("Invalid voucher code. Code should only consist of a number. '" + voucherCode + "'");
    cLogger.log ("Invalid voucher code. Code should only consist of a number. '" + voucherCode + "'");
    return null;
  }

  //println ("\nObtaining order details for '" + voucherCode + "'");
  String query = qDetails.getQuery (
    "WHERE so.name = ", // Line to replace
    "WHERE so.name = '" + SALES_ORDER_PREFIX + voucherCode + "'" // Replace line with
    );
  
  if (query == null) {
    println ("Query is null");
    cLogger.log ("Query is null");
    return null;
  }

  return qDetails.getOutput (query);
}

processing.data.Table getFS (String voucherCode) {
  if (!isValidInteger (voucherCode)) {
    println ("Invalid voucher code. Code should only consist of a number. '" + voucherCode + "'");
    cLogger.log ("Invalid voucher code. Code should only consist of a number. '" + voucherCode + "'");
    return null;
  }

  //println ("\nObtaining FS Number for '" + voucherCode + "'");
  String query = qGetFS.getQuery (
    "WHERE name = ", // Line to replace
    "WHERE name = '" + SALES_ORDER_PREFIX + voucherCode + "'" // Replace line with
    );

  if (query == null) {
    println ("Query is null");
    cLogger.log ("Query is null");
    return null;
  }

  return qGetFS.getOutput (query);
}

Boolean setFS (Order order, String fs) {
  return setFS (order.getCode (), fs);
}
Boolean setFS (String voucherCode, String fs) {
  if (!isValidInteger (voucherCode)) {
    println ("Invalid voucher code. Code should only consist of a number. '" + voucherCode + "'");
    cLogger.log ("Invalid voucher code. Code should only consist of a number. '" + voucherCode + "'");
    return null;
  }
  if (!isValidInteger (fs)) {
    println ("Invalid FS Number. FS should only consist of a number. '" + fs + "'");
    cLogger.log ("Invalid FS Number. FS should only consist of a number. '" + fs + "'");
    return null;
  }

  //println ("\nSetting and Obtaining back FS Number for '" + voucherCode + "'");
  String query = qSetFS.getQuery (
    // Lines to replace
    new String [] {
    "SET client_order_ref = ", 
    "WHERE name = "
    }, 
    // Lines to replace with
    new String [] {
      "SET client_order_ref = '" + FS_NUMBER_PREFIX + " " + fs + "'", 
      "WHERE name = '" + SALES_ORDER_PREFIX + voucherCode + "';"
    }
    );

  if (query == null) {
    println ("Query is null");
    cLogger.log ("Query is null");
    return null;
  }

  qSetFS.getOutput (query);
  return true;
}

Orders getActivePartnerOrders (String partnerName) {
  processing.data.Table oTable = getActivePartnerOrdersT (partnerName);
  if (oTable == null || !oTable.hasColumnTitles() || oTable.getRowCount () == 0) return null;

  return new Orders (oTable);
}
processing.data.Table getActivePartnerOrdersT (String partnerCode) {
  if (partnerCode == null || partnerCode.trim ().isEmpty()) {
    println ("Partner Code is Missing");
    cLogger.log ("Partner Code is Missing");
    return null;
  }

  String query = qGetPO.getQuery (
    "WHERE rp.partner_code = ", // Line to replace
    "WHERE rp.partner_code = '" + partnerCode.trim () + "'" // Replace line with
    );
    
  if (query == null) {
    println ("Query is null");
    cLogger.log ("Query is null");
    return null;
  }
  
  return qGetPO.getOutput (query);
}

Double getPartnerBalance (String partnerCode) {
  try {
    return oc.getCurrentBalance (partnerCode);
  } catch (Exception e) {
    System.err.println ("Error while fetching partner balance '" + partnerCode + "'");
    cLogger.log ("Error while fetching partner balance '" + partnerCode + "'" + e);
    return null;
  }
}
