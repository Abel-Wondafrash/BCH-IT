import javax.print.*;
import javax.print.attribute.*;
import javax.print.attribute.standard.*;
import java.io.File;
import java.io.IOException;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.printing.PDFPageable;
import org.apache.pdfbox.Loader;

class Printer {
  private static final int MAX_RETRIES = 3; // Maximum retry attempts for print failures
  private static final long BETWEEN_PRINT_JOB_DELAY = 1000; // Delay after successful print in milliseconds
  private static final long RETRY_DELAY_MS = 2000; // Delay between retries in milliseconds

  String selectedPrinterName;

  Printer(String printerName) {
    this.selectedPrinterName = printerName;
  }

  boolean showVerbose() {
    // List out printers and indicate selected or fallback to default
    PrintService[] printServices = PrintServiceLookup.lookupPrintServices(null, null);
    if (printServices == null || printServices.length == 0) {
      println("Error: No printers found on the system");
      return false;
    }

    PrintService selectedPrinter = null;
    PrintService defaultPrinter = PrintServiceLookup.lookupDefaultPrintService();
    println("Available Printers:");
    for (PrintService service : printServices) {
      print("\t" + service.getName());
      if (service.getName().trim().equalsIgnoreCase(selectedPrinterName.trim())) {
        selectedPrinter = service;
        print(" <<<< SELECTED");
      }
      if (defaultPrinter != null && service.equals(defaultPrinter)) {
        print(" <<<< DEFAULT");
      }
      println();
    }

    // If selected printer not found, check and mark the default
    if (selectedPrinter == null) {
      println("Selected printer '" + selectedPrinterName + "' is not found. Checking default printer...");
      if (defaultPrinter != null) {
        println("Falling back to default printer:");
        for (PrintService service : printServices) {
          print("\t" + service.getName());
          if (service.equals(defaultPrinter)) {
            print(" <<<< DEFAULT (FALLBACK)");
          }
          println();
        }
        return false; // Selected not found, using default
      } else {
        println("No default printer available either. Please install printer or provide correct name in Loj's config");
        return false; // No selected or default printer
      }
    }

    return true; // Selected printer found
  }

