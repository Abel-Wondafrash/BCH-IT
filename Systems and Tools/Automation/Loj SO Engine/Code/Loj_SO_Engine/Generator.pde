import processing.pdf.*;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;

int paperW = 927;
int paperH = 1315;
int a5Width = 420;    // A5 width at 72 DPI
int a5Height = 595;   // A5 height at 72 DPI

class Generator {
  PShape logo;
  PShape stamp;

  String logoPath;

  char itemMarker = '•';

  int copyW = 225;
  int copyH = 70;

  float dash = 6, gap = 6;
  float stampScale = 1.1, signatureWidthFactor = 0.34;
  float marginL = 37, marginR = 37;

  Generator () {
  }

  void setLogo (PShape logo) {
    this.logo = logo;
  }
  void setStamp (PShape stamp) {
    this.stamp = stamp;
  }

  boolean generate (Voucher voucher, PShape signature, String copiesLabels [], String opPath) {
    if (voucher == null || voucher.hasNoOrders ()) return false;

    PGraphicsPDF pdf = (PGraphicsPDF) createGraphics(paperW, paperH, PDF, opPath);

    for (int i = 0; i < copiesLabels.length; i ++) {
      pdf.beginDraw ();

      // Reset the transformation matrix to clear any accumulated transformations
      pdf.resetMatrix();

      // Wrap drawing operations in pushMatrix/popMatrix to isolate transformations
      pdf.pushMatrix();
      if (rotatePage) {
        pdf.translate (pdf.width, pdf.height);
        pdf.rotate (-PI);
      }

      String label = copiesLabels [i];
      generate (pdf, voucher, signature, label);

      pdf.popMatrix();

      if (i + 1 < copiesLabels.length) pdf.nextPage ();
      pdf.endDraw();
    }

    pdf.dispose ();

    return true;
  }

