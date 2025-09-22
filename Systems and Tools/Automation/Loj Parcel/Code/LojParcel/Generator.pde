int paperW = 590;
int paperH = 9999;
boolean rotatePage = false;

class Generator {
  PShape logo;

  static final String footerNote = "INVALID WITHOUT ALL REQUIRED SIGNATURES";
  static final float marginL = 15, marginR = 15;
  static final int NAME_ABBREVIATION_CHAR_LIMIT = 34;
  static final int REF_ABBREVIATION_CHAR_LIMIT = 8;
  static final int ISSUER_NAME_CHAR_LIMIT = 20;

  Generator () {
  }

  public Generator setLogo (PShape logo) {
    this.logo = logo;
    return this;
  }

  public boolean generate (ParcelParser parcel, String opPath) {
    if (parcel == null || !parcel.isValid()) return false;

    PGraphics img = createGraphics(paperW, paperH);
    img.beginDraw ();
    img.resetMatrix(); // Reset the transformation matrix to clear any accumulated transformations

    // Wrap drawing operations in pushMatrix/popMatrix to isolate transformations
    img.pushMatrix();
    if (rotatePage) {
      img.translate (img.width, img.height);
      img.rotate (-PI);
    }

    int actualH = generate (img, parcel);

    img.popMatrix();
    img.setSize (paperW, actualH);
    img.endDraw();
    img.dispose ();
    img.save (opPath);

    return true;
  }

  public int generate (PGraphics img, ParcelParser parcel) {
    float startX = marginL, startY = 148;
    float canvasW = img.width - marginL - marginR;
    float authGapH = 100;
    strokeCap (SQUARE);

    // Logo
    img.background (255);
    img.fill (0);
    img.noStroke ();
    img.rectMode (CORNER);
    img.shapeMode (CORNER);
    img.shape (logo, marginL, 0, 94.81f, 66);

    // Header Information
    img.textAlign (CENTER, TOP);
    img.fill (0);
    img.textFont (fonts.gotham.bold, 13);
    img.text ("TOP BEVERAGE INDUSTRIES AND TRADING", img.width/2, 0);
    img.textFont (fonts.gotham.medium, 19.5f);
    img.text ("DOCUMENT HANDOVER SLIP", img.width/2, 17);
    img.text (getNow (DATE_TIME_FORMAT), img.width/2, 43);

    // Destination Container
    float boxW = 95, boxH = 66;
    startX = img.width - marginR - boxW;
    img.stroke (0);
    img.strokeWeight (2);
    img.fill (255);
    img.rectMode (CORNER);
    img.rect (startX, 0, boxW, boxH);
    // Destination Content
    img.fill (0);
    img.textAlign (CENTER, CENTER);
    img.textFont (fonts.gotham.medium, 11);
    img.text ("DISPATCH TO", startX + boxW/2, 13 + textAscent ()/2);
    img.textFont (fonts.gotham.bold, 24);
    img.text ("TOP " + parcel.getStockNumber(), startX + boxW/2, 27 + textAscent ());

    // Title: Container
    float tBoxW = canvasW, tBoxH = 50;
    startY = 80;
    img.stroke (0);
    img.strokeWeight (2);
    img.fill (255);
    img.rect ((img.width - tBoxW)/2, startY, tBoxW, tBoxH);

    // Title: Labels
    img.fill (0);
    img.textAlign (LEFT, CENTER);
    img.textFont (fonts.robotoMono.bold, 20);
    img.text ("FS No.", 56, startY + tBoxH/2 - img.textDescent ()*0.5f);
    img.text ("CUSTOMER", 189, startY + tBoxH/2 - img.textDescent ()*0.5f);
    img.textAlign (RIGHT, CENTER);
    img.text (parcel.getBatchReference(), img.width - 24, startY + tBoxH/2 - img.textDescent ()*0.5f);

    //// Slip Contents
    float vGap = 34, checkboxD = 15;
    float columnsX [] = {42, 170};
    
    // Columns
    startY += tBoxH;
    float columnH = 4 + vGap*parcel.getVouchers().size () + 4;
    img.stroke (0);
    img.strokeWeight (2);
    img.line (columnsX [0], startY, columnsX [0], startY + columnH);
    img.line (columnsX [1], startY, columnsX [1], startY + columnH);
    
    // Row Content
    int sequenceCounter = 1;
    startY += 4; // 4 descent gap
    for (Voucher voucher : parcel.getVouchers ()) {
      // Checkbox
      img.stroke (0);
      img.strokeWeight (1.5f);
      img.fill (255);
      img.square (columnsX [1] - checkboxD/2, startY + vGap/2 - checkboxD/2, checkboxD);

      String reference = abbreviate (voucher.getReferenceNumber (), REF_ABBREVIATION_CHAR_LIMIT);
      String name = abbreviate (voucher.getCustomerName (), NAME_ABBREVIATION_CHAR_LIMIT);

      img.fill (0);
      img.textAlign (RIGHT, CENTER);
      img.textFont (fonts.robotoMono.medium, 20);
      img.text (sequenceCounter, columnsX [0] - 7, startY + vGap/2 - img.textDescent ()*0.5f);
      img.textAlign (LEFT, CENTER);
      img.text (reference, 56, startY + vGap/2 - img.textDescent ()*0.5f);
      img.textFont (fonts.robotoMono.medium, 18);
      img.text (name, 190, startY + vGap/2 - img.textDescent ()*0.5f);

      startY += vGap;
      sequenceCounter ++;
    }
    startY += 4; // 4 = descent gap
    // End of Slip content
    img.stroke (0);
    img.strokeWeight (2);
    img.line (marginL, startY, img.width - marginR, startY);

    // Authorizers
    String authLabels [] = {"Issuer", "Dispatcher", "Receiver"};
    for (int i = 0; i < authLabels.length; i ++) {
      startY += authGapH;
      img.stroke (0);
      img.strokeWeight (2);
      img.line (170, startY, 170 + 240, startY);
      img.line (435, startY, 435 + 140, startY);
      // Auth Labels
      img.fill (0);
      img.textAlign (RIGHT, BOTTOM);
      img.textFont (fonts.gotham.bold, 20);
      img.text (authLabels [i].toUpperCase (), 152, startY);
      img.textAlign (LEFT, TOP);
      img.textFont (fonts.robotoMono.regular, 18);
      img.text ("(name)", 170, startY);
      img.text ("(sign)", 435, startY);

      // Issuer name
      if (i != 0) continue;
      String issuerName = abbreviate(parcel.getIssuerName(), ISSUER_NAME_CHAR_LIMIT);
      img.textAlign (LEFT, BOTTOM);
      img.textFont (fonts.robotoMono.bold, 20);
      img.text (issuerName, 170, startY - 4); // 4 = Descent gap
    }
    startY += authGapH;

    // End of Authorizers
    img.stroke (0);
    img.strokeWeight (2);
    img.line (marginL, startY, img.width - marginR, startY);

    // Footer note
    startY += 4; // Footer descent gap
    img.fill (0);
    img.textAlign (CENTER, TOP);
    img.textFont (fonts.robotoMono.bold, 20);
    img.text (footerNote, img.width/2, startY);

    startY += 24;
    return int (startY);
  }
}
