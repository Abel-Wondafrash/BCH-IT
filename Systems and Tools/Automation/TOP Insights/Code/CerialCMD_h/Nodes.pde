import java.util.Set;
import java.util.List;
import java.util.Arrays;

int pins [] = {2, 3, 4, 5, 7, 6, 8, 9, 10, 12, 14, 11, 15, 16, 18, 19};
String codenames [] = {"PFC", "BLW", "INP", "LBP", "PKB", "PKX", "", "PLE", "PLT", "PLB", "EYM", "LBH", "", "", "", "PWR"};

class Nodes implements Runnable {
  private Node nodes [];

  private Database db;

  Nodes (int pins [], String codenames []) {
    nodes = new Node [0];
    for (int i = 0; i < pins.length; i ++) 
      if (!codenames [i].isEmpty())
        nodes = (Node []) append (nodes, new Node (pins [i], nfs (i + 1, 2).trim () + "-" + codenames [i]));
  }
  Node [] getNodes () {
    return nodes;
  }
  Node getNode (int pin) {
    for (Node node : nodes) if (node.pin == pin) return node;
    return null;
  }

  void start () {
    new Thread (this).start ();
  }

  void setDB (Database db) {
    this.db = db;
  }

  public void update (String data, Long timestamp) {
    data = data.trim ();

    if (data.equals (CONNECTION_ACTIVE_MESSAGE)) {
      cerial.periodicalActivePolling.reset ();
      cerial.isOverdue = false;
      return;
    }
    if (data.isEmpty() || !data.contains ("<") || !data.contains (">") || !data.contains (",")) return;

    data = data.replaceAll ("[<>]", "");
    String nodeData [] = split (data, ";");

    for (String nodeDatum : nodeData) {
      String elements [] = split (nodeDatum, ",");
      if (elements.length != 2) continue;

      int pin = Integer.parseInt (elements [0]);
      int val = Integer.parseInt (elements [1]);

      // Jump invalid datum: val
      if (val != 0 && val != 1) continue;

      Node node = getNode (pin);
      // Jump invalid datum: val
      if (node == null || !node.isValid ()) continue;

      node.setValue (val, timestamp);

      // Last States
      db.update (
        STATES_TABLE_NAME, 
        new String [] {statesHeadersTypes [1], statesHeadersTypes [2]}, 
        new String [] {timestamp + "", node.getVal () + ""}, // Value, Timestamp
        "ID='" + node.getCodename () + "'");

      // Logs
      db.set (
        node.getCodename (), 
        logNodeHeadersTypes,
        new String [] {timestamp + "", node.getVal () + ""}); // Timestamp, Value
    }

    cerial.periodicalActivePolling.reset ();
    cerial.isOverdue = false;
  }

  void run () {
    while (true) {
      db.set (
        ACTIVITY_TABLE_NAME, 
        activityHeadersTypes, 
        new String [] {
        getNowEpoch () + "", 
        (cerial.isOverdue () == null)? "-1" : cerial.isOverdue? "0" : "1"}); // FT PT CT

      if (cerial.isOverdue () != null) {
        if (cerial.isOverdue () || cerial.wasOverdue ()) nircmd.setVolume (50);

        //if (cerial.isOverdue ()) sound.alert ();
        //else if (cerial.wasOverdue ()) sound.ease ();
      }

      delay (ACTIVITY_LOG_PERIOD);
    }
  }
}
