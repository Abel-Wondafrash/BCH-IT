class Order {
  private String name;
  private String code;
  private String state;

  private Partner partner;
  private List <OrderLine> lines;

  private String subtotal;
  private String tax;
  private String total;
  private String stateOC;

  // For Attachment
  private String voucherNo;
  private String fs;
  private String MRC;
  private String aSubtotal;
  private String aVat;
  private String aGrandTotal;

  Order (String name, String total, String state) {
    this.name = name;
    this.total = total;
    this.state = state;
  }
  Order () {
  }

  // Setters
  String setValues (processing.data.Table oTable) {
    if (oTable == null || !oTable.hasColumnTitles() || oTable.getRowCount () == 0) return "Table is null, with no header, or empty";

    try {
      // Order headers
      name = oTable.getStringColumn ("sale_order_name") [0];
      code = getPositiveInt (name);
      state = oTable.getStringColumn ("order_state") [0];

      // Partner details
      String pCode = oTable.getStringColumn ("partner_code") [0];
      String pTin = oTable.getStringColumn ("customer_tin") [0];
      String pName = oTable.getStringColumn ("partner_name") [0];
      partner = new Partner (pCode, pTin, pName);
      if (!partner.isValid ()) return "Invalid partner details";

      // Order Lines details
      String itemWarehouseCodes [] = oTable.getStringColumn ("product_warehouse_code");
      String itemNames [] = oTable.getStringColumn ("product_name");
      String itemSaleQuantities [] = oTable.getStringColumn ("sale_uom_qty");
      String itemSaleUOMs [] = oTable.getStringColumn ("uom_name");
      String itemQuantities [] = oTable.getStringColumn ("product_uom_qty");
      String itemUnitPrices [] = oTable.getStringColumn ("price_unit");
      String itemLineSubtotals [] = oTable.getStringColumn ("line_subtotal");
      String isExcisables [] = oTable.getStringColumn ("is_excisable");

      lines = new ArrayList <OrderLine> ();
      for (int i = 0; i < itemWarehouseCodes.length; i ++) {
        OrderLine oLine = new OrderLine (
          itemWarehouseCodes [i], itemNames [i], itemSaleQuantities [i], itemSaleUOMs [i], 
          itemQuantities [i], itemUnitPrices [i], itemLineSubtotals [i], isExcisables [i]);
        if (!oLine.isValid ()) return "Invalid Order Line";
        lines.add (oLine);
      }
      if (!isValid ()) return "Invalid Order Line";
      if (isExcisable ()) lines.add (new OrderLine (lines, EXCISE_TAX_ITEM_CODE, EXCISE_TAX_ITEM_NAME, EXCISE_TAX_QUANTITY, EXCISE_SALE_UOM));

      // Order footers
      subtotal = oTable.getStringColumn ("subtotal") [0];
      tax = oTable.getStringColumn ("tax") [0];
      total = oTable.getStringColumn ("total") [0];
    }
    catch (Exception e) {
      println ("Error setting values from Order Table:", e);
      cLogger.log ("Error setting values from Order Table: " + e);
    }

    return null;
  }

  // For Attachment
  void setFS (String fs) {
    this.fs = fs;
  }
  void setMRC (String MRC) {
    this.MRC = MRC;
  }
  void setVoucherNumber (String voucherNo) {
    this.voucherNo = voucherNo;
  }
  void setAsubtotal (String aSubtotal) {
    this.aSubtotal = aSubtotal;
  }
  void setAvat (String aVat) {
    this.aVat = aVat;
  }
  void setAgrandTotal (String aGrandTotal) {
    this.aGrandTotal = aGrandTotal;
  }

  boolean exists () {
    return lines != null;
  }
  boolean isEmpty () {
    return exists () && lines.isEmpty();
  }
  boolean isValid () {
    return !lines.contains (null);
  }
  boolean isExcisable () {
    for (OrderLine line : lines) if (line.isExcisable) return true;
    return false;
  }
  boolean isUnprocessed () {
    return ORDER_STATE_UNPROCESSED.contains (state);
  }

  // Getters
  String getName () {
    return name;
  }
  String getCode () {
    return code;
  }
  String getState () {
    return state;
  }
  Partner getPartner () {
    return partner;
  }
  List <OrderLine> getLines () {
    return lines;
  }
  String getSubtotal () {
    return subtotal;
  }
  String getTax () {
    return tax;
  }
  String getTotal () {
    return total;
  }

  // For Attachment
  String getFS () {
    return fs;
  }
  String getMRC () {
    return MRC;
  }
  String getVoucherNumber () {
    return voucherNo;
  }
  String getAsubtotal () {
    return aSubtotal;
  }
  String getAvat () {
    return aVat;
  }
  String getAgrandTotal () {
    return aGrandTotal;
  }

  void printVerbose () {
    println (lines.size(), "order lines");
    println (getPartner().getCode(), getPartner().getTin());
    for (OrderLine line : getLines()) {
      println (">", line.getItemWarehouseCode(), line.getItemName(), line.getItemSaleQuantity(), line.getItemPrice ());
    }
    println (getSubtotal (), getTax (), getTotal ());
  }

  // Odoo Client fetched Details : Sale Order and Invoice
  String getStateOC () {
    try {
      return oc.getState (getName ());
    } 
    catch (Exception e) {
      System.err.println ("Error fetching state through Odoo Client: " + e);
      cLogger.log ("Error fetching state through Odoo Client: " + e);
      return null;
    }
  }
  void updateState () {
    stateOC = getStateOC ();
  }
  boolean isDraft () {
    return stateOC == null || !stateOC.equals ("draft")? false : true;
  }
  boolean isConfirmed () {
    return stateOC == null || !stateOC.equals ("sale")? false : true;
  }
  boolean isSalesOrder () {
    return stateOC == null || !stateOC.equals ("sent")? false : true;
  }

  boolean confirmOrder () {
    try {
      return oc.confirmOrder(getName ());
    } 
    catch (Exception e) {
      System.err.println ("Error trying to confirm order:" + getName () + " " + e);
      cLogger.log ("Error trying to confirm order:" + getName () + " " + e);
      return false;
    }
  }
  boolean createInvoice () {
    try {
      List <Integer> invoiceIds = oc.createInvoice(getName ());
      return invoiceIds != null && !invoiceIds.isEmpty ();
    } 
    catch (Exception e) {
      System.err.println ("Error confirming order:" + getName () + " " + e);
      cLogger.log ("Error confirming order:" + getName () + " " + e);
      return false;
    }
  }

  Invoices getInvoices () {
    return new Invoices (getInvoicesOC ());
  }
  List <Invoice> getInvoicesOC () {
    try {
      LinkedHashMap <Integer, String> invoicesDetails = oc.getOrderInvoices (getName ());
      List <Invoice> invoices = new ArrayList <Invoice> ();
      for (Integer invoiceId : invoicesDetails.keySet ())
        invoices.add (new Invoice (invoiceId, invoicesDetails.get (invoiceId)));
      return invoices;
    } 
    catch (Exception e) {
      System.err.println ("Error obtaining invoices: " + e);
      cLogger.log ("Error obtaining invoices: " + e);
      return null;
    }
  }
}

