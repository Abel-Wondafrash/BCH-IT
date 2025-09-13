import java.util.Comparator;
import java.util.List;
import java.util.LinkedHashMap;

class Orders {
  List <Order> orders;

  LinkedHashMap <String, Double []> items;
  Double grandTotal = 0d;

  Orders () {
    items = new LinkedHashMap <String, Double []> ();
    orders = new ArrayList <Order> ();
  }

  void add (List <Order> orders) {
    this.orders.addAll (orders);
  }

  int size () {
    return items.size ();
  }

  String getItem (int index) {
    if (index > items.size () - 1) return null;
    return new ArrayList <String> (items.keySet()).get(index);
  }
  Integer getQuantity (int index) {
    if (index > items.size () - 1) return null;
    Double [] qt = items.get (getItem (index));
    return int (qt [0] + "");
  }
  Double getTotal (int index) {
    if (index > items.size () - 1) return null;
    Double [] qt = items.get (getItem (index));
    return qt [1];
  }
  Double getGrandTotal () {
    return grandTotal;
  }

  void summarize () {
    items.clear ();
    grandTotal = 0d;

    for (Order order : orders) {
      if (order.getSalesQuantity() == null) println (">>", order.getItemName (), order.getSalesQuantity(), order.getUnitQuantity());
      String item = order.getShorthandItemName () == null? order.getItemName () : order.getShorthandItemName ();
      double quantity = Double.parseDouble(order.getSalesQuantity() + "");
      double total = Double.parseDouble(order.getTotalPrice ());

      if (!items.containsKey (item)) items.put (item, new Double [] {0d, 0d});

      items.get (item) [0] += quantity;
      items.get (item) [1] += total;
      items.put (item, items.get (item));

      grandTotal += total;
    }
  }
}

class Order {
  String itemName;
  String shorthandItemName;
  String salesUOM;
  String salesQuantity;
  String unitQuantity;
  String unitPrice;
  String bundlePrice;
  String subtotal;
  String taxAmount;
  String totalPrice;

  Order () {
  }

  // Setters
  Order setItemName (String itemName) {
    this.itemName = itemName;
    return this;
  }
  Order setShorthandItemName (String shorthandItemName) {
    this.shorthandItemName = shorthandItemName;
    return this;
  }
  Order setSalesUOM (String salesUOM) {
    this.salesUOM = salesUOM;
    return this;
  }
  Order setSalesQuantity (String salesQuantity) {
    this.salesQuantity = salesQuantity;
    return this;
  }
  Order setUnitQuantity (String unitQuantity) {
    this.unitQuantity = unitQuantity;
    return this;
  }
  Order setUnitPrice (String unitPrice) {
    this.unitPrice = unitPrice;
    return this;
  }
  Order setBundlePrice (String bundlePrice) {
    this.bundlePrice = bundlePrice;
    return this;
  }
  Order setSubtotal (String subtotal) {
    this.subtotal = subtotal;
    return this;
  }
  Order setTaxAmount (String taxAmount) {
    this.taxAmount = taxAmount;
    return this;
  }
  Order setTotalPrice (String totalPrice) {
    this.totalPrice = totalPrice;
    return this;
  }

  // Getters
  public String getItemName() {
    return itemName;
  }
  public String getShorthandItemName() {
    return shorthandItemName;
  }
  public String getSalesUOM() {
    return salesUOM;
  }
  public String getSalesQuantity() {
    return salesQuantity;
  }
  public String getUnitQuantity() {
    return unitQuantity;
  }
  public String getUnitPrice() {
    return unitPrice;
  }
  public String getBundlePrice() {
    return bundlePrice;
  }
  public String getSubtotal() {
    return subtotal;
  }
  public String getTaxAmount() {
    return taxAmount;
  }
  public String getTotalPrice() {
    return totalPrice;
  }

  boolean isValid () {
    return itemName != null && salesQuantity != null && totalPrice != null;
  }
}
