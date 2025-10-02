Field customerDD, tin, origin, articleDD, articleD, quantity, price, fs, add, remove;
Field voucherNo, mrcNo;
Field subtotal, vat, grandTotal;

String verifyOrderValidity (String code) {
  processing.data.Table vTable = getVoucherDetails (code);
  if (vTable == null) return "Could not verify order '" + SALES_ORDER_PREFIX + code + "'";

  Order order = new Order ();
  String response = order.setValues (vTable);
  if (response != null) return response;

  String orderCode = order.getCode ();
  // Order Fetching Validity Check
  if (orderCode == null || !orderCode.equals (code))
    return "Order " + SALES_ORDER_PREFIX + code + " DOES NOT EXIST!\nMake sure you are on the right DB.\n\nSelected DB: '" + DB_NAME + "'";

  processing.data.Table fsT = getFS (orderCode);
  // FS Fetching Validity Check
  if (fsT == null || !fsT.hasColumnTitles() || fsT.getRowCount () == 0) return "Failed to fetch FS for order '" + SALES_ORDER_PREFIX + code + "'";

  String orderFS = fsT.getStringColumn("client_order_ref") [0];
  // Duplicate Order Check
  if (orderFS != null && !orderFS.isEmpty()) return "Order " + order.getName() + " is already processed with Reference '" + orderFS + "'";

  // Order Processibility Check
  if (!order.exists () || order.isEmpty() || !order.isValid() || !order.isUnprocessed()) {
    if (!order.exists()) return ("Order does NOT exist");
    if (order.isEmpty()) return ("Order is EMPTY");
    if (!order.isValid()) return ("Order is NOT valid");
    if (!order.isUnprocessed ()) return ("Order is NON_PROCESSIBLE (state is '" + order.getState() + "')");
  }

  Orders orders = getActivePartnerOrders (order.getPartner ().getCode ());
  if (orders == null) return "> Partner Data NOT FOUND!\n\n" +
    "Name: '" + order.getPartner ().getName () + "'\nCode: '" + order.getPartner ().getCode () + "'";
  if (orders.isEmpty()) return "> Improbable Error: No processible orders found for partner '" + order.getPartner () + "'";

  Double parBalance = getPartnerBalance (order.getPartner ().getCode ());
  if (parBalance == null) return "> Failed to fetch customer balance for '" + order.getPartner().getCode() + "'";

  Double ordersTotal = Double.parseDouble (orders.getGrandTotal ());
  if (ordersTotal > parBalance) {
    response = "> Insufficient Balance for " + order.getPartner ().getCode() + "!\n\n";
    int counter = 1;
    for (Order o : orders.list ()) response += counter ++ + " - " +
      o.getName () + " " + nfcBig (o.getTotal(), 2) + "\n";
    response += "\nCurrent Customer Balance = " + nfcBig (parBalance, 2) +
      "\nGrand Total of active order(s) = " + nfcBig (ordersTotal, 2) + "\n" +
      "CCB_GTO_Delta is: " + nfcBig(ordersTotal - parBalance, 2);
    return response;
  }

  //if (true) return ">";
  return entry (order);
}

