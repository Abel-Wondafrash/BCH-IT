class Entry {
  String amount;
  String reference;
  
  Entry (String amount, String reference) {
    this.amount = amount;
    this.reference = reference;
  }
  
  String getReference () {
    return reference;
  }
  String getAmount () {
    return amount;
  }
}

class Entries {
  LinkedHashMap <String, Entry> list;
  float total = 0;
  
  Entries () {
    list = new LinkedHashMap <String, Entry> ();
  }
  
  Entries add (String key, Entry entry) {
    list.put (key, entry);
    String amount = entry.getAmount();
    amount = amount.replace (",", "").substring (0, amount.indexOf (".") - 1);
    total += float (amount);
    return this;
  }
  
  float getTotal () {
    return total;
  }
  int size () {
    return list.size ();
  }
  
  Entry getEntry (String key) {
    return list.get (key);
  }
}
