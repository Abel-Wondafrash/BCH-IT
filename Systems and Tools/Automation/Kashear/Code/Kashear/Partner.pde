class Partner {
  private String code;
  private String tin;
  private String name;
  
  Partner (String code, String tin, String name) {
    if (code == null || tin == null || name == null) return;
    if (code.trim ().isEmpty() || tin.trim().isEmpty() || name.trim().isEmpty()) return;
    
    this.code = code.trim ();
    this.tin = tin.trim ();
    this.name = name.trim ();
  }
  
  boolean isValid () {
    return code != null && tin != null && name != null;
  }
  
  // Getters
  String getCode () {
    return code;
  }
  String getTin () {
    return tin;
  }
  String getName () {
    return name;
  }
}