String entry (Order order) {
  //println ("Waiting for window to exist");
  if (!winWaitUntilExist (Windows.mainTitle, timeouts.getWinWait ()))
    return "> Timeout waiting for window to exist";

  if (!isWinForeground (Windows.mainTitle)) {
    //println ("Setting foreground");
    setForeground (Windows.mainTitle);

    //println ("Confirming set foreground");
    if (!winWaitUntilForeground (Windows.mainTitle, timeouts.getWinWait ()))
      return "> Timeout waiting for window to be foreground";
  }

  //println ("Waiting for '" + Windows.cashSalesVoucher + "' window");
  if (!winWaitUntilContains (Windows.mainTitle, Windows.cashSalesVoucher, timeouts.getWinWait ())) // CASH_SALES_VOUCHER_TITLE_IN_WINDOW_INDEX
    return "> Timeout waiting for 'Cash Sales Voucher' to exist";

  // Fetch and update window fields
  fields = new Fields (Windows.mainTitle, winLabels);
  if (!updateFields ()) return "> Window is Missing Field(s) in WinLabels-Main";

  // Verify empty line
  remove.click ();
  String orderLineContent = isOrderLineEmpty ();
  if (orderLineContent != null) return orderLineContent;
  //println ("OrderLine is Empty");

  //if (true) return "";

  { /// SET CUSTOMER
    // Click and wait for Customer container to be drawn
    String partnerTin = order.getPartner ().getTin();
    customerDD.click ();
    if (!waitWhilePixelColor (555, 255, -1, timeouts.getFieldWait ())) return "> Timeout waiting for Customer entry field to appear";
    // Enter TIN
    robot.typeString (partnerTin);
    delay (200);
    robot.DOWN();

    // Wait for Customer matching TIN to be selected
    if (!waitForPixelColor(555, 310, SELECTION_BLUE, timeouts.getFieldWait ())) return "> Timeout waiting to select partner. TIN maybe mismatch or missing"; 
    // Select customer
    robot.ENTER ();
    if (!waitForFieldContent (tin, partnerTin, timeouts.getFieldWait ()))
      return "> Timeout waiting to read TIN content";
    if (!isValidField (tin.getContent(), partnerTin, CONTENT_VALIDATION_TYPE_POSITIVE_INTEGER))
      return "> TIN is invalid or not a match! " + tin.getContent ();
  }

  { /// Set ORIGIN (Remark)
    String orderName = order.getName();
    origin.setContent(orderName);
    if (!waitForFieldContent (origin, orderName, timeouts.getFieldWait ()))
      return "> Timeout waiting to read ORIGIN content " + origin.getContent ();
    if (!isValidField (origin.getContent(), orderName, CONTENT_VALIDATION_TYPE_TEXT))
      return "> ORIGIN is invalid or not a match! " + origin.getContent ();
  }

  { /// Set Order Lines
    for (OrderLine line : order.getLines ()) {
      String itemCode = line.getItemWarehouseCode ();
      articleDD.click();
      if (!waitWhilePixelColor (510, 325, -1, timeouts.getFieldWait ())) return "> Timeout waiting for Article entry field to appear";
      //// Enter Product Code
      robot.typeString (itemCode);
      delay (200);
      robot.DOWN();

      // Wait for Product Code to be selected
      String itemName = line.getItemName();
      if (!waitForPixelColor(510, 378, SELECTION_BLUE, timeouts.getFieldWait ())) return "> Timeout waiting to select Article. Article maybe mismatch or missing";
      // Select product
      robot.ENTER ();
      if (!waitForFieldContent (articleD, itemName, timeouts.getFieldWait ()))
        return "> Timeout waiting to read Article Description content " + articleD.getContent();
      if (!isValidField (articleD.getContent(), itemName, CONTENT_VALIDATION_TYPE_TEXT))
        return "> Article Description is invalid or not a match! " + articleD.getContent();

      /// Set QUANTITY
      String itemQuantity = line.getItemSaleQuantity();
      quantity.click();
      robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_A});
      robot.typeString(itemQuantity);
      robot.ENTER ();
      if (!waitForFieldContent (quantity, itemQuantity, timeouts.getFieldWait ())) return "> Timeout waiting to read Quantity content";
      if (!isValidField (quantity.getContent(), itemQuantity, CONTENT_VALIDATION_TYPE_POSITIVE_INTEGER))
        return "> Quantity is invalid or not a match! " + quantity.getContent();
      delay (200);

      /// Set PRICE
      String itemPrice = line.getItemPrice ();
      price.click ();
      robot.press (new Integer [] {KeyEvent.VK_CONTROL, KeyEvent.VK_A});
      robot.typeString (itemPrice);
      robot.press (new Integer [] {KeyEvent.VK_SHIFT, KeyEvent.VK_TAB});
      if (!waitForFieldContent (price, itemPrice, timeouts.getFieldWait ())) return "> Timeout waiting to read Price content";
      if (!isValidField (price.getContent(), itemPrice, CONTENT_VALIDATION_TYPE_NUMBER))
        return "> Price is invalid or not a match! " + price.getContent();

      delay (200);
      add.click();
    }
  }

  { /// Confirm Grand Total
    delay (200);
    add.click ();
    String articleContent = isArticleEmpty ();
    if (articleContent != null) return articleContent;
    //println ("No article to add");

    fields = new Fields (Windows.mainTitle, winLabelsAll);
    if (!updateFields ()) return "> Window is Missing Field(s) in WinLabels-All";

    fields.update ();
    grandTotal = fields.get ("Grand Total").getEditable (0);
    String orderGrandTotal = order.getTotal();

    if (!waitForFieldContent (grandTotal, orderGrandTotal, timeouts.getFieldWait ()))
      return "> Timeout waiting to read Grand Total content " + grandTotal.getContent();
    String setGT = getNumber (grandTotal.getContent ());
    float setGTfloat = Float.parseFloat(setGT);
    float orderGTfloat = Float.parseFloat(orderGrandTotal);
    float delta = abs (setGTfloat - orderGTfloat);
    if (delta > GRAND_TOTAL_NOMINAL_DELTA) return "> Grand Total Delta is NOT nominal '" + delta +
      "' Expected: " + orderGTfloat + " Found: " + setGTfloat;
    //println ("Nominal GT Delta:", delta);
  }

  fields = new Fields (Windows.mainTitle, winLabelsAll);
  if (!updateFields ()) return "> Window is Missing Field(s) in WinLabels-All";

  fields.update ();
  subtotal = fields.get ("Sub Total").getEditable (0);
  vat = fields.get ("VAT [15 %]").getEditable (1);
  grandTotal = fields.get ("Grand Total").getEditable (0);

  order.setVoucherNumber (voucherNo.getContent ());
  order.setFS (fs.getContent ());
  order.setMRC (mrcNo.getContent ());
  order.setAsubtotal (getNumber (subtotal.getContent ()));
  order.setAvat (getNumber (vat.getContent ()));
  order.setAgrandTotal (getNumber(grandTotal.getContent ()));

  for (int i = 0; i < GENERATOR_LABELS.length; i ++) {
    String pdfPath = paths_.tempDir + ATTACHMENT_PREFIX + order.getName () + "-" + (i + 1) + ".pdf";
    String labels [] = new String [] {GENERATOR_LABELS [i]};
    if (!aGen.generate(labels, order, pdfPath)) return "Failed to create attachment for '" + order.getName () + "'";

    // Resize PDF
    String resizedPath = paths_.tempDir + getDateToday ("yyyy/MMM/MMM_dd_yyyy/") +
      order.getName () + "-" + RandomStringUtils.randomAlphanumeric (ATTACHMENT_RANDOM_CODE_LENGTH) + "_resized.pdf";
    pdf_toolkit.resize (pdfPath, resizedPath);
    if (!isFileCreationComplete (resizedPath, FILE_CREATION_TIMEOUT)) return "Failed to resize PDF";
    printer.printPDF(resizedPath, 1, order.getName ());
    //break;
  }

  //if (true) return ">";

  { // Set FS
    if (!setFS (order, order.getFS ())) return "> Failed trying to set FS (" + order.getFS () + ")" + " for " + order.getName ();
  }

  { /// Confirm | Crate Invoice | Validate
    op.add (order);
  }

  if (AUTO_CLOSE_VOUCHER_SAVED_MODAL) {
    if (!winWaitUntilExist (Windows.voucherSavedModal, timeouts.getWinWait ()*4)) return ("> Timeout waiting for " + Windows.voucherSavedModal + " Window to exist");
    closeWindowByTitle (Windows.voucherSavedModal);
    if (!winWaitIfExist (Windows.voucherSavedModal, timeouts.getWinWait ()*4)) return ("> Timeout waiting for " + Windows.voucherSavedModal + " to close");
  }

  if (AUTO_CLOSE_PRINT_DIALOG) {
    if (!winWaitUntilExist (Windows.printDialog, timeouts.getWinWait ()*4)) return ("> Timeout waiting for " + Windows.printDialog + " Window to exist");
    closeWindowByTitle (Windows.printDialog);
    if (!winWaitIfExist (Windows.printDialog, timeouts.getWinWait ()*4)) return ("> Timeout waiting for " + Windows.printDialog + " to close");
  }

  return null;
}

