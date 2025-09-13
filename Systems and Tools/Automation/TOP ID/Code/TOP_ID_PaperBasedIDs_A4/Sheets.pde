import processing.pdf.*;

void createPDF (PImage front, PImage back, String path) {
  PGraphicsPDF pdf = (PGraphicsPDF) createGraphics (PAGE_WIDTH, PAGE_HEIGHT, PDF, path);
  
  println ("Canvas:", PAGE_WIDTH, PAGE_HEIGHT);
  println ("Images:", front.width, front.height, back.width, back.height);
  pdf.beginDraw();
  
  // First Page
  pdf.background (#FFFFFF);
  pdf.image (front, 0, 0);
  pdf.nextPage();
  
  // Second Page
  pdf.background (#FFFFFF);
  pdf.image (back, 0, 0);
  
  pdf.dispose ();
  pdf.endDraw ();
}
