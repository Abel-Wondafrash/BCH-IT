import processing.data.Table;
import processing.data.TableRow;
import processing.data.FloatDict;
import java.util.LinkedHashMap;

String peaPath = "c:/users/abel wondafrash/desktop/pea_ledger.csv";
String cbePath = "c:/users/abel wondafrash/desktop/cbe_ledger.csv";

void setup () {
  Table pTable = loadTable(peaPath, "header");
  Table cTable = loadTable(cbePath, "header");

  LinkedHashMap<String, Entries> pEntries = getOrganizedEntries(
    pTable.getStringColumn("Vendor"), 
    pTable.getStringColumn("Credit Amt"), 
    pTable.getStringColumn("Trans No")
    );

  LinkedHashMap<String, Entries> cEntries = getOrganizedEntries(
    cTable.getStringColumn("Trans Description"), 
    cTable.getStringColumn("Debit Amt"), 
    cTable.getStringColumn("Reference")
    );

  Table report = new Table();
  report.addColumn("Status");
  report.addColumn("CBE Key");
  report.addColumn("PEA Key (Best Match)");
  report.addColumn("CBE Total");
  report.addColumn("CBE Reference");
  report.addColumn("PEA Total");
  report.addColumn("PEA Reference");
  report.addColumn("Difference");
  report.addColumn("Similarity");

  for (String cKey : cEntries.keySet()) {
    String pKey = null;
    float similarity = 1.0f;

    if (!pEntries.containsKey(cKey)) {
      FloatDict bm = getBM(cKey, pEntries.keySet());
      similarity = bm.valueArray()[0];
      pKey = bm.keyArray()[0]; // always pick best match
    } else {
      pKey = cKey;
    }

    float pTotal = pEntries.containsKey(pKey) ? pEntries.get(pKey).getTotal() : 0;
    float cTotal = cEntries.get(cKey).getTotal();
    float diff = abs(cTotal - pTotal);

    String status;
    if (!pEntries.containsKey(pKey) && similarity < 0.5f) {
      status = "Unmatched";
    } else if (diff == 0) {
      status = "Reconciled";
    } else {
      status = "Discrepancy";
    }

    // --- collect all references for this key ---
    String cRef = "";
    if (cEntries.get(cKey).size() > 0) {
      StringBuilder sb = new StringBuilder();
      for (Entry e : cEntries.get(cKey).list.values()) {
        if (sb.length() > 0) sb.append("; ");
        sb.append(e.getReference());
      }
      cRef = sb.toString();
    }

    String pRef = "";
    if (pEntries.containsKey(pKey) && pEntries.get(pKey).size() > 0) {
      StringBuilder sb = new StringBuilder();
      for (Entry e : pEntries.get(pKey).list.values()) {
        if (sb.length() > 0) sb.append("; ");
        sb.append(e.getReference());
      }
      pRef = sb.toString();
    }

    TableRow row = report.addRow();
    row.setString("Status", status);
    row.setString("CBE Key", cKey);
    row.setString("PEA Key (Best Match)", (pKey == null || pKey.equals(cKey)) ? cKey : pKey);
    row.setFloat("CBE Total", cTotal);
    row.setFloat("PEA Total", pTotal);
    row.setFloat("Difference", diff);
    row.setString("Similarity", nf(similarity * 100, 0, 1) + "%"); // similarity in %
    row.setString("CBE Reference", cRef);
    row.setString("PEA Reference", pRef);
  }
  String exportPath = System.getProperty("user.home") + "/Desktop/Recon.csv";
  saveTable(report, exportPath);
  println (millis ());
  //launch (exportPath);
  println("Saved Recon.csv");
  exit();
}
