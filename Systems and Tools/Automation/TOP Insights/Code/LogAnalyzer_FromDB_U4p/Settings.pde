class Settings {
  List <Setting> settings;
  List <String> codenames;

  Settings () {
    settings = new ArrayList <Setting> ();
    codenames = new ArrayList <String> ();

    add (new Setting ("01-PFC", "Preform Conveyor", 350, 20000));
    add (new Setting ("02-BLW", "Blow Molding", 416, 2000));
    add (new Setting ("03-INP", "Integrity Inspection", 412, 5000));
    add (new Setting ("11-EYM", "Labeling", 840, 3500)); // 340, 1500
    add (new Setting ("04-LBP", "Label Inspection", 340, 5000));
    add (new Setting ("05-PKB", "Packer Blade", 1818, 5000)
      .setCountMultiplier (6)); // 6 pieces per pack
    add (new Setting ("06-PKX", "Packer Exit", 1818, 5000)
      .setCountMultiplier (6)); // 6 pieces per pack
    add (new Setting ("09-PLT", "Palletizer", 6670, 50000) // 6670, 50000
      .setCountMultiplier (20*6) // 20 packs * 6 pieces per pack
      .setMinProcessingTime (MIN_PALLETIZER_PROCESSING_TIME)
      .setLastNode ());
  }

  void add (Setting setting) {
    settings.add (setting);
    codenames.add (setting.getCodename ());
  }

  boolean contains (String codename) {
    return codenames.contains (codename);
  }

  Setting getSetting (String codename) {
    if (!contains (codename)) return null;
    int index = codenames.indexOf (codename);
    return settings.get (index);
  }

  List <String> getCodenames () {
    return codenames;
  }
  
  int size () {
    return codenames.size ();
  }
}
class Setting {
  private int idealCycleTime = DEFAULT_CYCLE_TIME;
  private int slowCycleThreshold = DEFAULT_SLOW_CYCLE_THRESHOLD;
  private int countMultiplier = 1;
  private Integer minProcessingTime;

  private boolean isLastNode;

  private String codename, name;

  Setting (String codename, String name, int idealCycleTime, int slowCycleThreshold) {
    this.codename = codename;
    this.name = name;
    this.idealCycleTime = idealCycleTime;
    this.slowCycleThreshold = slowCycleThreshold;
  }
  Setting setLastNode () {
    isLastNode = true;
    return this;
  }
  Setting setMinProcessingTime (Integer minProcessingTime) {
    this.minProcessingTime = minProcessingTime;
    return this;
  }
  Setting setCountMultiplier (Integer countMultiplier) {
    this.countMultiplier = countMultiplier;
    return this;
  }

  int getIdealCycleTime () {
    return idealCycleTime;
  }
  int getSlowCycleThreshold () {
    return slowCycleThreshold;
  }
  int getCountMultiplier () {
    return countMultiplier;
  }
  Integer getMinProcessingTime () {
    return minProcessingTime;
  }

  boolean isLastNode () {
    return isLastNode;
  }

  String getCodename () {
    return codename;
  }
  String getName () {
    return name;
  }
}
