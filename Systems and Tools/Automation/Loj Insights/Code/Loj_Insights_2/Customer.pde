class Customer {
  String name;
  String code;
  String tin;
  String phone;
  String location;
  
  List <Invoice> invoices;
  
  float invoiceGrandTotal;

  Customer () {
    invoices = new ArrayList <Invoice> ();
  }

  // Adders
  void addInvoice (Invoice invoice) {
    invoices.add (invoice);
    invoiceGrandTotal += Double.parseDouble (invoice.getTotal());
  }

  // Setters
  Customer setName (String name) {
    this.name = name.trim ().toUpperCase();
    return this;
  }
  Customer setCode (String code) {
    this.code = code.trim ().toUpperCase();
    return this;
  }
  Customer setTIN (String tin) {
    if (tin == null) return this;
    this.tin = tin.trim ().toUpperCase();
    return this;
  }
  Customer setPhone (String phone) {
    if (phone == null) return this;
    this.phone = phone.trim ().toUpperCase();
    return this;
  }
  Customer setLocation (String location) {
    if (location == null) return this;
    this.location = location.trim ().toUpperCase();
    return this;
  }

  // Getters
  List <Invoice> getInvoices () {
    return invoices;
  }
  float getInvoiceGrandTotal () {
    return invoiceGrandTotal;
  }
  String getName () {
    return name;
  }
  String getCode () {
    return code;
  }
  String getTIN () {
    return tin;
  }
  String getPhone () {
    return phone;
  }
  String getLocation () {
    return location;
  }
}
