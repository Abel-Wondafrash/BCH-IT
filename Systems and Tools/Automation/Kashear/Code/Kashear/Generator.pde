import processing.pdf.*;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;

int a4Width = 595;    // A5 width at 72 DPI
int a4Height = 842;   // A5 height at 72 DPI
int paperW = a4Width;
int paperH = a4Height;

class Generator {
  PShape watermark;

  Generator setWatermark (PShape watermark) {
    this.watermark = watermark;
    return this;
  }

  boolean generate (String labels [], Order order, String opPath) {
    PGraphicsPDF pdf = (PGraphicsPDF) createGraphics(paperW, paperH, PDF, opPath);

    for (int i = 0; i < labels.length; i ++) {
      pdf.beginDraw ();
      pdf.resetMatrix();
      pdf.pushMatrix();

      generate (pdf, order, labels [i]);

      pdf.popMatrix();
      if (i + 1 < labels.length) pdf.nextPage ();
      pdf.endDraw();
    }

    pdf.dispose ();
    return isFileCreationComplete (opPath, FILE_CREATION_TIMEOUT);
  }

  boolean generate (PGraphicsPDF pdf, Order order, String label) {
    float LEFT_MARGIN = 24.31;
    float RIGHT_MARGIN = 30;

    pdf.background (255);
    pdf.strokeCap (SQUARE);

    /// Watermark
    pdf.fill (COL_GRAY);
    pdf.noStroke ();
    pdf.rectMode (CORNER);
    pdf.shapeMode (CORNER);
    pdf.shape (watermark, 36.1, 138.5, 511.96, 393.92);

    /// Main Company Title
    pdf.fill (0);
    pdf.textAlign (LEFT, TOP);
    pdf.textFont (fonts.arial.bold, 12.95);
    pdf.text (Company.TITLE, 34, 64);

    /// Company Tin
    pdf.textAlign (LEFT, TOP);
    pdf.textFont (fonts.tahoma.bold, 8.6);
    pdf.text ("TIN : " + Company.TIN, 112, 102.7);
    pdf.text ("VAT : " + Company.VAT, 204, 102.7);

    /// Company Information
    // Container
    pdf.stroke (0);
    pdf.noFill ();
    pdf.strokeWeight (STROKE_WEIGHT);
    pdf.rect (368.5, 20.35, 196.5, 91);
    // Contents
    pdf.fill (0);
    pdf.textAlign (LEFT, TOP);
    pdf.textFont (fonts.tahoma.bold, 8.6);
    pdf.text (Company.TITLE, 377.5, 30.8);
    pdf.text ("Tel: " + Company.TEL, 377.5, 40.8);
    pdf.text ("Fax: " + Company.FAX, 377.5, 50.8);
    pdf.text ("Web: " + Company.WEB, 377.5, 60.8);
    pdf.text ("E-Mail: " + Company.EMAIL, 377.5, 70.8);
    pdf.text ("POBox: " + Company.POBOX, 377.5, 80.8);

    /// Cash Sales Voucher Header
    pdf.fill (0);
    pdf.textAlign (RIGHT, TOP);
    pdf.textFont (fonts.arial.bold, 13);
    pdf.text ("Cash Sales Voucher", pdf.width - RIGHT_MARGIN - 3, 120.8);

    // Lines & Rects
    pdf.noFill ();
    pdf.strokeWeight (STROKE_WEIGHT);
    // Separator Line
    pdf.stroke (0);
    pdf.line (LEFT_MARGIN, 128.3, LEFT_MARGIN + 390, 128.3);
    // Order Container [LEFT]
    pdf.stroke (COL_GRAY_DARK);
    pdf.rect (LEFT_MARGIN, 138.5, 337.9, 72);
    // Order Container [RIGHT]
    float rightBoxX = pdf.width - RIGHT_MARGIN - 196.5;
    pdf.rect (rightBoxX, 138.5, 196.5, 72);

    /// Voucher Details [LEFT]
    // Labels
    pdf.fill (0);
    pdf.textAlign (LEFT, TOP);
    pdf.textFont (fonts.tahoma.regular, 8.05);
    pdf.text ("Customer", LEFT_MARGIN + 5, 142);
    pdf.text ("TIN No.", LEFT_MARGIN + 5, 155.6);
    pdf.text ("Address", LEFT_MARGIN + 5, 169.2);
    pdf.text ("FS No.", LEFT_MARGIN + 5, 182.8);
    pdf.text ("MRC No.", LEFT_MARGIN + 88, 182.8);
    pdf.text ("Remark", LEFT_MARGIN + 5, 196.4);

    // Values
    pdf.textAlign (LEFT, TOP);
    pdf.textFont (fonts.arial.regular, 8.6);
    pdf.text (order.getPartner ().getName (), LEFT_MARGIN + 48.4, 142, 280, 12);
    pdf.text (order.getPartner ().getTin (), LEFT_MARGIN + 48.4, 155.6);
    //pdf.text ("", LEFT_MARGIN + 48.4, 169.2); // Address
    pdf.text (order.getFS (), LEFT_MARGIN + 39.2, 182.8);
    pdf.text (order.getMRC (), LEFT_MARGIN + 127, 182.8);
    pdf.text (order.getName (), LEFT_MARGIN + 39.2, 196.4);

    /// Voucher Details [RIGHT]
    // Labels
    pdf.fill (0);
    pdf.textAlign (LEFT, TOP);
    pdf.textFont (fonts.tahoma.regular, 8.05);
    pdf.text ("Voucher No", rightBoxX + 5, 142);
    pdf.text ("Date", rightBoxX + 5, 155.6);
    pdf.text ("Cart", rightBoxX + 5, 169.2);
    pdf.text ("Store", rightBoxX + 5, 182.8);
    pdf.text ("Distribution", rightBoxX + 5, 196.4);
    // Values
    pdf.textFont (fonts.arial.regular, 8.6);
    pdf.text (order.getVoucherNumber (), rightBoxX + 59.6, 142);
    pdf.text (getNow (AG_DATE_TIME_PATTERN), rightBoxX + 59.6, 155.6);
    //pdf.text ("", rightBoxX + 59.6, 169.2); // Cart
    //pdf.text ("", rightBoxX + 59.6, 182.8); // Store
    pdf.text (label, rightBoxX + 59.6, 196.4);

    /// Cash Sales Voucher | Table Headers
    float headerY = 216.5, startY = headerY;
    float ROW_H = 10.2;
    // Headers
    pdf.fill (0);
    pdf.textFont (fonts.arial.bold, 8.6);
    pdf.textAlign (LEFT, CENTER);
    startY = headerY + ROW_H/2 - textDescent ()*0.2;
    pdf.text ("SN", 28.1, startY);
    pdf.text ("Item Id", 45.3, startY);
    pdf.text ("Description", 119.4, startY);
    pdf.text ("Qty", 335.71, startY);
    pdf.text ("Unit", 389.9, startY);
    pdf.text ("Unit Amount", 437, startY);
    pdf.textAlign (RIGHT, CENTER);
    pdf.text ("Total", pdf.width - RIGHT_MARGIN - 3.4, startY);

    /// Order Lines
    pdf.fill (0);
    pdf.textFont (fonts.arial.regular, 8.6);
    // Table Content
    for (int y = 0; y < order.getLines().size(); y ++) {
      OrderLine oLine = order.getLines ().get (y);
      startY = headerY + ROW_H * 1.5 + ROW_H * y - textDescent ()*0.2;
      
      pdf.textAlign (LEFT, CENTER);
      pdf.text (y + 1, AG_LINE_ITEMS_COL_Xs [0] + 3, startY);
      pdf.text (oLine.getItemWarehouseCode(), AG_LINE_ITEMS_COL_Xs [1] + 3, startY);
      pdf.text (oLine.getItemName(), AG_LINE_ITEMS_COL_Xs [2] + 5, startY);
      pdf.text (nfcBig (oLine.getItemSaleQuantity (), 3, NFC_BIG_BASE_PATTERN), AG_LINE_ITEMS_COL_Xs [3] + 3, startY);
      pdf.text (oLine.getItemSaleUOM (), AG_LINE_ITEMS_COL_Xs [4] + 3, startY);
      pdf.textAlign (RIGHT, CENTER);
      pdf.text (nfcBig (oLine.getItemPrice (), 3, NFC_BIG_BASE_PATTERN), AG_LINE_ITEMS_COL_Xs [6] - 6.4, startY);
      Double lineSubtotal = Double.parseDouble (oLine.getItemPrice ()) * Double.parseDouble (oLine.getItemSaleQuantity ());
      pdf.text (nfcBig ("" + lineSubtotal, 3, NFC_BIG_BASE_PATTERN), AG_LINE_ITEMS_COL_Xs [7] - 1.4, startY);
    }

    pdf.strokeWeight (STROKE_WEIGHT);
    pdf.stroke (COL_GRAY_DARK);
    // Table Dividers | Vertical
    for (float x : AG_LINE_ITEMS_COL_Xs) pdf.line (x, headerY, x, headerY + ROW_H* (order.getLines ().size () + 1));
    // Table Dividers | Horizontal
    for (int y = 0; y <= order.getLines ().size () + 1; y ++)
      pdf.line (LEFT_MARGIN, headerY + ROW_H * y, pdf.width - RIGHT_MARGIN, headerY + ROW_H * y);

    /// Summary Section: LEFT
    float lettersH = 11, lettersW = 306.9;
    float leadingSpace = 10;
    float lineItemsSummaryGapY = 20;
    String grandTotalLetters = numberToWords (order.getAgrandTotal());
    startY = headerY + ROW_H * (order.getLines ().size () + 1) + lineItemsSummaryGapY;
    
    processing.data.StringList gtLetters = getWrappedLines(grandTotalLetters, lettersW, fonts.arial.italic, 8.6);
    int wrappingLines = gtLetters.size ();
    float gtLmargin = 1.7, gtRmargin = 1.5;
    // Container
    pdf.noStroke ();
    pdf.fill (COL_GRAY_DARK);
    pdf.rect (LEFT_MARGIN, startY, lettersW, lettersH*wrappingLines + leadingSpace*(wrappingLines == 1? 0 : 1));
    // Value
    pdf.fill (0);
    pdf.rectMode (CORNER);
    pdf.textFont (fonts.arial.italic, 8.6);
    pdf.textLeading (10);
    pdf.textAlign (LEFT, TOP);
    pdf.text (grandTotalLetters, LEFT_MARGIN + gtLmargin, startY, lettersW, lettersH * wrappingLines + leadingSpace);

    // Payment Method
    startY += lettersH * wrappingLines + leadingSpace/2;
    pdf.fill (0);
    pdf.textAlign (LEFT, TOP);
    pdf.textFont (fonts.tahoma.bold, 8.6);
    pdf.text ("Payment Method:", LEFT_MARGIN + gtLmargin, startY);
    pdf.textFont (fonts.arial.regular, 8.6);
    pdf.text ("Cash", LEFT_MARGIN + 85, startY + textDescent ()*0.2);

    /// Summary Section: RIGHT
    // Labels
    String summaryFigures [] = {order.getAsubtotal(), order.getAvat(), order.getAgrandTotal ()};
    float figuresH = 13.8, figuresLabelsMargin = 6.5;
    startY = headerY + ROW_H * (order.getLines ().size () + 1) + lineItemsSummaryGapY;
    pdf.fill (0);
    pdf.textAlign (LEFT, BOTTOM);
    pdf.textFont (fonts.arial.bold, 8.8);
    for (int i = 0; i < 3; i ++)
      pdf.text (AG_SUMMARY_LABELS [i], AG_SUMMARY_COL_Xs [0] + figuresLabelsMargin, startY + figuresH * (1 + i));

    // Values
    pdf.fill (0);
    pdf.textAlign (RIGHT, BOTTOM);
    pdf.textFont (fonts.arial.bold, 8.8);
    // Subtotal
    pdf.text (nfcBig (order.getAsubtotal (), 3, NFC_BIG_BASE_PATTERN), AG_LINE_ITEMS_COL_Xs [6] - figuresLabelsMargin, startY + figuresH*2);

    // Summary Figures
    for (int i = 0; i < 3; i ++)
      pdf.text (nfcBig (summaryFigures [i], 3, NFC_BIG_BASE_PATTERN), AG_LINE_ITEMS_COL_Xs [7] - gtRmargin, startY + figuresH * (1 + i));
    // Line under grand total
    float gtLength = textWidth (nfcBig (order.getAgrandTotal (), 3, NFC_BIG_BASE_PATTERN));
    pdf.stroke (0);
    pdf.strokeWeight (STROKE_WEIGHT_THICK);
    pdf.line (AG_LINE_ITEMS_COL_Xs [7] - gtRmargin, startY + figuresH * (1 + 2) - STROKE_WEIGHT, 
      AG_LINE_ITEMS_COL_Xs [7] - gtLength - gtRmargin, startY + figuresH * (1 + 2) - STROKE_WEIGHT);

    // RIGHT
    pdf.stroke (COL_GRAY_DARK);
    pdf.strokeWeight (STROKE_WEIGHT);
    // Table Dividers | Vertical
    for (float x : AG_SUMMARY_COL_Xs) pdf.line (x, startY, x, startY + figuresH * 3);
    pdf.line (AG_LINE_ITEMS_COL_Xs [5], startY + figuresH, AG_LINE_ITEMS_COL_Xs [5], startY + figuresH * 2);
    // Table Dividers | Horizontal
    for (int y = 0; y <= 3; y ++)
      pdf.line (AG_SUMMARY_COL_Xs [0], startY + figuresH * y, AG_SUMMARY_COL_Xs [2], startY + figuresH * y);

    return true;
  }
}
