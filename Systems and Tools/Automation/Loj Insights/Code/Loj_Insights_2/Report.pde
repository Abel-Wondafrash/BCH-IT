import java.util.Collections;

class Report {
  Table raw;

  LinkedHashMap <String, Invoice> invoices;
  LinkedHashMap <String, LinkedHashMap <String, Customer>> customerCategories;

  StringList locations;
  StringList customersCodes;

  boolean isEmpty = true;

  Report (Table raw) {
    if (raw == null || raw.getRowCount() == 0) {
      println ("Input table is null or empty. Nothing to report.");
      return;
    }

    invoices = new LinkedHashMap <String, Invoice> ();
    locations = new StringList ();
    customersCodes = new StringList ();

    for (int i = 0; i < raw.getRowCount (); i ++) {
      TableRow row = raw.getRow (i);
      String so_code = row.getString (OrderHeaders.SO_NAME);
      Invoice invoice;
      if (invoices.containsKey (so_code)) invoice = (Invoice) invoices.get (so_code);
      else {
        Customer customer = new Customer ()
          .setName (row.getString (OrderHeaders.CUSTOMER_NAME))
          .setCode (row.getString (OrderHeaders.CUSTOMER_CODE))
          .setLocation (row.getString (OrderHeaders.CUSTOMER_LOCATION))
          .setTIN (row.getString (OrderHeaders.CUSTOMER_TIN))
          .setPhone (row.getString (OrderHeaders.CUSTOMER_PHONE));

        invoice = new Invoice ()
          .setSOcode (row.getString (OrderHeaders.SO_NAME))
          .setCustomer (customer)
          .setTax (row.getString (OrderHeaders.INVOICE_TAX))
          .setTotal (row.getString (OrderHeaders.INVOICE_TOTAL));
      }

      Order order = new Order ()
        .setItemName (row.getString (OrderHeaders.ITEM_NAME))
        .setShorthandItemName (row.getString (OrderHeaders.ITEM_NAME_SHORTHAND))
        .setSalesQuantity (row.getString (OrderHeaders.ORDER_SALES_QUANTITY))
        .setTotalPrice (row.getString (OrderHeaders.ORDER_TOTAL));

      invoice.addOrder (order);
      invoices.put (so_code, invoice);
      String location = invoice.getCustomer ().getLocation();
      if (invoice.isNonTaxable()) locations.appendUnique (CATEGORY_NON_TAXABLE);
      else if (location != null) locations.appendUnique (invoice.getCustomer ().getLocation());
      else locations.appendUnique (CATEGORY_UNKNOWN_DETAILS);

      customersCodes.appendUnique (invoice.getCustomer ().getCode());
    }

    println (invoices.size (), "\tInvoices");
    println (customersCodes.size (), "\tCustomers");
    println (locations.size (), "\tLocations");

    customerCategories = getCustomerCategories ();
    isEmpty = false;
  }

  List <String> getCategoriesNames () {
    return new ArrayList <String> (customerCategories.keySet());
  }

  LinkedHashMap <String, LinkedHashMap <String, Customer>> getCustomerCategories () {
    // Invoice Categories: Initializing
    LinkedHashMap <String, List <Invoice>> invoiceCategories = new LinkedHashMap <String, List <Invoice>> ();
    for (String location : locations) invoiceCategories.put (location, new ArrayList <Invoice> ());

    // Invoice Categories: Populating
    for (Invoice invoice : new ArrayList <Invoice> (invoices.values())) {
      if (invoice.isNonTaxable ()) invoiceCategories.get (CATEGORY_NON_TAXABLE).add (invoice);
      else if (invoice.getCustomer ().getLocation () != null) invoiceCategories.get (invoice.getCustomer ().getLocation()).add (invoice);
      else invoiceCategories.get (CATEGORY_UNKNOWN_DETAILS).add (invoice);
    }

    // Aggregating Categorized Invoices by Customers
    LinkedHashMap <String, LinkedHashMap <String, Customer>> customerCategories = new LinkedHashMap <String, LinkedHashMap <String, Customer>> ();
    for (String category : new ArrayList <String> (invoiceCategories.keySet())) {
      customerCategories.put (category, new LinkedHashMap <String, Customer> ()); // Customer Code, Customer
      List <Invoice> cInvoices = invoiceCategories.get (category);
      LinkedHashMap <String, Customer> customers = customerCategories.get (category);

      for (Invoice invoice : cInvoices) {
        String customerCode = invoice.getCustomer().getCode ();
        Customer customer = customers.containsKey(customerCode)? customers.get (customerCode) : invoice.getCustomer ();
        customer.addInvoice(invoice);
        customers.put (customer.getCode (), customer);
      }
    }

    println (customerCategories.size (), "\tCustomer Categories");
    return customerCategories;
  }