//  order.updateState();
//  if (order.isDraft() && !order.confirmOrder())
//    return "> Failed to confirm draft order '" + order.getName () + "'";

//  order.updateState ();
//  if (order.isConfirmed() && !order.createInvoice())
//    return "> Failed to create invoice for order '" + order.getName () + "'";

//  order.updateState ();
//  if (!order.isSalesOrder ())
//    return "> Failed to create invoice | malfunctioning createInvoiceOC '" + order.getName () + "'";

//  Invoices invoices = order.getInvoices();
//  if (invoices.isEmpty()) return "> Created Invoice but there is no invoiced line '" + order.getName () + "'";
//  if (invoices.isAllPaid()) return "> Nothing to validate. All invoices are 'paid' for order '" + order.getName () + "'";

//  for (Invoice invoice : invoices.list ()) {
//    if (!invoice.isDraft()) continue;
//    if (!invoice.validate())
//      return "> Failed to validate invoice " + invoice.getId () + " for order '" + order.getName () + "'";
//  }

boolean waitForFieldContent (Field field, String setVal, long timeout) {
  long startTime = millis ();
  String fetchedVal = field.getContent();
  // Wait for val to appear in field
  while (fetchedVal == null || fetchedVal.trim ().isEmpty() || fetchedVal.trim ().length () < setVal.length()) {
    delay (500);
    fetchedVal = field.getContent();
    if (millis () - startTime > timeout) return false;
  }
  return true;
}
boolean waitForPixelColor (int x, int y, int _color, long timeout) {
  long startTime = millis ();
  // Wait for val to match _color
  while (robot.pixelColor (x, y) != _color) {
    delay (500);
    if (millis () - startTime > timeout) return false;
  }
  return true;
}
boolean waitWhilePixelColor (int x, int y, int _color, long timeout) {
  long startTime = millis ();
  // Wait for val to match _color
  while (robot.pixelColor (x, y) == _color) {
    delay (500);
    if (millis () - startTime > timeout) return false;
  }
  return true;
}
boolean isValidField (String fetchedVal, String setVal, String contentValidationType) {
  String cleanedVal = null;
  if (contentValidationType.equals (CONTENT_VALIDATION_TYPE_NUMBER)) cleanedVal = getNumber (fetchedVal);
  else if (contentValidationType.equals (CONTENT_VALIDATION_TYPE_POSITIVE_INTEGER)) cleanedVal = getPositiveInt (fetchedVal);
  else cleanedVal = fetchedVal;

  if (cleanedVal == null) {
    System.err.println ("Content is invalid or empty fetchedVal: " + fetchedVal + " setVal: " + setVal + " contentValidationType: " + contentValidationType);
    cLogger.log ("Content is invalid or empty fetchedVal: " + fetchedVal + " setVal: " + setVal + " contentValidationType: " + contentValidationType);
    return false;
  }

  if (contentValidationType.equals (CONTENT_VALIDATION_TYPE_NUMBER)) return float (cleanedVal) == float (fetchedVal);
  return cleanedVal.equals (setVal);
}
boolean updateFields () {
  fields.update ();

  try {
    customerDD = fields.get ("Customer*").getSelectable (0);
    tin = fields.get ("Customer*").getEditable (0);
    origin = fields.get ("Remark").getEditable (0);
    articleDD = fields.getD ("Customer*").getSelectable (0);
    articleD = fields.getD ("Customer*").getEditable (0);
    quantity = fields.get ("Quantity").getEditable (0);
    price = fields.get ("Price").getEditable (0);
    fs = fields.get ("FS No.").getEditable(0);
    add = fields.getSelf ("Add").getSelf (0);
    remove = fields.getSelf ("Remove").getSelf (0);
    mrcNo = fields.get ("MRC No.").getEditable(0);
    voucherNo = fields.get ("Cash Sales Voucher No").getEditable(0);

    Field temp [] = new Field [] {customerDD, tin, origin, articleDD, articleD, quantity, price, fs, add, remove};
    for (Field field : temp) if (field == null) return false;
  } 
  catch (Exception e) {
    println ("Missing Field(s)", e);
    cLogger.log ("Missing Field(s) " + e);
    return false;
  }
  return true;
}

