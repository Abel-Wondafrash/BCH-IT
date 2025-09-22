import com.github.anastaciocintra.escpos.EscPos;
import com.github.anastaciocintra.escpos.EscPosConst;
import com.github.anastaciocintra.escpos.image.*;
import com.github.anastaciocintra.output.PrinterOutputStream;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.imageio.ImageIO;
import javax.print.PrintService;
import javax.print.PrintServiceLookup;

class RasterImagePrint {
  String printerName;

  RasterImagePrint setPrinterName(String printerName) {
    this.printerName = printerName;
    return this;
  }

  boolean print(File imageFile) {
    return print (imageFile.getAbsolutePath());
  }
  boolean print(String imagePath) {
    try {
      // Verify image file exists
      File imageFile = new File(imagePath);
      if (!imageFile.exists()) {
        System.err.println("Image file not found: " + imagePath);
        return false;
      }

      // Get print service
      PrintService printService = null;
      PrintService[] printServices = PrintServiceLookup.lookupPrintServices(null, null);
      for (PrintService ps : printServices) {
        if (ps.getName().equalsIgnoreCase(printerName)) {
          printService = ps;
          break;
        }
      }

      if (printService == null) {
        System.err.println("Printer '" + printerName + "' not found. Available printers:");
        for (PrintService ps : printServices) {
          System.out.println(ps.getName());
        }
        return false;
      }

      EscPos escpos = null;
      try {
        // Load image
        BufferedImage githubBufferedImage = ImageIO.read(imageFile);
        Bitonal algorithm = new BitonalThreshold(200);
        EscPosImage escposImage = new EscPosImage(new CoffeeImageImpl(githubBufferedImage), algorithm);

        RasterBitImageWrapper imageWrapper = new RasterBitImageWrapper();
        escpos = new EscPos(new PrinterOutputStream(printService));

        imageWrapper.setJustification(EscPosConst.Justification.Center);
        escpos.write(imageWrapper, escposImage);
        escpos.feed(5);
        escpos.cut(EscPos.CutMode.FULL);
      } 
      catch (IOException ex) {
        Logger.getLogger(RasterImagePrint.class.getName()).log(Level.SEVERE, null, ex);
        ex.printStackTrace();
      } 
      finally {
        if (escpos != null) {
          try {
            escpos.close();
          } 
          catch (IOException ex) {
            Logger.getLogger(RasterImagePrint.class.getName()).log(Level.SEVERE, null, ex);
          }
        }
      }
    }
    catch (Exception e) {
      println ("Error printing:", e);
    }
    
    return true;
  }
}
