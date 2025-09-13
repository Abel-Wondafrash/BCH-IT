class Shapes {
  PShape logoFull;
  PShape logoMinimal;
  PShape stamp;

  String path;

  Shapes (String path) {
    this.path = path;
  }

  boolean init () {
    if (!new File (path).exists ()) {
      showCMDerror (Error.MISSING_OR_CORRUPT_SVGS);
      return false;
    }
    
    try {
      logoFull = loadAndDisableStyle (path + "s/top_logo_full.svg", 138, 96);
      logoMinimal = loadAndDisableStyle (path + "s/TOP-logo-Minimal.svg", 69, 83);
      stamp = loadAndDisableStyle (path + "s/TOP-stamp.svg", 206, 206);
      return true;
    } 
    catch (Exception e) {
      showCMDerror (Error.MISSING_OR_CORRUPT_SVGS);
      return false;
    }
  }

  PShape loadAndDisableStyle (String path) {
    PShape shape = loadShape (path);
    shape.disableStyle();
    return shape;
  }
  PShape loadAndDisableStyle (String path, int width, int height) {
    PShape shape = loadShape (path);
    shape.disableStyle();
    shape.width = width;
    shape.height = height;
    return shape;
  }
}
