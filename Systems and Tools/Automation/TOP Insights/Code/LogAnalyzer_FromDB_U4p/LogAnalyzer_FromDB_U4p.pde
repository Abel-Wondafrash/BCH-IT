import java.util.Arrays;

Database db;
Nodes nodes;
Runner runner;

String dbDir = System.getProperty ("user.home") + "/Documents/_Amber Flashes/Logs";
String site = "TOP-1";

public void setup () {
  size (380, 180);
  background (0);

  loadJDBCdriver ();
  runner = new Runner ();

  println ("Started");
}
public void draw () {
}