class Invoices {
  List <Invoice> list;

  Invoices (List <Invoice> list) {
    if (list != null) this.list = list;
    list = new ArrayList <Invoice> ();
  }

  List <Invoice> list  () {
    return list;
  }

  boolean isEmpty () {
    return list.isEmpty ();
  }
  boolean containsDraft () {
    for (Invoice invoice : list) if (invoice.isDraft ()) return true;
    return false;
  }
  boolean isAllPaid () {
    for (Invoice invoice : list) if (!invoice.isPaid ()) return false;
    return true;
  }
}
class Invoice {
  private Integer id;
  private String state;

  Invoice (Integer id, String state) {
    this.id = id;
    this.state = state;
  }

  Integer getId () {
    return id;
  }
  String getState () {
    return state;
  }

  boolean isDraft () {
    return state != null && state.equals ("draft");
  }
  boolean isPaid () {
    return state != null && state.equals ("paid");
  }

  boolean validate () {
    if (!isDraft ()) return false;

    try {
      return oc.validateInvoice(id);
    } 
    catch (Exception e) {
      System.err.println ("Error trying to validate: " + e);
      cLogger.log ("Error trying to validate: " + e);
      return false;
    }
  }
}

class OrderLine {
  private String itemWarehouseCode;
  private String itemName;
  private String itemSaleQuantity;
  private String itemSaleUOM;
  private String itemQuantity;
  private String itemUnitPrice;
  private String itemPrice;
  private String itemSubtotal;
  private boolean isExcisable;

