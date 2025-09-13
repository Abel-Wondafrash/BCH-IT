static final String SITE_NAME = "TOP-1";
static final String CONNECTION_ACTIVE_MESSAGE = "<Alive>";
static final String ACTIVITY_TABLE_NAME = "activity", ACTIVITY_TABLE_HEADER = "ACT";
static final String STATES_TABLE_NAME = "states";
static final String ESTABLISH_NEW_CONNECTION = "NEW_CONNECTION";
static final String JOURNAL_MODE_WAL = "WAL";

String LOGS_TABLE_DEFINITION;
String STATES_TABLE_DEFINITION;
String ACTIVITY_TABLE_DEFINITION;

String logNodeHeadersTypes [] = {"UNIX", "STATE"};
String statesHeadersTypes [] = {"ID", "UNIX", "STATE"};
String activityHeadersTypes [] = {"UNIX", "ACT"};
String PRIMARY_KEY_HEADER = "UNIX";

int ACTIVITY_LOG_PERIOD = 5000;

void setLogTableDefinition () {
  LOGS_TABLE_DEFINITION = "(\n";
  for (String header : logNodeHeadersTypes)
    LOGS_TABLE_DEFINITION += " " + header + " INTEGER NOT NULL" + (header.equals (PRIMARY_KEY_HEADER)? " PRIMARY KEY" : "") + ",\n";
  LOGS_TABLE_DEFINITION += ",\n" + ")";
  LOGS_TABLE_DEFINITION = LOGS_TABLE_DEFINITION.replace (",\n,\n", "\n");
}
void setStatesTableDefinition () {
  STATES_TABLE_DEFINITION = "(\n" +
    " ID TEXT NOT NULL PRIMARY KEY,\n" +
    " UNIX INTEGER NOT NULL" + ",\n" +
    " STATE INTEGER NOT NULL CHECK (STATE IN (-1, 0, 1))" + "\n);";
}
void setLogActivityTableDefinition () {
  ACTIVITY_TABLE_DEFINITION = "(\n";
  for (String header : activityHeadersTypes)
    ACTIVITY_TABLE_DEFINITION += " " + header + " INTEGER NOT NULL" + (header.equals (PRIMARY_KEY_HEADER)? " PRIMARY KEY" : "") + ",\n";
  ACTIVITY_TABLE_DEFINITION += ",\n" + ")";
  ACTIVITY_TABLE_DEFINITION = ACTIVITY_TABLE_DEFINITION.replace (",\n,\n", "\n");
}
