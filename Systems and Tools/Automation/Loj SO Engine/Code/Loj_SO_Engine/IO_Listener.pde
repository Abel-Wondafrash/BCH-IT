class VoucherProcessor implements Runnable {
  private int checkinPeriod = 1000;
  private File listener, archive, temp, dest;
  private Long lastModified;
  private String archivePath, tempPath;
  private LinkedHashMap<String, Voucher> queue;
  private LinkedHashMap <String, String []> copiesTypes;
  private StringDict imgQueue;
  private volatile boolean running = true;

  VoucherProcessor(String xmlListenPath, String archivePath, int checkinPeriod) {
    this.checkinPeriod = checkinPeriod;

    // Initialize directories
    this.listener = new File(xmlListenPath);
    if (!listener.exists()) {
      println("Error: Listener directory does not exist: " + xmlListenPath);
      cLogger.log ("Error: Listener directory does not exist: " + xmlListenPath);
      return;
    }

    copiesTypes = new LinkedHashMap <String, String []> ();
    for (int i = 0; i < COPIES_TYPES.length; i ++)
      copiesTypes.put (COPIES_TYPES [i], COPIES_LABELS [i]);

    queue = new LinkedHashMap<String, Voucher>();
    archive = new File(archivePath);
    this.archivePath = archive.getAbsolutePath() + "/";

    tempPath = listener.getAbsolutePath() + "/temp/";
    temp = new File(tempPath);
    imgQueue = new StringDict();

    lastModified = listener.lastModified();
    new Thread(this).start();
  }

  void checkAndQueue() {
    try {
      // Check if directory has been modified
      if (lastModified == null) lastModified = listener.lastModified();
      else if (lastModified == listener.lastModified()) return;

      // Queue new vouchers
      File[] files = listener.listFiles();
      if (files != null) {
        for (File file : files) {
          if (!file.isFile() || !file.getName().toLowerCase().endsWith(".xml")) continue;

          //boolean generated = isFileCreationComplete(file.getAbsolutePath (), FILE_CREATION_TIMEOUT);
          //if (!generated) {
          //  println("Warning: Voucher is either invalid or timeout in waiting for its complete creation: " + file.getName ());
          //  continue;
          //}

          try {
            String path = file.getAbsolutePath();
            Voucher voucher = new Voucher().get(path);
            if (voucher == null) {
              println("Warning: Failed to create voucher for file: " + file.getName());
              cLogger.log("Warning: Failed to create voucher for file: " + file.getName());
              continue;
            }
            String voucherCode = voucher.getCode();
            if (voucherCode == null) {
              println("Warning: Voucher has no code for file: " + file.getName());
              cLogger.log ("Warning: Voucher has no code for file: " + file.getName());
              continue;
            }
            if (queue.containsKey(voucherCode)) {
              println("Warning: Duplicate voucher code skipped: " + voucherCode);
              cLogger.log ("Warning: Duplicate voucher code skipped: " + voucherCode);
              continue;
            }
            queue.put(voucherCode, voucher);
            //println("Queued voucher: " + voucherCode);
          } 
          catch (Exception e) {
            println("Error queuing file: " + file.getName() + ", " + e.getMessage());
            cLogger.log ("Error queuing file: " + file.getName() + ", " + e.getMessage());
          }
        }
      }

      // Move files to archive (keeping this as in original XML_Listener)
      //files = listener.listFiles();
      if (files == null) return;

      for (File file : files) {
        if (!file.isFile()) continue;
        
        try {
          String fromPath = file.getAbsolutePath();
          String toPath = archivePath + getDateToday("yyyy/MMM/MMM_dd_yyyy/") + file.getName();
          if (!archive.exists()) archive.mkdirs();
          moveFile(fromPath, toPath);
          //println("Archived file: " + file.getName());
        } 
        catch (Exception e) {
          println("Error archiving file: " + file.getName() + ", " + e.getMessage());
          cLogger.log ("Error archiving file: " + file.getName() + ", " + e.getMessage());
        }
      }

      lastModified = listener.lastModified();
    }
    catch (Exception e) {
      println("Error in checkAndQueue: " + e.getMessage());
      cLogger.log ("Error in checkAndQueue: " + e.getMessage());
    }
  }
  
  void processQueue() {
    try {
      if (queue.isEmpty()) return;

      StringDict[] logContents = new StringDict[0];

      // Use for-each loop like original code
      for (String voucherCode : queue.keySet()) {
        Voucher voucher = queue.get(voucherCode);
        try {
          String issuer = voucher.getActivity().getIssuerName();
          if (issuer == null) {
            println("Warning: No issuer for voucher: " + voucherCode);
            cLogger.log ("Warning: No issuer for voucher: " + voucherCode);
            continue;
          }

          PShape signature = issuers.getSignature(issuer);
          if (signature == null) {
            println("Warning: No signature for issuer: " + issuer + voucherCode);
            cLogger.log ("Warning: No signature for issuer: " + issuer + voucherCode);
            continue;
          }

          String copyType = voucher.getCopyType ();
          if (copyType == null || !copiesTypes.containsKey (copyType)) {
            println("Warning: No copy type for: " + voucherCode);
            cLogger.log ("Warning: No copy type for: " + voucherCode);
            continue;
          }

          int printedCopies = 0;
          String printerName = null;

          String labels [] = copiesTypes.get (copyType);
          String genPath = tempPath + getDateToday("yyyy/MMM/MMM_dd_yyyy/") +
            voucherCode + "-" + RandomStringUtils.randomAlphanumeric(VOUCHER_RANDOM_CODE_LENGTH) + ".pdf";
          try {
            if (!temp.exists()) temp.mkdirs();
            generator.generate(voucher, signature, labels, genPath);

            boolean generated = isFileCreationComplete(genPath, FILE_CREATION_TIMEOUT);
            if (!generated) {
              println("Warning: Failed to generate PDF for voucher: " + voucherCode);
              cLogger.log ("Warning: Failed to generate PDF for voucher: " + voucherCode);
              continue;
            }

            String resizedPath = tempPath + getDateToday("yyyy/MMM/MMM_dd_yyyy/") +
              voucherCode + "-" + RandomStringUtils.randomAlphanumeric(VOUCHER_RANDOM_CODE_LENGTH) + "_resized.pdf";
            pdf_toolkit.resize(genPath, resizedPath);
            boolean resized = isFileCreationComplete(resizedPath, FILE_CREATION_TIMEOUT);
            if (!resized) {
              println("Warning: Failed to resize PDF for voucher: " + voucherCode);
              cLogger.log ("Warning: Failed to resize PDF for voucher: " + voucherCode);
              continue;
            }

            //new File(genPath).delete();
            printerName = printer.printPDF(resizedPath, 1, voucher.getCode());
            printedCopies += printerName != null ? 1 : 0;
            if (printerName == null) {
              println("Warning: Failed to print voucher: " + voucherCode);
              cLogger.log ("Warning: Failed to print voucher: " + voucherCode);
            }
            new File(resizedPath).delete();
          } 
          catch (Exception e) {
            println("Error processing PDF for voucher: " + voucherCode + ", " + e.getMessage());
            cLogger.log ("Error processing PDF for voucher: " + voucherCode + ", " + e.getMessage());
          }

          // Log voucher details
          try {
            for (Voucher.Order order : voucher.getOrders()) {
              StringDict logContent = new StringDict();
              logContent.set("print_date_time", getDateToday("HH:mm:ss - MMM d, yyyy"));
              logContent.set("order_date_time", getOrDash(voucher.getDateQuoted()) + " • " + getOrDash(voucher.getTimeQuoted()));
              logContent.set("voucher_code", getOrDash(voucher.getCode()).toUpperCase());
              logContent.set("voucher_reference", getOrDash(voucher.getReference()).toUpperCase());
              logContent.set("print_copy_type", voucher.getCopyType() + "");
              logContent.set("printed_copies", printedCopies + "");
              logContent.set("printer", printerName == null? "-" : printerName);
              logContent.set("salesperson", getOrDash(voucher.getSalesperson()).toUpperCase());
              logContent.set("device_name", getOrDash(voucher.getActivity().getDeviceName()).toUpperCase());
              logContent.set("user_name", getOrDash(voucher.getActivity().getIssuerName()).toUpperCase());
              logContent.set("plate_number", getOrDash(voucher.getPlateNumber()).toUpperCase());
              logContent.set("stock_site", getOrDash(voucher.getSite()).toUpperCase());
              logContent.set("payment_term", getOrDash(voucher.getPaymentTerm().toUpperCase()));
              logContent.set("par_name", getOrDash(voucher.getCustomer().getName()).toUpperCase());
              logContent.set("par_code", getOrDash(voucher.getCustomer().getCode()).toUpperCase());
              logContent.set("par_adress", getOrDash(voucher.getCustomer().getAddress()).toUpperCase());
              logContent.set("par_tin", getOrDash(voucher.getCustomer().getTIN()).toUpperCase());
              logContent.set("item_name", getOrDash(order.getItemName()));
              logContent.set("item_uom", getOrDash(order.getUoM()));
              logContent.set("item_sales_uom", getOrDash(order.getPack() + ""));
              logContent.set("item_quantity", getOrDash(order.getQuantity() + ""));
              logContent.set("item_unit_price", nfcBig(float(order.getUnitPrice()), 6));
              logContent.set("item_subtotal", nfcBig(float(order.getSubtotal()), 2));
              logContent.set("item_tax_type", getOrDash(order.getTaxType()));
              logContent.set("item_tax_amount", getOrDash(order.getTaxAmount()));
              logContent.set("item_total_amount", nfcBig(float(order.getTotalAmount()), 2));
              logContent.set("voucher_subtotal", nfcBig(voucher.getVoucherSummary().getSubtotal(), 2) + "");
              logContent.set("voucher_tax_total", nfcBig(voucher.getVoucherSummary().getTaxTotal(), 2) + "");
              logContent.set("voucher_grand_total", nfcBig(voucher.getVoucherSummary().getGrandTotal(), 2) + "");
              logContents = (StringDict[]) append(logContents, logContent);
            }
          } 
          catch (Exception e) {
            println("Error logging order for voucher: " + voucherCode + ", " + e.getMessage());
            cLogger.log ("Error logging order for voucher: " + voucherCode + ", " + e.getMessage());
          }
        } 
        catch (Exception e) {
          println("Error processing voucher: " + voucherCode + ", " + e.getMessage());
          cLogger.log ("Error processing voucher: " + voucherCode + ", " + e.getMessage());
        }
      }

      if (logContents.length > 0) {
        try {
          oLogger.log(logContents);
          //println("Logged " + logContents.length + " entries");
        } 
        catch (Exception e) {
          println("Error logging: " + e.getMessage());
          cLogger.log ("Error logging: " + e.getMessage());
        }
      }

      queue.clear(); // Clear the queue after processing all vouchers
    } 
    catch (Exception e) {
      println("Error in processQueue: " + e.getMessage());
      cLogger.log ("Error in processQueue: " + e.getMessage());
    }
  }

  void sendVouchers() {
    // Kept for completeness, but not called in run()
    try {
      if (imgQueue.size() == 0) return;
      if (!temp.exists()) temp.mkdirs();
      if (!temp.exists() || temp.list() == null || temp.list().length == 0) return;
      if (!connectedToNetwork() || !dest.exists()) return;

      File[] files = temp.listFiles();
      if (files != null) {
        for (File file : files) {
          if (!file.isFile() || !file.getName().toLowerCase().endsWith(".pdf")) continue;
          String fromPath = file.getAbsolutePath();
          if (!imgQueue.hasKey(fromPath)) {
            file.delete();
            println("Deleted orphaned PDF: " + file.getName());
            cLogger.log ("Deleted orphaned PDF: " + file.getName());
            continue;
          }
          try {
            String toPath = dest.getAbsolutePath() + "/" + file.getName();
            File toFile = new File(toPath);
            if (!connectedToNetwork() || !dest.exists()) {
              println("Network or destination unavailable, skipping: " + file.getName());
              cLogger.log ("Network or destination unavailable, skipping: " + file.getName());
              return;
            }
            if (moveFile(file, toFile)) {
              imgQueue.remove(fromPath);
              println("Sent PDF: " + file.getName());
              cLogger.log ("Sent PDF: " + file.getName());
            } else {
              println("Failed to send PDF: " + file.getName());
              cLogger.log ("Failed to send PDF: " + file.getName());
            }
          } 
          catch (Exception e) {
            println("Error sending PDF: " + file.getName() + ", " + e.getMessage());
            cLogger.log ("Error sending PDF: " + file.getName() + ", " + e.getMessage());
          }
        }
      }
    } 
    catch (Exception e) {
      println("Error in sendVouchers: " + e.getMessage());
      cLogger.log ("Error in sendVouchers: " + e.getMessage());
    }
  }

  void run() {
    while (running) {
      checkAndQueue();  // Check and queue XMLs
      processQueue();   // Process queued vouchers
      // sendVouchers(); // Commented out as in original VoucherQueuer
      delay(checkinPeriod); // Wait 1s
    }
  }

  void stop() {
    running = false;
  }

  void delay(int millis) {
    try {
      Thread.sleep(millis);
    } 
    catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      running = false;
    }
  }
}