  // Normal (Non-Excise Tax) line
  OrderLine (
    String warehouseCode, String itemName, String itemSaleQuantity, String itemSaleUOM, 
    String itemQuantity, String itemUnitPrice, String itemSubtotal, String excisable) {
    this.itemWarehouseCode = warehouseCode;
    this.itemName = itemName;
    this.itemSaleQuantity = itemSaleQuantity;
    this.itemQuantity = itemQuantity;
    this.itemSaleUOM = itemSaleUOM;
    this.itemUnitPrice = itemUnitPrice;
    this.itemSubtotal = itemSubtotal;
    this.isExcisable = excisable != null && excisable.equals ("t")? true : false;

    try {
      itemPrice = calculateItemPrice ();
    } 
    catch (Exception e) {
      println ("Error calculating itemPrice:", itemWarehouseCode, itemName, itemSaleQuantity, itemQuantity, itemUnitPrice, itemUnitPrice);
      cLogger.log ("Error calculating itemPrice: " + 
        itemWarehouseCode + " | " + itemName + " | " + itemSaleQuantity + " | " + itemQuantity + " | " + itemUnitPrice + " | " +  itemUnitPrice);
    }
  }
  // Excise Tax line
  OrderLine (List <OrderLine> lines, String warehouseCode, String itemName, String itemSaleQuantity, String itemSaleUOM) {
    this.itemWarehouseCode = warehouseCode;
    this.itemName = itemName;
    this.itemSaleQuantity = itemSaleQuantity;
    this.itemSaleUOM = itemSaleUOM;

    try {
      itemPrice = calculateItemPrice (lines);
      itemSubtotal = itemPrice;
    } 
    catch (Exception e) {
      println ("Error calculating itemPrice:", itemWarehouseCode, itemName, itemSaleQuantity, itemQuantity, itemUnitPrice);
      cLogger.log ("Error calculating itemPrice: "
        + " | " + itemWarehouseCode + " | " + itemName + " | " + itemSaleQuantity + " | " + itemQuantity + " | " + itemUnitPrice);
    }
  }

  String calculateItemPrice (List <OrderLine> lines) {
    Double subtotal = 0d;
    for (OrderLine line : lines) {
      Double quantity = Double.parseDouble (line.getItemSaleQuantity());
      Double price = Double.parseDouble (line.getItemPrice());
      subtotal += quantity * price;
    }
    subtotal *= EXCISE_TAX_PERCENTAGE/100.0; // This item is excise given 'lines'
    return nfBig (subtotal, PRICE_DP);
  }
  String calculateItemPrice () {
    Double iQuantity = Double.parseDouble(itemQuantity);
    Double sQuantity = Double.parseDouble (itemSaleQuantity);
    Double iUnitPrice = Double.parseDouble (itemUnitPrice);
    Double iPrice = iUnitPrice * (iQuantity/sQuantity);
    Double iSubtotal = Double.parseDouble (itemSubtotal);

    if (isExcisable) {
      iPrice /= (1 + EXCISE_TAX_PERCENTAGE/100.0);
      iSubtotal /= (1 + EXCISE_TAX_PERCENTAGE/100.0);
    }
    itemSubtotal = nfBig (iSubtotal + "", PRICE_DP);
    return nfBig (iPrice, PRICE_DP);
  }

  boolean isValid () {
    return itemWarehouseCode != null && itemName != null && itemSaleQuantity != null && itemSaleUOM != null &&
      itemQuantity != null && itemUnitPrice != null && itemPrice != null && itemSubtotal != null;
  }
  boolean isExcisable () {
    return isExcisable;
  }

  // Getters
  String getItemWarehouseCode () {
    return itemWarehouseCode;
  }
  String getItemName () {
    return itemName;
  }
  String getItemSaleQuantity () {
    if (itemSaleQuantity != null) return str (Integer.parseInt (itemSaleQuantity));
    return null;
  }
  String getItemSaleUOM () {
    return itemSaleUOM;
  }
  String getItemQuantity () {
    return itemQuantity;
  }
  String getItemUnitPrice () {
    return itemUnitPrice;
  }
  String getItemPrice () {
    return itemPrice;
  }
  String getItemSubtotal () {
    return itemSubtotal;
  }
}

