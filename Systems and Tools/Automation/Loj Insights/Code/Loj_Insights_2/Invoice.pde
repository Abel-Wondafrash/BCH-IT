class Invoice {
  String so_code;
  String total;
  String subtotal;
  String tax;
  String warehouse;
  String username;

  Customer customer;

  List <Order> orders;

  Invoice () {
    orders = new ArrayList <Order> ();
  }

  // Adders
  void addOrder (Order order) {
    orders.add (order);
  }

  // Setters
  Invoice setCustomer (Customer customer) {
    this.customer = customer;
    return this;
  }
  Invoice setSOcode (String so_code) {
    this.so_code = so_code;
    return this;
  }
  Invoice setTotal (String total) {
    this.total = total;
    return this;
  }
  Invoice setSubtotal (String subtotal) {
    this.subtotal = subtotal;
    return this;
  }
  Invoice setTax (String tax) {
    this.tax = tax;
    return this;
  }
  Invoice setWarehouse (String warehouse) {
    this.warehouse = warehouse;
    return this;
  }
  Invoice setUsername (String username) {
    this.username = username;
    return this;
  }

  // Getters
  Customer getCustomer () {
    return customer;
  }
  List <Order> getOrders () {
    return orders;
  }
  String getSOcode () {
    return so_code;
  }
  String getTotal () {
    return total;
  }
  String getSubtotal () {
    return subtotal;
  }
  String getTax () {
    return tax;
  }
  String getWarehouse () {
    return warehouse;
  }
  String getUsername () {
    return username;
  }

  boolean isNonTaxable () {
    return Double.parseDouble (getTax()) == 0;
  }
  boolean isValid () {
    for (Order order : orders) if (!order.isValid ()) return false;
    return true;
  }
}