String isArticleEmpty () {
  if (!winWaitUntilExist (Windows.addLineItemModal, timeouts.getWinWait ())) return "> Timeout waiting for " + Windows.addLineItemModal + " Window to exist";
  if (!fieldWaitUntilExist (Windows.addLineItemModal, "&OK", timeouts.getFieldWait ())) return "> Timeout waiting for " + Windows.addLineItemModal + " Field to exist";
  robot.press (new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_O});

  if (!winWaitIfExist (Windows.addLineItemModal, timeouts.getWinWait ())) return "> Timeout waiting for " + Windows.addLineItemModal + " to close";
  if (!winWaitUntilExist (Windows.mainTitle, timeouts.getWinWait ())) return "> Timeout waiting for " + Windows.mainTitle + " to exist";

  return null;
}
String isOrderLineEmpty () {
  if (!winWaitUntilExist (Windows.removeLineItemModal, timeouts.getWinWait ())) return "> Timeout waiting for " + Windows.removeLineItemModal + " Window to exist";
  if (hasFieldText (Windows.removeLineItemModal, new String [] {"&Yes", "&No"})) return "> Remove Added Lines First";

  if (!fieldWaitUntilExist (Windows.removeLineItemModal, "&OK", timeouts.getFieldWait ())) return "> Timeout waiting for " + Windows.removeLineItemModal + " Field to exist";
  robot.press (new Integer [] {KeyEvent.VK_ALT, KeyEvent.VK_O});

  if (!winWaitIfExist (Windows.removeLineItemModal, timeouts.getWinWait ())) return "> Timeout waiting for " + Windows.removeLineItemModal + " to close";
  if (!winWaitUntilExist (Windows.mainTitle, timeouts.getWinWait ())) return "> Timeout waiting for " + Windows.mainTitle + " to exist";

  return null;
}
