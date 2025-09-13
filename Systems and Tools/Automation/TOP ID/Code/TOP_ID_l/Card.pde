class Card {
  private PImage templateFront, templateBack;
  private PImage front, back;
  private PImage maskCircle;

  private int width = 154, height = 244;
  private int photoD, QRcodeD;

  private float nameTextSize = 8;
  private float positionTextSize = 7.5;
  private float issuedDateTextSize = 5;
  private float IDnumberTextSize = 7;
  private float scale = 7;

  private String dateIssued;

  private Person person;
  
  boolean isMaskOn = true;

  Card () {
    width *= scale;
    height *= scale;

    photoD = int (width*0.43);
    QRcodeD = int (width*0.282);
    
    maskCircle = getMaskCircle (photoD, photoD);

    nameTextSize = nameTextSize * scale;
    positionTextSize = positionTextSize * scale;
    IDnumberTextSize = IDnumberTextSize * scale;
    issuedDateTextSize = issuedDateTextSize * scale;

    dateIssued = getFormattedDate (getNowEpoch ());
  }
  
  void maskPhoto () {
    maskPhoto (true);
  }
  void maskPhoto (boolean isMaskOn) {
    this.isMaskOn = isMaskOn;
  }

  void setTemplate (PImage templateFront, PImage templateBack) {
    templateFront.resize (width, height);
    templateBack.resize (width, height);

    this.templateFront = templateFront;
    this.templateBack = templateBack;
  }

  void setPerson (Person person) {
    this.person = person;
  }
  void setDateIssued (String dateIssued) {
    this.dateIssued = dateIssued;
  }

  PImage getFront () {
    return front;
  }
  PImage getBack () {
    return back;
  }
  String getQRcontent () {
    return person.getName () + "\n" + person.getPosition () + "\n" + person.getIDnumber ();
  }

  void clear () {
    person = null;
  }

  void generate () {
    front = generateFront ();
    back = generateBack ();
  }

  PImage generateFront () {
    background (255);

    // Off-screen graphics -- Front
    PGraphics pg = createGraphics (width, height);
    pg.beginDraw ();

    // Template
    pg.image (templateFront, 0, 0);

    // Photo
    pg.imageMode (CENTER);
    PImage photo = person.getPhoto ();

    // Photo: Resize
    float resizingScale = photoD*1.0/photo.width;
    int photoW = int (photo.width*resizingScale), photoH = int (photo.height*resizingScale);
    photo.resize (photoW, photoH);

    // Photo: Crop
    int photoX = int (pg.width*0.5), photoY = int (pg.height*0.54);
    photo = crop (photo, 0, 0, photoD, photoD);
    if (isMaskOn) photo.mask (maskCircle);
    pg.image (photo, photoX, photoY);

    pg.textAlign (CENTER, CENTER);
    pg.fill (0);
    // Name
    pg.textFont (fonts.gotham.bold, nameTextSize);
    pg.text (person.getName (), pg.width*0.5, pg.height*0.73);
    // Position
    pg.textFont (fonts.gotham.medium, positionTextSize);
    pg.text (person.getPosition (), pg.width*0.5, pg.height*0.78);

    pg.endDraw ();

    return pg;
  }
  PImage generateBack () {
    // Off-screen graphics -- Back
    PGraphics pg = createGraphics (width, height);
    pg.beginDraw ();

    // Template
    pg.imageMode (CORNER);
    pg.image (templateBack, 0, 0);

    // QR Code
    pg.pushMatrix ();
    pg.translate (pg.width*0.197, pg.height*0.5);
    pg.rotate (PI/2);
    pg.stroke (0);
    pg.fill (255);
    pg.strokeWeight (1);
    pg.rectMode (CENTER);
    // QR Code: Container
    pg.square (0, 0, QRcodeD);

    // QR Code: Content
    PImage QRcode = getQRcodeCropped (getQRcontent (), QRcodeD, QRcodeD);
    pg.imageMode (CENTER);
    pg.image (QRcode, 0, 0, QRcodeD*0.9, QRcodeD*0.9);
    pg.popMatrix ();

    // ID Number
    pg.pushMatrix ();
    pg.translate (pg.width*0.87, pg.height*0.133);
    pg.rotate (PI/2);
    pg.fill (255);
    pg.textAlign (LEFT, CENTER);
    pg.textFont (fonts.robotoMono.bold, IDnumberTextSize);
    pg.text (person.getIDnumber (), 0, 0);
    pg.popMatrix ();

    // Date Issued
    pg.pushMatrix ();
    pg.translate (pg.width*0.09, pg.height*0.8);
    pg.rotate (PI/2);
    pg.fill (255);
    pg.textFont (fonts.robotoMono.bold, issuedDateTextSize);
    pg.textAlign (LEFT, CENTER);
    pg.text (dateIssued.toUpperCase (), 0, 0);
    pg.popMatrix ();

    pg.endDraw ();

    return pg;
  }

  PImage getMaskCircle (int w, int h) {
    PGraphics pg = createGraphics (w, h);

    pg.beginDraw ();
    pg.background (0);
    pg.ellipseMode (CENTER);
    pg.noStroke ();
    pg.fill (255);
    pg.ellipse (pg.width*0.5, pg.height*0.5, w, h);
    pg.endDraw ();

    return pg;
  }
}
