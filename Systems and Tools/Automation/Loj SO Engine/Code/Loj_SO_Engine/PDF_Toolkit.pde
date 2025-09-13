import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.apache.pdfbox.Loader;
import java.io.File;
import processing.pdf.*;

class PDF_Toolkit {
  // Target PDF properties
  PDRectangle targetSize;
  int DPI; // DPI for rendering the source PDF page to an image
  int targetWidth, targetHeight;

  PDF_Toolkit(PDRectangle targetSize, int DPI) {
    this.targetSize = targetSize;
    this.DPI = DPI;

    // Calculate target dimensions in points (Processing/PDF standard unit)
    targetWidth = round(targetSize.getWidth());  // A5 width in points
    targetHeight = round(targetSize.getHeight()); // A5 height in points
  }

  boolean resize(String inputPath, String outputPath) {
    File inputFile = new File(inputPath);
    if (!inputFile.exists()) {
      println("PDF_Toolkit Error: Input PDF Does Not Exist");
      cLogger.log ("PDF_Toolkit Error: Input PDF Does Not Exist");
      return false;
    }

    PDDocument document = null;
    try {
      // Load the input PDF
      document = Loader.loadPDF(inputFile);
      PDFRenderer pdfRenderer = new PDFRenderer(document);

      if (document.getNumberOfPages() == 0) {
        println("PDF_Toolkit Error: Input PDF has no pages.");
        cLogger.log ("PDF_Toolkit Error: Input PDF has no pages.");
        return false;
      }

      // Create the PGraphics object for PDF output
      PGraphicsPDF pdfOutput = (PGraphicsPDF) createGraphics(targetWidth, targetHeight, PDF, outputPath);
      pdfOutput.beginDraw();

      // Process each page
      for (int pageIndex = 0; pageIndex < document.getNumberOfPages(); pageIndex++) {
        // Render the current page to a PImage
        PImage pageImage = new PImage(pdfRenderer.renderImageWithDPI(pageIndex, DPI));

        // Calculate scaling factor to fit the rendered image onto the target dimensions
        float scaleX = (float) targetWidth / pageImage.width;
        float scaleY = (float) targetHeight / pageImage.height;
        float scale = min(scaleX, scaleY); // Use the smaller scale factor to fit entirely

        // Draw the page image
        pdfOutput.background(255);
        pdfOutput.imageMode(CORNER);
        pdfOutput.image(pageImage, 0, 0, pageImage.width * scale, pageImage.height * scale);

        // Add a new page in the PDF if not the last page
        if (pageIndex < document.getNumberOfPages() - 1) {
          pdfOutput.nextPage();
        }
      }

      pdfOutput.endDraw();
      pdfOutput.dispose();
      document.close();
      return true;
    } catch (Exception e) {
      println("An error occurred:", e);
      cLogger.log ("An error occurred: " + e);
      return false;
    } finally {
      // Ensure the document is closed even if an exception occurs
      if (document != null) {
        try {
          document.close();
        } catch (Exception e) {
          println("Error closing document:", e);
          cLogger.log ("Error closing document:" + e);
        }
      }
    }
  }

  // The getImage method is no longer needed since rendering is handled in resize
}
