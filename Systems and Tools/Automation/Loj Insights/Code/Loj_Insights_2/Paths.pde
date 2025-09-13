String getDailyPath (String date, String category) {
  Long epoch = DateUtils.toEpochMillis(date);

  return DateUtils.formatDate(epoch, "yyyy") + "/Daily/" +
    DateUtils.formatDate(epoch, "(MM) MMM/") +
    DateUtils.formatDate (epoch, "MMM_dd_yyyy") + "/" +
    DateUtils.formatDate (epoch, "MMM_dd_yyyy") + "-" + category + "-" + REPORT_SUFFIX + ".csv";
}

String getWeeklyPath (String startDate, String endDate, String category) {
  Long startEpoch = DateUtils.toEpochMillis(startDate);
  Long endEpoch = DateUtils.toEpochMillis(endDate);
  
  String weekNumber = DateUtils.getWeekNumber(startDate);
  String weekPrefix = "(W" + weekNumber + ") " +
    DateUtils.formatDate (startEpoch, "MMM_dd_yyyy") + " to " +
    DateUtils.formatDate (endEpoch, "MMM_dd_yyyy");

  return DateUtils.formatDate(startEpoch, "yyyy") + "/Weekly/" + 
    weekPrefix + "/" + weekPrefix + " - " +
    category + "-" + REPORT_SUFFIX + ".csv";
}