  boolean generate (PGraphicsPDF pdf, Voucher voucher, PShape signature, String label) {
    float boxWidth = 100, boxHeight = 100, boxGap = 11; // Invoice & Stock Boxes
    float canvasWidth = pdf.width - marginL - marginR - boxWidth*2 - boxGap*2;

    // Logo
    pdf.background (255);
    pdf.fill (0);
    pdf.noStroke ();
    pdf.rectMode (CORNER);
    pdf.shapeMode (CORNER);
    pdf.shape (logo, marginL, 38, 138, 96);

    // Header Information
    float companyDetailsGapX = 10;
    float companyDetailsX = pdf.width - marginR - boxWidth - companyDetailsGapX;
    pdf.textAlign (RIGHT, TOP);
    pdf.fill (0);
    pdf.textFont (fonts.gotham.bold, 17);
    pdf.text ("TOP BEVERAGES INDUSTRIES AND TRADING", companyDetailsX, 36);
    pdf.textFont (fonts.gotham.medium, 17);
    pdf.text ("TIN: 0001470176 • TEL: +251-983-831818", companyDetailsX, 60);
    pdf.text ("info@topwaterethiopia.com", companyDetailsX, 86);
    pdf.text (getOrDash (voucher.getDateQuoted ()) + " • " + getOrDash (voucher.getTimeQuoted ()), companyDetailsX, 111);

    // QR
    String vCode = getOrDash (voucher.getCodeNumber());
    PImage qr = getQRcodeCropped (vCode);
    if (qr != null) {
      pdf.imageMode (CORNER);
      pdf.image (qr, pdf.width - marginR - boxWidth, 36, boxWidth, boxWidth);
    }

    float startX = marginL, startY = 148;
    float mainTextSize = 22;
    float h1TextSize = 20;
    float h2TextSize = 18;
    float h3TextSize = 17;
    float h4TextSize = 16;
    float h5TextSize = 11;

    // Title: Container
    pdf.stroke (0);
    pdf.strokeWeight (3);
    pdf.fill (0);
    pdf.rect (startX, startY, boxWidth, boxHeight/2);
    pdf.fill (255);
    pdf.rect (startX, startY + boxHeight/2, boxWidth, boxHeight/2);

    // Title: Label
    pdf.fill (255);
    pdf.textAlign (CENTER, TOP);
    pdf.textFont (fonts.gotham.bold, h5TextSize);
    pdf.text ("PRO-FORMA", startX + boxWidth/2, startY + 10);
    pdf.textAlign (CENTER, BOTTOM);
    pdf.textFont (fonts.gotham.bold, h3TextSize);
    pdf.text ("INVOICE", startX + boxWidth/2, startY + boxHeight/2 - 10);

    // Title: Content
    pdf.fill (0);
    pdf.textAlign (CENTER, CENTER);
    pdf.textFont (fonts.gotham.bold, h3TextSize);
    pdf.text (vCode, startX + boxWidth/2, startY + boxHeight/2 + boxHeight/4);

    startX = pdf.width - marginL - boxWidth;
    // Stock: Container
    pdf.stroke (0);
    pdf.fill (0);
    pdf.rect (startX, startY, boxWidth, boxHeight/2);
    pdf.fill (255);
    pdf.rect (startX, startY + boxHeight/2, boxWidth, boxHeight/2);

    // Stock: Label
    pdf.fill (255);
    pdf.textAlign (CENTER, TOP);
    pdf.textFont (fonts.gotham.bold, h5TextSize);
    pdf.text ("STOCK", startX + boxWidth/2, startY + 10);
    pdf.textAlign (CENTER, BOTTOM);
    pdf.textFont (fonts.gotham.bold, h3TextSize);
    pdf.text ("TOP", startX + boxWidth/2, startY + boxHeight/2 - 10);

    // Stock: Content
    pdf.fill (0);
    pdf.textAlign (CENTER, CENTER);
    pdf.textFont (fonts.gotham.bold, 38);
    pdf.text (voucher.getSiteNumber (), startX + boxWidth/2, startY + boxHeight/2 + boxHeight/4 - 3); // -# padding

    // Customer Information
    pdf.textFont (fonts.robotoMono.bold, h2TextSize);
    pdf.textLeading (24);

    String customerName = voucher.getCustomer ().getName ();
    if (customerName == null) return false;
    customerName = customerName.replace ("\n", " ").trim ();
    if (customerName.length () < MIN_CUSTOMER_NAME_LENGTH) return false;

    String customerAddress = voucher.getCustomer ().getAddress();
    customerAddress = customerAddress == null? "" : customerAddress.replace (voucher.getCustomer ().getName (), "");
    customerAddress = customerAddress.replace ("\n", " ").trim ();

    String customerTIN = voucher.getCustomer ().getTIN ();
    String customerNameAdd = customerName + (customerAddress.isEmpty()? "" : " • " + customerAddress);
    processing.data.StringList customerDetails = getWrappedLines(customerNameAdd, canvasWidth, fonts.robotoMono.bold, h2TextSize);
    if (customerTIN != null) customerDetails.append ("TIN: " + customerTIN);

    String customerDetailsOneLine = "";
    for (String details : customerDetails) customerDetailsOneLine += details + "\n";
    customerDetailsOneLine = (customerDetailsOneLine + "\n").replace ("\n\n", "");

    startX = marginL + boxWidth + boxGap;
    // Customer Information: Container
    pdf.stroke (0);
    pdf.strokeWeight (3);
    pdf.fill (255);
    pdf.rect (startX, startY, canvasWidth, boxHeight);

    pdf.fill (0);
    pdf.textAlign (CENTER, CENTER);
    pdf.rectMode (CENTER);
    pdf.text (customerDetailsOneLine.toUpperCase(), startX + canvasWidth/2, startY + boxHeight/2, canvasWidth*0.9, boxHeight);
    pdf.rectMode (CORNER);

    startY = 248;
    startY += 12.5;
    float gapX = 12;

    // Voucher Metadata: Titles
    pdf.fill (0);
    pdf.textAlign (RIGHT, TOP);
    pdf.textFont (fonts.robotoMono.medium, h2TextSize);
    pdf.text ("PAYMENT TERMS:", 191, startY);
    pdf.text ("PLATE NUMBER:", 191, startY + 33);
    pdf.text ("SALESPERSON:", 726, startY);
    pdf.text ("LOCATION:", 726, startY + 33);

    // Voucher Metadata: Values
    pdf.textAlign (LEFT, TOP);
    pdf.textFont (fonts.robotoMono.bold, h2TextSize);
    pdf.text (getOrDash (voucher.getPaymentTerm()).toUpperCase (), 191 + gapX, startY);
    pdf.text (abbreviate (getOrDash (voucher.getPlateNumber()), PLATE_NUMBER_CUTOFF_LENGTH), 191 + gapX, startY + 33);
    pdf.text (abbreviate (getOrDash (voucher.getSalesperson()), 14).toUpperCase (), 726 + gapX, startY);
    pdf.text (abbreviate (getOrDash (voucher.getCustomer ().getLocation ()).toUpperCase(), 14), 726 + gapX, startY + 33);

    startY += 72;
    // Order Details: Container
    pdf.stroke (0);
    pdf.strokeWeight (3);
    pdf.fill (255);
    float separatorH = 50;
    pdf.rect (marginL, startY, pdf.width - marginL - marginR, separatorH);

    // Order Details: Title
    pdf.fill (0);
    pdf.textAlign (CENTER, CENTER);
    pdf.textFont (fonts.gotham.bold, mainTextSize);
    pdf.text ("ORDER DETAILS", pdf.width/2, startY + separatorH/2);

    startY += separatorH + 18; // ... + gap

    List <Voucher.Order> orders = voucher.getOrders ();
    String longestPrice = "";
    String longestSalesMeasure = "";
    String prices [] = new String [0];
    String salesMeasure [] = new String [0];
    String UoMs [] = new String [0];
    // All Right Side Prices
    for (Voucher.Order order : voucher.getOrders ()) {
      prices = append (prices, "" + nfcBig (float (order.getUnitPrice ()), 2));
      prices = append (prices, "" + nfcBig (float (order.getTotalAmount ()), 2));
      UoMs = append (UoMs, "" + getOrDash (order.getUoM ()).toUpperCase ());
      salesMeasure = append (salesMeasure, nfc (order.getPack ()));
    }
    prices = append (prices, nfcBig (voucher.getVoucherSummary ().getGrandTotal (), 2));
    // String length () comparison
    for (String price : prices)
      longestPrice = price.length () > longestPrice.length ()? price : longestPrice;
    for (String salesUoM : salesMeasure)
      longestSalesMeasure = salesUoM.length () > longestSalesMeasure.length ()? salesUoM : longestSalesMeasure;

    pdf.textFont (fonts.robotoMono.bold, h2TextSize);
    float longestPriceWidth = pdf.textWidth (longestPrice);

    pdf.textFont (fonts.gotham.bold, 30);
    float longestSalesMeasureWidth = pdf.textWidth (longestSalesMeasure + "##");
    longestSalesMeasureWidth = max (longestSalesMeasureWidth, longestPriceWidth + 8); // 8 gap TITLE: ###.##

    // Order Details: Titles
    pdf.fill (0);
    pdf.textFont (fonts.robotoMono.medium, 16);
    pdf.textAlign (LEFT, TOP);
    pdf.text ("DESCRIPTION", marginL, startY);
    pdf.textAlign (RIGHT, TOP);
    pdf.text ("QTY (" + UoMs [0].toLowerCase () + ")", 557, startY);
    pdf.text ("PRICE (Br)", 709, startY);
    pdf.text ("S.TOTAL (Br)", pdf.width - marginR, startY);

    startY += 38;

    // Order Details: Footer
    pdf.stroke (0);
    pdf.strokeWeight (3);
    pdf.strokeCap (SQUARE);
    pdf.line (marginL, startY, pdf.width - marginR, startY);

    // Draw Orders
    int orderCounter = 1;
    float packWidth = 100, packHeight = 31;
    for (Voucher.Order order : voucher.getOrders ()) {
      // Order Details: Values
      startY += 15;

      // Item Description
      pdf.fill (0);
      pdf.textFont (fonts.roboto.bold, h4TextSize);
      pdf.textAlign (LEFT, TOP);
      pdf.text (itemMarker + " " + getOrDash (order.getItemName()), marginL, startY);

      pdf.fill (0);
      pdf.noStroke ();
      //pdf.strokeWeight (3);
      //packWidth = textWidth (nfc (order.getPack ()) + " ");
      pdf.rect (557 - packWidth, startY - 6, packWidth, packHeight);

      pdf.fill (255);
      pdf.textFont (fonts.gotham.bold, h2TextSize);
      pdf.textAlign (CENTER, CENTER);
      pdf.text (nfc (order.getPack ()), 557 - packWidth/2, startY - 6 + packHeight/2 - textDescent ()*0.4);

      //pdf.fill (0);
      //pdf.textFont (fonts.robotoMono.bold, h4TextSize);
      //pdf.textAlign (RIGHT, TOP);
      //pdf.text (nfc (order.getQuantity ()), 565, startY);

      pdf.fill (0);
      pdf.textFont (fonts.robotoMono.bold, h4TextSize);
      pdf.textAlign (RIGHT, TOP);
      float uPrice = Float.parseFloat (order.getUnitPrice());
      float price = uPrice * order.getQuantity () / order.getPack ();
      pdf.text (nfcBig (price, 2), 709, startY);
      pdf.text (nfcBig (float(order.getSubtotal()), 2), pdf.width - marginR, startY);

      // Orders Separator
      startY += 32;
      boolean hasNextOrder = orderCounter ++ < orders.size ();
      pdf.stroke (0);
      pdf.strokeCap (SQUARE);
      pdf.strokeWeight (hasNextOrder? 0.75 : 3);
      pdf.line (marginL, startY, pdf.width - marginR, startY);
    }

    startY += 15;

    // Order Details Summary: Titles RIGHT
    float yGap = 17 + 11;
    float x = pdf.width - marginR - longestPriceWidth - 8;
    boolean noTax = voucher.getVoucherSummary ().getTaxTotal () == 0;
    processing.data.StringList sDetails = new processing.data.StringList ();
    sDetails.append ("SUBTOTAL");
    if (!noTax) sDetails.append ("VAT 15%");
    sDetails.append ("TOTAL");

    pdf.textAlign (RIGHT, TOP);
    pdf.textFont (fonts.robotoMono.medium, h2TextSize);
    for (int i = 0; i < sDetails.size (); i ++)
      pdf.text (sDetails.get (i) + ":", 709, startY + yGap*i);

    // Order Details Summary: values RIGHT
    x = pdf.width - marginR;
    FloatList sValues = new FloatList ();
    sValues.append (voucher.getVoucherSummary ().getSubtotal());
    if (!noTax) sValues.append (voucher.getVoucherSummary ().getTaxTotal ());
    sValues.append (voucher.getVoucherSummary ().getGrandTotal ());
    pdf.textFont (fonts.robotoMono.bold, h2TextSize);
    for (int i = 0; i < sDetails.size (); i ++)
      pdf.text (nfcBig (sValues.get (i), 2), x, startY + yGap*i);

    // Order Details Summary: Footer Separator
    float separatorY = startY + yGap*sDetails.size () + 13;
    pdf.strokeCap (SQUARE);
    pdf.strokeWeight (3);
    pdf.stroke (0);
    pdf.line (610, separatorY, pdf.width - marginR, separatorY);
    separatorY = pdf.height - 36 - 235;
    pdf.line (marginL, separatorY, pdf.width - marginR, separatorY);

    startY = separatorY + 20;
    float wSize = 2.04;
    float wGap = wSize*2.9;
    float wWidth = pdf.width - marginL - marginR, wHeight = stamp.height*stampScale - 20*3;
    int rows = int (wHeight / (wGap + wSize));
    int cols = int (wWidth / (wGap + wSize));

    // Authentication: Watermark
    pdf.noStroke ();
    pdf.rectMode (CORNER);
    pdf.fill (0, 255*0.5);
    for (int r = 0; r <= rows; r ++)
      for (int c = 0; c <= cols; c ++)
        pdf.rect (marginL + c*wSize + c*wGap, startY + r*wSize + r*wGap, wSize, wSize);

    if (label != null) {
      // Copies Label: Container
      pdf.stroke (0);
      pdf.fill (255);
      pdf.rect (pdf.width - marginR - 149, separatorY, 150, 50);

      // Copies Label: Value
      pdf.fill (0);
      pdf.textAlign (CENTER, CENTER);
      pdf.textFont (fonts.gotham.bold, mainTextSize);
      pdf.text (label.toUpperCase(), pdf.width - marginR - 149/2, separatorY + 50/2);
    }

    float stampX = marginL + wWidth/2;
    float stampY = startY + wHeight/2;
    // Authentication: Stamp
    pdf.fill (0);
    pdf.noStroke ();
    pdf.shapeMode (CENTER);
    pdf.shape (stamp, stampX, stampY, stamp.width*stampScale, stamp.height*stampScale);

    float signWmax = wWidth * signatureWidthFactor;
    float signHmax = wHeight;
    boolean isLandscape = signature.width > signature.height;
    float ratio = isLandscape? signWmax/signature.width : signHmax/signature.height;
    float signW = isLandscape? signWmax : signature.width*ratio;
    float signH = isLandscape? signature.height * ratio : signHmax;
    float signX = marginL + signW / 2;
    float signY = stampY;
    // Authentication: Signature
    pdf.fill (0);
    pdf.noStroke ();
    pdf.shapeMode (CENTER);
    pdf.shape (signature, signX, signY, signW, signH);

    startY = separatorY + wHeight + 20;

    // Voucher Footer
    startY += 21.8;
    pdf.stroke (0);
    pdf.strokeWeight (3);
    pdf.line (marginL, startY, pdf.width - marginR, startY);
    pdf.line (marginL, startY + 50, pdf.width - marginR, startY + 50);

    startY += 25;
    String footerTitle = "Outskirts of Addis Ababa • Geferesa Nono, Tatek Industry Zone • Oromia, Ethiopia";
    pdf.textAlign (CENTER, CENTER);
    pdf.textFont (fonts.gotham.bold, 16.5);
    pdf.text (footerTitle.toUpperCase (), marginL + pdf.width/2 - marginR, startY - pdf.textDescent ()/2);
    startY += 25;

    return true;
  }
}
