Querier sentQ;

String reportDir = System.getProperty("user.home") + "/Documents/Loj/Sales Report/";

void setup() {
  // yyyy-MM-dd | Hamle 2, 2016: 2024-07-09
  String date = DateUtils.formatDate (VALID_DATE_FORMAT, 0);
  //saveDailyReport ("2025-08-05"); // yyyy-MM-dd

  saveDailyReport (date); // yyyy-MM-dd
  if (DateUtils.isSunday (date)) saveWeeklyReport (date); // Ending Date: Date has to be Sunday

  exit ();
}

void saveDailyReport (String date) {
  Table sentQT = getDailyTable (date);
  if (sentQT == null) return;

  Report report = new Report (sentQT);
  if (report.isEmpty()) {
    println ("Input table is null or empty. Nothing to report for:", date);
    return;
  }

  long lastTime = millis ();
  for (String category : report.getCategoriesNames ()) {
    Table reportT = report.getTable (category);
    print ("Generating Report [" + category + "]:");
    if (reportT == null) continue;
    String path = reportDir + getDailyPath (date, category);

    saveTable (reportT, path);
    println (" Saved as:", new File (path).getName ());
  }

  println ("Done in", (millis () - lastTime)/1000.0 + "s");
}
void saveWeeklyReport (String endDate) {
  if (!DateUtils.isValidDateFormat (endDate, VALID_DATE_FORMAT)) {
    println ("Date '" + endDate + "' is invalid. Date should be in the format '" + VALID_DATE_FORMAT + "'");
    return;
  }
  String startDate = DateUtils.getWeekStartDate(endDate);
  if (startDate == null) {
    println ("Cannot generate a weekly report. '" + endDate + "' is not a Sunday (end of the week)");
    return;
  }

  long lastTime = millis ();
  Table sentQT = getBoundedTable (startDate, endDate);
  if (sentQT == null) return;

  Report report = new Report (sentQT);
  if (report.isEmpty()) {
    println ("Input table is null or empty. Nothing to report for:", startDate, "-", endDate);
    return;
  }

  for (String category : report.getCategoriesNames ()) {
    Table reportT = report.getTable (category);
    print ("Generating Report [" + category + "]:");
    if (reportT == null) continue;

    String path = reportDir + getWeeklyPath (startDate, endDate, category);
    saveTable (reportT, path);
    println (" Saved as:", new File (path).getName ());
  }

  println ("Done in", (millis () - lastTime)/1000.0 + "s");
}

Table getDailyTable (String date) {
  if (!DateUtils.isValidDateFormat (date, VALID_DATE_FORMAT)) {
    println ("Date '" + date + "' is invalid. Date should be in the format '" + VALID_DATE_FORMAT + "'");
    return null;
  }

  println ("\nGenerating Reports for '" + date + "'");
  sentQ = new Querier (dataPath ("") + "/queries/sent_quotations_by_date.txt", 
    "WHERE so.date_order::date = ", // Line to replace
    "WHERE so.date_order::date = '" + date + "'" // Replace line with
    );

  return sentQ.getOutput ();
}
Table getBoundedTable (String startDate, String endDate) {
  if (!DateUtils.isValidDateFormat (startDate, VALID_DATE_FORMAT) && DateUtils.isValidDateFormat (endDate, VALID_DATE_FORMAT)) {
    println ("Date '" + startDate + "' and/or '" + endDate + "' are/is invalid. Date should be in the format '" + VALID_DATE_FORMAT + "'");
    return null;
  }

  println ("\nGenerating Reports for '" + startDate + "' - '" + endDate + "'");
  sentQ = new Querier (dataPath ("") + "/queries/sent_quotations_by_date.txt", 
    "WHERE so.date_order::date = ", // Line to replace
    "WHERE so.date_order::date BETWEEN '" + startDate + "' AND '" + endDate + "'" // Replace line with

    );

  return sentQ.getOutput ();
}

void genDailyMass () {
  StringList dates = getDaysBetween ("2024-07-09", "2025-01-01");
  if (dates != null) {
    println ("Generating Report: ", dates.size (), "day(s)");
    for (String date : dates) {
      saveDailyReport (date);
    }
  }
}
