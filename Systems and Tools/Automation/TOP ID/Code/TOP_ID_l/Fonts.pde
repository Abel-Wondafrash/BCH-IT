class Fonts {
  RobotoMono robotoMono;
  Roboto roboto;
  Gotham gotham;
  
  Fonts (String path) {
    robotoMono = new RobotoMono (path);
    roboto = new Roboto (path);
    gotham = new Gotham (path);
  }
}

class RobotoMono {
  PFont regular, medium, bold;
  
  RobotoMono (String path) {
    regular = createFont (path + "f/rm/rm-r.ttf", 17);
    medium = createFont (path + "f/rm/rm-m.ttf", 17);
    bold = createFont (path + "f/rm/rm-b.ttf", 17);
  }
}

class Roboto {
  PFont regular, medium, bold;
  
  Roboto (String path) {
    regular = createFont (path + "f/r/r-r.ttf", 17);
    medium = createFont (path + "f/r/r-m.ttf", 17);
    bold = createFont (path + "f/r/r-b.ttf", 17);
  }
}

class Gotham {
  PFont regular, medium, bold;
  
  Gotham (String path) {
    regular = createFont (path + "f/g/g-r.otf", 17);
    medium = createFont (path + "f/g/g-m.otf", 17);
    bold = createFont (path + "f/g/g-b.otf", 17);
  }
}