  List <Invoice> getInvoices (List <Customer> customers) {
    List <Invoice> catInvoices = new ArrayList <Invoice> (); // Categorized Invoices
    for (Customer customer : customers) catInvoices.addAll (customer.getInvoices ());

    return catInvoices;
  }
  List <Order> getOrders (List <Invoice> catInvoices) {
    List <Order> catOrders = new ArrayList <Order> (); // Categorized Orders
    for (Invoice invoice : new ArrayList <Invoice> (catInvoices))
      if (invoice.isValid ()) catOrders.addAll (invoice.getOrders ());

    return catOrders;
  }
  StringList getItems (List <Order> catOrders) {
    StringList items = new StringList ();
    for (Order order : catOrders) items.appendUnique (
      order.getShorthandItemName () == null? order.getItemName () : order.getShorthandItemName ());
    items.sort ();
    return items;
  }

  boolean isEmpty () {
    return isEmpty;
  }

  Table getTable (String category) {
    if (category == null || !getCategoriesNames ().contains (category)) {
      println ("Category: '" + "' Does NOT Exist");
      return null;
    }
    LinkedHashMap <String, Customer> catCustomers = customerCategories.get (category);

    // Fetch customers and sort by name
    List <Customer> customers = new ArrayList <Customer> (catCustomers.values ());
    Collections.sort (customers, customerNameComparator ());

    // Fetch Invoices
    List <Invoice> catInvoices = getInvoices (customers);

    // Fetch Orders
    List <Order> catOrders = getOrders (catInvoices);

    // Fetch and Sort Items
    StringList items = getItems (catOrders);

    // Headers
    String headers [] = {"#", "Partner Name"};
    for (String item : items) headers = append (headers, item);
    headers = append (headers, "|");
    for (String item : items) headers = append (headers, item + "\n(Birr)");
    headers = append (headers, "Grand Total");

    // Init table
    Table report = new Table ();
    report.setColumnTitles(headers);

    IntDict totalQuantities = new IntDict ();
    FloatDict totalAmounts = new FloatDict ();
    float categoryGrandTotal = 0;

    for (Customer customer : customers) {
      TableRow row = report.addRow();
      row.setInt ("#", report.lastRowIndex() + 1);
      row.setString ("Partner Name", customer.getName ());
      row.setString ("Grand Total", nfc (customer.getInvoiceGrandTotal (), 2));

      Orders orders = new Orders ();
      for (Invoice invoice : customer.getInvoices ())
        if (invoice.isValid()) orders.add (invoice.getOrders());
      orders.summarize();

      categoryGrandTotal += customer.getInvoiceGrandTotal ();

      for (int i = 0; i < orders.size (); i ++) {
        String itemIdentifier = orders.getItem(i);
        String amountIdentifier = itemIdentifier + "\n(Birr)";
        int quantity = orders.getQuantity(i);
        double total = orders.getTotal (i);

        int prevQuantity = totalQuantities.hasKey (itemIdentifier)? totalQuantities.get (itemIdentifier) : 0;
        float prevTotal = totalAmounts.hasKey (amountIdentifier)? totalAmounts.get (amountIdentifier) : 0;

        totalQuantities.set (itemIdentifier, prevQuantity + quantity);
        totalAmounts.set (amountIdentifier, prevTotal + float (total + ""));

        row.setString (itemIdentifier, nfc (quantity));
        row.setString (amountIdentifier, nfc (float (total + ""), 2));
      }
    }

    // Totals
    report.addRow ();
    TableRow row = report.addRow();
    row.setString ("Partner Name", "TOTAL SALES");

    for (String header : headers) {
      if (totalQuantities.hasKey(header))
        row.setString (header, nfc (totalQuantities.get (header)));
      else if (totalAmounts.hasKey (header))
        row.setString (header, nfc (totalAmounts.get (header), 2));
    }
    row.setString ("Grand Total", nfc (categoryGrandTotal, 2));

    return report;
  }
}
