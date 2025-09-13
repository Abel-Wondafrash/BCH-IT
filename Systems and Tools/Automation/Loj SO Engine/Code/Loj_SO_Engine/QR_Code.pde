import com.cage.zxing4p3.*;

int codeDimension = 95*4;

PImage getQRcode (String content) {
  return getQRcode (content, codeDimension, codeDimension);
}
PImage getQRcode (String content, int width, int height) {
  return qrGen.generateQRCode (content, width, height);
}

PImage getQRcodeCropped (String content) {
  return getQRcodeCropped (content, codeDimension, codeDimension);
}
PImage getQRcodeCropped (String content, int width, int height) {
  PImage code = getQRcode (content, width, height);

  int startPoint = 0;
  for (int a = 0; a < code.width; a ++) {
    if (code.get (startPoint, startPoint) != -1) break; // -1: black

    startPoint ++;
  }

  int endPoint = code.width - startPoint;
  int codeD = endPoint - startPoint - 1;

  PGraphics cropped = createGraphics (width, height);
  cropped.beginDraw ();
  cropped.background (255);
  cropped.copy (code, startPoint, startPoint, codeD, codeD, 0, 0, width, height);
  cropped.endDraw();

  return cropped;
}
