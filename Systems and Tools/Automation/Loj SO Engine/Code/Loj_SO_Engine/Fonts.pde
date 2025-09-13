class Fonts {
  RobotoMono robotoMono;
  Roboto roboto;
  Gotham gotham;

  String path;

  Fonts (String path) {
    this.path = path;
  }

  boolean init () {
    if (!new File (path).exists ()) {
      showCMDerror (Error.MISSING_FONTS_DIR);
      return false;
    }

    try {
      robotoMono = new RobotoMono (path);
      roboto = new Roboto (path);
      gotham = new Gotham (path);

      if (robotoMono.init () && roboto.init () && gotham.init ()) return true;

      showCMDerror (Error.MISSING_OR_CORRUPT_FONTS);
      return false;
    } 
    catch (Exception e) {
      showCMDerror (Error.MISSING_OR_CORRUPT_FONTS);
      return false;
    }
  }
}

class RobotoMono {
  PFont regular, medium, bold;
  String path;

  RobotoMono (String path) {
    this.path = path;
  }

  boolean init () {
    regular = createFont (path + "f/rm/rm-r.ttf", 17);
    medium = createFont (path + "f/rm/rm-m.ttf", 17);
    bold = createFont (path + "f/rm/rm-b.ttf", 17);

    return regular != null && medium != null && bold != null;
  }
}

class Roboto {
  PFont regular, medium, bold;
  String path;

  Roboto (String path) {
    this.path = path;
  }

  boolean init () {
    regular = createFont (path + "f/r/r-r.ttf", 17);
    medium = createFont (path + "f/r/r-m.ttf", 17);
    bold = createFont (path + "f/r/r-b.ttf", 17);

    return regular != null && medium != null && bold != null;
  }
}

class Gotham {
  PFont regular, medium, bold;
  String path;

  Gotham (String path) {
    this.path = path;
  }

  boolean init () {
    regular = createFont (path + "f/g/g-r.otf", 17);
    medium = createFont (path + "f/g/g-m.otf", 17);
    bold = createFont (path + "f/g/g-b.otf", 17);
    return regular != null && medium != null && bold != null;
  }
}