  String printPDF(String path, int copies, String jobName) {
    //if (true) return null;
    PDDocument document = null;
    boolean verbose = true; // Enable verbose logging by default

    try {
      File pdfFile = new File(path);
      if (!pdfFile.exists()) {
        println("Error: PDF file not found at " + path);
        return null;
      }
      document = Loader.loadPDF(pdfFile);
      float widthPx = document.getPage(0).getMediaBox().getWidth();
      float heightPx = document.getPage(0).getMediaBox().getHeight();
      //println ("Number of Pages:", document.getNumberOfPages());
      print ("Print Job: | ");
      if (document.getNumberOfPages() == 0) return "No pages to print";

      // Get all available print services
      PrintService[] printServices = PrintServiceLookup.lookupPrintServices(null, null);
      if (printServices == null || printServices.length == 0) {
        println("Error: No printers found on the system");
        document.close();
        return null;
      }

      // Try to find the specified printer by name
      PrintService printer = null;
      for (PrintService service : printServices) {
        if (service.getName().trim().equalsIgnoreCase(selectedPrinterName.trim())) {
          printer = service;
          break;
        }
      }

      // If specified printer not found, fall back to default printer
      if (printer == null) {
        printer = PrintServiceLookup.lookupDefaultPrintService();
        if (printer == null) {
          println("Error: Specified printer '" + selectedPrinterName + "' not found, and no default printer available");
          document.close();
          return null;
        }
        println("Warning: Printer '" + selectedPrinterName + "' not found. Falling back to default printer: " + printer.getName());
      } else {
        // Check if the printer is the default to determine logging verbosity
        PrintService defaultPrinter = PrintServiceLookup.lookupDefaultPrintService();
        if (printer.equals(defaultPrinter)) {
          verbose = false; // Suppress verbose logging if printer is found and default
        }
      }

      // Log printer details only if verbose
      if (verbose) {
        println("Selected printer name: '" + selectedPrinterName + "'");
        println("\tAvailable printers:");
        for (PrintService service : printServices) {
          println("\t - '" + service.getName() + "'");
        }
      }

      // Set as default printer if not already default (log only if verbose)
      PrintService defaultPrinter = PrintServiceLookup.lookupDefaultPrintService();
      if (!printer.equals(defaultPrinter)) {
        setDefaultPrinter(printer.getName(), verbose);
      }

      // Check printer state and attributes (log only if verbose)
      PrinterState state = (PrinterState) printer.getAttribute(PrinterState.class);
      PrinterIsAcceptingJobs acceptingJobs = (PrinterIsAcceptingJobs) printer.getAttribute(PrinterIsAcceptingJobs.class);
      QueuedJobCount jobCount = (QueuedJobCount) printer.getAttribute(QueuedJobCount.class);
      if (verbose) {
        println("Printer state: " + state + ", Accepting jobs: " + (acceptingJobs != null ? acceptingJobs : "Unknown") + 
          ", Jobs in queue: " + (jobCount != null ? jobCount.getValue() : "Unknown"));
      }

      if (state == PrinterState.STOPPED || state == PrinterState.UNKNOWN) {
        println("Error: Printer '" + printer.getName() + "' is stopped or in unknown state: " + state);
        document.close();
        return null;
      }
      if (acceptingJobs == PrinterIsAcceptingJobs.NOT_ACCEPTING_JOBS) {
        println("Error: Printer '" + printer.getName() + "' is not accepting jobs");
        document.close();
        return null;
      }

      // Retry loop for printing
      for (int attempt = 1; attempt <= MAX_RETRIES; attempt++) {
        try {
          // Create and configure the print job
          DocPrintJob printJob = printer.createPrintJob();
          PrintRequestAttributeSet attributes = new HashPrintRequestAttributeSet();
          attributes.add(new Copies(copies));
          attributes.add(new JobName("Kashear Print - " + jobName, null));

          PDFPageable pageable = new PDFPageable(document);
          printJob.print(new SimpleDoc(pageable, DocFlavor.SERVICE_FORMATTED.PAGEABLE, null), attributes);

          // Delay to avoid overwhelming the printer
          Thread.sleep(BETWEEN_PRINT_JOB_DELAY);

          // Re-check if the printer is the default after successful print
          defaultPrinter = PrintServiceLookup.lookupDefaultPrintService();
          if (!printer.equals(defaultPrinter)) {
            setDefaultPrinter(printer.getName(), verbose);
          }

          document.close();
          document = null;
          println(jobName, "PDF queued successfully to:", printer.getName());
          return printer.getName();
        } 
        catch (PrintException e) {
          if (attempt < MAX_RETRIES && e.getMessage().contains("Printer is not accepting job")) {
            if (verbose) {
              println("Printer not accepting job for " + jobName + ", retrying (" + attempt + "/" + MAX_RETRIES + ")...");
            }
            Thread.sleep(RETRY_DELAY_MS);
            // Re-check printer availability after delay
            printServices = PrintServiceLookup.lookupPrintServices(null, null);
            printer = null;
            for (PrintService service : printServices) {
              if (service.getName().trim().equalsIgnoreCase(selectedPrinterName.trim())) {
                printer = service;
                // If found during retry, re-evaluate verbosity
                defaultPrinter = PrintServiceLookup.lookupDefaultPrintService();
                if (printer.equals(defaultPrinter)) {
                  verbose = false; // Suppress further logs if now default
                } else {
                  verbose = true; // Enable verbose for default setting attempts
                  setDefaultPrinter(printer.getName(), verbose);
                }
                break;
              }
            }
            if (printer == null) {
              printer = PrintServiceLookup.lookupDefaultPrintService();
              if (printer == null) {
                println("Error: Printer not found during retry, and no default printer available");
                document.close();
                document = null;
                return null;
              }
              verbose = true; // Enable verbose for fallback
            }
            continue;
          }
          println("Error printing PDF for " + jobName + ": " + e.getMessage());
          e.printStackTrace();
          document.close();
          document = null;
          return null;
        }
      }

      // If retries are exhausted
      println("Error: Failed to print " + jobName + " after " + MAX_RETRIES + " attempts");
      document.close();
      document = null;
      return null;
    } 
    catch (Exception e) {
      println("Error printing PDF for " + jobName + ": " + e.getMessage());
      e.printStackTrace();
      if (document != null) {
        try {
          document.close();
        } 
        catch (Exception ignored) {
        }
      }
      return null;
    }
  }

  // Method to set the default printer (Windows-specific) with optional logging
  private void setDefaultPrinter(String printerName, boolean verbose) {
    try {
      // Escape backslashes for the command
      String escapedPrinterName = printerName.replace("\\", "\\\\");
      String command = "rundll32 printui.dll,PrintUIEntry /y /n \"" + escapedPrinterName + "\"";
      Process process = Runtime.getRuntime().exec(command);
      int exitCode = process.waitFor();
      if (verbose) {
        if (exitCode == 0) {
          println("\tSuccessfully set '" + printerName + "' as the default printer");
        } else {
          println("Warning: Failed to set '" + printerName + "' as the default printer (exit code: " + exitCode + ")");
        }
      }
    } 
    catch (IOException e) {
      if (verbose) {
        println("Error setting default printer (IOException) '" + printerName + "': " + e.getMessage());
        e.printStackTrace();
      }
    } 
    catch (InterruptedException e) {
      if (verbose) {
        println("Error setting default printer (InterruptedException) '" + printerName + "': " + e.getMessage());
        e.printStackTrace();
      }
    }
  }
}
