class Person {
  private String name;
  private String position;
  private String IDnumber;
  
  private PImage photo;

  Person () {
  }

  void setName (String name) {
    this.name = name;
  }
  void setPosition (String position) {
    this.position = position;
  }
  void setIDnumber (String IDnumber) {
    this.IDnumber = IDnumber;
  }
  void setPhoto (PImage photo) {
    this.photo = photo;
  }

  String getName () {
    return name;
  }
  String getPosition () {
    return position;
  }
  String getIDnumber () {
    return IDnumber;
  }
  PImage getPhoto () {
    return photo;
  }

  void clear () {
  }
}