class Reference {
  private String code;

  Reference (processing.data.Table rTable) {
    if (rTable == null || !rTable.hasColumnTitles() || rTable.getRowCount () == 0) return;

    try {
      setValues (rTable);
    }
    catch (Exception e) {
      println ("Error setting values from Reference Table:", e);
      cLogger.log ("Error setting values from Reference Table: " + e);
    }
  }

  void setValues (processing.data.Table rTable) {
    code = rTable.getStringColumn ("client_order_ref") [0];
    //println ("code:", code);
  }

  boolean exists () {
    return code != null;
  }
  boolean isEmpty () {
    return code != null && code.trim ().isEmpty();
  }
  boolean isValid () {
    return code != null && getPositiveInt (code).length () >= FS_NUMBER_SAMPLE.length ();
  }
  String getName () {
    return code;
  }
  String getNumber () {
    return getPositiveInt (code);
  }
}

class Orders {
  private List <Order> list;
  private String grandTotal;

  Orders (processing.data.Table oTable) {
    if (oTable == null || !oTable.hasColumnTitles() || oTable.getRowCount () == 0) return;
    list = new ArrayList <Order> ();
    try {
      setValues (oTable);
    }
    catch (Exception e) {
      println ("Error setting values from Partner Orders Table:", e);
      cLogger.log ("Error setting values from Partner Orders Table: " + e);
    }
  }

  void setValues (processing.data.Table rTable) {
    String names [], totals [], states [];
    names = rTable.getStringColumn ("sale_order_name");
    totals = rTable.getStringColumn ("total");
    states = rTable.getStringColumn ("state");
    for (int i = 0; i < names.length; i ++) list.add (new Order (names [i], totals [i], states [i]));

    grandTotal = rTable.getStringColumn ("grand_total") [0];
  }

  boolean exists () {
    return grandTotal != null;
  }
  boolean isEmpty () {
    return grandTotal != null && grandTotal.trim ().isEmpty();
  }

  List <Order> list () {
    return list;
  }
  String getGrandTotal () {
    return grandTotal;
  }
}

import java.util.concurrent.ConcurrentLinkedQueue;

class OrderProcessor implements Runnable {
  private int checkinPeriod = 5000;

  ConcurrentLinkedQueue<Order> orders;

  OrderProcessor () {
    orders = new ConcurrentLinkedQueue<Order>();
    new Thread(this).start();
  }

  void add (Order order) {
    orders.add(new Order(order.getName(), order.getTotal(), order.getState()));
  }

  String confirmInvoiceValidate (Order order) {
    Order cOrder = new Order (order.getName (), order.getTotal (), order.getState ());

    /// Confirm | Crate Invoice | Validate
    cOrder.updateState();
    if (cOrder.isDraft() && !cOrder.confirmOrder())
      return "> Failed to confirm draft order '" + cOrder.getName () + "'";

    cOrder.updateState ();
    if (cOrder.isConfirmed() && !cOrder.createInvoice())
      return "> Failed to create invoice for order '" + cOrder.getName () + "'";

    cOrder.updateState ();
    if (!cOrder.isSalesOrder ())
      return "> Failed to create invoice | malfunctioning createInvoiceOC '" + cOrder.getName () + "'";

    Invoices invoices = cOrder.getInvoices();
    if (invoices.isEmpty()) return "> Created Invoice but there is no invoiced line '" + cOrder.getName () + "'";
    if (invoices.isAllPaid()) return "> Nothing to validate. All invoices are 'paid' for order '" + cOrder.getName () + "'";

    for (Invoice invoice : invoices.list ()) {
      if (!invoice.isDraft()) continue;
      if (!invoice.validate())
        return "> Failed to validate invoice " + invoice.getId () + " for order '" + cOrder.getName () + "'";
    }

    return null;
  }

  void run() {
    while (true) {
      Order order;
      while ((order = orders.poll()) != null) { // drains queue
        String response = confirmInvoiceValidate(order);
        if (response != null) {
          System.err.println(order.getName() + ": " + response);
          cLogger.log (order.getName() + ": " + response);
        }
        else {
          println("CIV Done:", order.getName());
          cLogger.log ("CIV Done: " + order.getName());
        }
      }
      delay (checkinPeriod);
    }
  }
}
