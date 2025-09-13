class Shapes {
  PShape attachment;

  String path;

  Shapes (String path) {
    this.path = path;
  }

  boolean init () {
    if (!new File (path).exists ()) {
      showCMDerror (Error.MISSING_SVG_DIR);
      return false;
    }
    
    try {
      attachment = loadAndDisableStyle (path + "s/attachment.svg", 512, 394);
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
