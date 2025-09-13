class SerialPort {
  private String description;
  private String deviceID;
  private String name;

  static final String _DESCRIPTION = "Description";
  static final String _DEVICE_ID = "DeviceID";
  static final String _NAME = "Name";

  SerialPort (String headers [], String details []) {
    set (headers, details);
  }

  void setDescription (String description) {
    this.description = description;
  }
  void setDeviceID (String deviceID) {
    this.deviceID = deviceID;
  }
  void setName (String name) {
    this.name = name;
  }

  void set (String headers [], String details []) {
    for (int i = 0; i < headers.length; i ++) {
      String header = headers [i];
      String detail = details [i];

      if (header.equals (_DESCRIPTION)) description = detail;
      else if (header.equals (_DEVICE_ID)) deviceID = detail;
      else if (header.equals (_NAME)) name = detail;
    }
  }

  String getDescription () {
    return description;
  }
  String getDeviceID () {
    return deviceID;
  }
  String getName () {
    return name;
  }

  String [] get () {
    return new String [] {deviceID, description, name};
  }
}
