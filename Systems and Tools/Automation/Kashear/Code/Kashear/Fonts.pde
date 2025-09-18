class Fonts {
  Arial arial;
  Tahoma tahoma;

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
      arial = new Arial (path);
      tahoma = new Tahoma (path);

      if (arial.init () && tahoma.init ()) return true;

      showCMDerror (Error.MISSING_OR_CORRUPT_FONTS);
      return false;
    } 
    catch (Exception e) {
      showCMDerror (Error.MISSING_OR_CORRUPT_FONTS);
      return false;
    }
  }
}

class Arial {
  PFont regular, italic, medium, bold;
  String path;

  Arial (String path) {
    this.path = path;
  }

  boolean init () {
    regular = createFont (path + "/f/a/a-r.ttf", 17);
    italic = createFont (path + "/f/a/a-i.ttf", 17);
    medium = createFont (path + "/f/a/a-m.ttf", 17);
    bold = createFont (path + "/f/a/a-b.ttf", 17);

    return regular != null && italic != null && medium != null && bold != null;
  }
}

class Tahoma {
  PFont regular, bold;
  String path;

  Tahoma (String path) {
    this.path = path;
  }

  boolean init () {
    regular = createFont (path + "/f/t/t-r.ttf", 17);
    bold = createFont (path + "/f/t/t-b.ttf", 17);

    return regular != null && bold != null;
  }
}
