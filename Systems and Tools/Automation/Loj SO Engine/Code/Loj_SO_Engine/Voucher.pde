import org.w3c.dom.*;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.xml.sax.InputSource;

public class Voucher {
  public class Customer {
    private String code;
    private String name;
    private String location;
    private String address;
    private String tin;

    // Getters
    public String getCode() {
      return code;
    }
    public String getName() {
      return name;
    }
    public String getLocation () {
      return location;
    }
    public String getAddress() {
      return address;
    }
    public String getTIN() {
      return tin;
    }
  }

  public class Order {
    private String uom;
    private int pack;
    private int quantity;
    private String unitPrice;
    private String subtotal;
    private String taxType;
    private String taxAmount;
    private String totalAmount;
    private String itemCode;
    private String itemName;
    private String itemCategory;
    private float discount;
    private float additionalCharge;

    // Getters
    public String getUoM () {
      return uom;
    }
    public int getPack() {
      return pack;
    }
    public int getQuantity() {
      return quantity;
    }
    public String getUnitPrice() {
      return unitPrice;
    }
    public String getSubtotal() {
      return subtotal;
    }
    public String getTaxType() {
      return taxType;
    }
    public String getTaxAmount() {
      return taxAmount;
    }
    public String getTotalAmount() {
      return totalAmount;
    }
    public String getItemCode() {
      return itemCode;
    }
    public String getItemName() {
      return itemName;
    }
    public String getItemCategory() {
      return itemCategory;
    }
    public float getDiscount() {
      return discount;
    }
    public float getAdditionalCharge() {
      return additionalCharge;
    }
  }

  public class VoucherDetails {
    private float discount;
    private float additionalCharge;
    private float subTotal;
    private float taxTotal;
    private float grandTotal;

    // Getters
    public float getDiscount() {
      return discount;
    }
    public float getAdditionalCharge() {
      return additionalCharge;
    }
    public float getSubtotal() {
      return subTotal;
    }
    public float getTaxTotal() {
      return taxTotal;
    }
    public float getGrandTotal() {
      return grandTotal;
    }
  }

  public class Activity {
    private String deviceName;
    private String employeeCode;
    private String issuerName;
    private String userName;

    // Getters
    public String getDeviceName() {
      return deviceName;
    }
    public String getEmployeeCode() {
      return employeeCode;
    }
    public String getIssuerName() {
      return issuerName;
    }
    public String getUsername() {
      return userName;
    }
  }

  // Main fields of the Voucher
  private String copies;
  private String copy_type;
  private String code;
  private String codeNumber;
  private String date;
  private String reference;
  private String dateQuoted;
  private String timeQuoted;
  private String salesperson;
  private String plateNumber;
  private String stock;
  private String paymentTerm;

  private Customer customer;
  private List<Order> orders;
  private VoucherDetails voucherValues;
  private Activity activity;

  // Constructor
  public Voucher() {
    customer = new Customer ();
    this.orders = new ArrayList<Order>();
  }

  // Method to parse XML and populate the fields
  public Voucher get (String xmlFilePath) {
    NullValidator nullValidator = new NullValidator ();
    try {
      // Read file content and replace invalid UTF-8 characters
      byte[] bytes = Files.readAllBytes(Paths.get(xmlFilePath));
      String content = new String(bytes, StandardCharsets.UTF_8)
        .replaceAll("[^\u0000-\uFFFF]", "?"); // Replace non-UTF-8 chars with ?

      // Basic pre-parsing check for incomplete XML
      if (!content.contains("<Voucher>") || !content.contains("</Voucher>")) {
        System.err.println("Invalid XML: Missing Voucher root element in: " + xmlFilePath);
        cLogger.log ("Invalid XML: Missing Voucher root element in: " + xmlFilePath);
        return null;
      }

      // Parse cleaned content
      DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      DocumentBuilder builder = factory.newDocumentBuilder();
      InputSource inputSource = new InputSource(new StringReader(content));
      Document document;
      try {
        document = builder.parse(inputSource);
        document.getDocumentElement().normalize();
      } 
      catch (SAXException e) {
        System.err.println("Malformed or incomplete XML in: " + xmlFilePath + ". Error: " + e.getMessage());
        cLogger.log ("Malformed or incomplete XML in: " + xmlFilePath + ". Error: " + e.getMessage());
        return null;
      }

      // Parse Voucher
      Node voucherNode = document.getElementsByTagName("Voucher").item(0);
      if (voucherNode == null) return null;

      if (voucherNode.getNodeType() == Node.ELEMENT_NODE) {
        org.w3c.dom.Element voucherElement = (org.w3c.dom.Element) voucherNode;

        boolean containsNull = nullValidator.clear ()
          .add ("voucher copies", getTagValue("copies", voucherElement))
          .add ("voucher code", getTagValue("code", voucherElement))
          .add ("voucher date", getTagValue("date", voucherElement))
          //.add (getTagValue("reference", voucherElement))
          .add ("voucher dateQuoted", getTagValue("dateQuoted", voucherElement))
          .add ("voucher salesperson", getTagValue("salesperson", voucherElement))
          .add ("voucher plateNumber", getTagValue("plateNumber", voucherElement))
          .add ("voucher stock", getTagValue("stock", voucherElement))
          .add ("voucher paymentTerm", getTagValue("paymentTerm", voucherElement))
          .containsNull ();

        if (containsNull) {
          println ("Null element found -1");
          printArray (nullValidator.getNullTags ());
          cLogger.log ("Null element found -1");
          for (String nullTag : nullValidator.getNullTags ()) cLogger.log (nullTag);
          return null;
        }

        this.copies = getTagValue("copies", voucherElement);
        this.copy_type = getTagValue("copy_type", voucherElement);
        this.code = getTagValue("code", voucherElement);
        this.codeNumber = split (this.code, "-") [1];
        this.date = getTagValue("date", voucherElement);
        this.reference = getTagValue("reference", voucherElement);
        this.reference = this.reference == null? "-" : this.reference.replace (" ", "").trim ();

        String dateTime = getTagValue("dateQuoted", voucherElement);
        String split [] = split (dateTime, " ");
        this.dateQuoted = split [0];
        this.timeQuoted = split [1];

        this.salesperson = getTagValue("salesperson", voucherElement);
        this.plateNumber = getTagValue("plateNumber", voucherElement);
        this.stock = getTagValue("stock", voucherElement);
        this.paymentTerm = getTagValue("paymentTerm", voucherElement);

        // Parse Customer
        org.w3c.dom.Element customerElement = (org.w3c.dom.Element) voucherElement.getElementsByTagName("customer").item(0);
        if (customerElement != null) {
          containsNull = nullValidator.clear ()
            .add ("customer code", getTagValue("code", customerElement))
            .add ("customer name", getTagValue("name", customerElement))
            .add ("customer location", getTagValue("location", customerElement))
            .containsNull ();
          if (containsNull) {
            println ("Null Element Found 0");
            printArray (nullValidator.getNullTags ());
            cLogger.log ("Null Element Found 0");
            for (String nullTag : nullValidator.getNullTags ()) cLogger.log (nullTag);
            return null;
          }
          this.customer = new Customer();
          this.customer.code = getTagValue("code", customerElement);
          this.customer.name = getTagValue("name", customerElement);
          this.customer.location = getTagValue("location", customerElement);
          this.customer.address = getTagValue("address", customerElement);
          this.customer.tin = getTagValue("TIN", customerElement);
        }
      }

      // Parse LineItem
      NodeList lineItemNodes = document.getElementsByTagName("LineItem");
      for (int i = 0; i < lineItemNodes.getLength(); i++) {
        Node lineItemNode = lineItemNodes.item(i);
        if (lineItemNode != null && lineItemNode.getNodeType() == Node.ELEMENT_NODE) {
          org.w3c.dom.Element lineItemElement = (org.w3c.dom.Element) lineItemNode;
          Order order = new Order();
          boolean containsNull = nullValidator.clear ()
            .add ("order " + (i + 1) + " uom", getTagValue("uom", lineItemElement))
            .add ("order " + (i + 1) + " pack", getTagValue("pack", lineItemElement))
            .add ("order " + (i + 1) + " quantity", getTagValue("quantity", lineItemElement))
            .add ("order " + (i + 1) + " unitPrice", getTagValue("unitPrice", lineItemElement))
            .add ("order " + (i + 1) + " subtotal", getTagValue("subtotal", lineItemElement))
            .add ("order " + (i + 1) + " totalAmount", getTagValue("totalAmount", lineItemElement))
            .containsNull();
          if (containsNull) {
            println ("Null Element Found 1");
            printArray (nullValidator.getNullTags ());
            cLogger.log ("Null Element Found 1");
            for (String nullTag : nullValidator.getNullTags ()) cLogger.log (nullTag);
            return null;
          }

          order.uom = getTagValue("uom", lineItemElement);
          order.pack = int(getTagValue("pack", lineItemElement));
          order.quantity = int (getTagValue("quantity", lineItemElement));
          order.unitPrice = getTagValue("unitPrice", lineItemElement);
          order.subtotal = getTagValue("subtotal", lineItemElement);
          order.taxType = getTagValue("taxType", lineItemElement);
          if (order.taxType.equals ("NO_TAX")) order.taxType = null;
          order.taxAmount = getTagValue("taxAmount", lineItemElement);
          order.totalAmount = getTagValue("totalAmount", lineItemElement);

          // Parse Item
          org.w3c.dom.Element itemElement = (org.w3c.dom.Element) lineItemElement.getElementsByTagName("item").item(0);
          if (itemElement != null) {
            containsNull = nullValidator.clear ()
              .add ("order " + (i + 1) + " code", getTagValue("code", itemElement))
              .add ("order " + (i + 1) + " name", getTagValue("name", itemElement))
              .add ("order " + (i + 1) + " category", getTagValue("category", itemElement))
              .containsNull ();

            if (containsNull) {
              println ("Null Element Found 2");
              printArray (nullValidator.getNullTags ());
              cLogger.log ("Null Element Found 2");
              for (String nullTag : nullValidator.getNullTags ()) cLogger.log (nullTag);
              return null;
            }
            order.itemCode = getTagValue("code", itemElement);
            order.itemName = getTagValue("name", itemElement);
            order.itemCategory = getTagValue("category", itemElement);
          }

          // Parse LineItemValues
          org.w3c.dom.Element lineItemValuesElement = (org.w3c.dom.Element) lineItemElement.getElementsByTagName("lineItemValues").item(0);
          if (lineItemValuesElement != null) {
            order.discount = Float.parseFloat (getTagValue("discount", lineItemValuesElement));
            order.additionalCharge = Float.parseFloat (getTagValue("additionalCharge", lineItemValuesElement));
          }

          this.orders.add(order);
        }
      }

      // Parse VoucherValues
      org.w3c.dom.Element voucherValuesElement = (org.w3c.dom.Element) document.getElementsByTagName("voucherValues").item(0);
      if (voucherValuesElement != null) {
        this.voucherValues = new VoucherDetails();

        boolean containsNull = nullValidator.clear ()
          .add ("voucher discount", getTagValue("discount", voucherValuesElement))
          .add ("voucher additionalCharge", getTagValue("additionalCharge", voucherValuesElement))
          .add ("voucher subTotal", getTagValue("subTotal", voucherValuesElement))
          .add ("voucher taxTotal", getTagValue("taxTotal", voucherValuesElement))
          .add ("voucher grandTotal", getTagValue("grandTotal", voucherValuesElement))
          .containsNull ();
        if (containsNull) {
          println ("Null Element Found 3");
          printArray (nullValidator.getNullTags ());
          cLogger.log ("Null Element Found 3");
          for (String nullTag : nullValidator.getNullTags ()) cLogger.log (nullTag);
          return null;
        }

        this.voucherValues.discount = Float.parseFloat (getTagValue("discount", voucherValuesElement));
        this.voucherValues.additionalCharge = Float.parseFloat (getTagValue("additionalCharge", voucherValuesElement));
        this.voucherValues.subTotal = Float.parseFloat (getTagValue("subTotal", voucherValuesElement));
        this.voucherValues.taxTotal = Float.parseFloat (getTagValue("taxTotal", voucherValuesElement));
        this.voucherValues.grandTotal = Float.parseFloat (getTagValue("grandTotal", voucherValuesElement));
      }

      // Parse Activity
      org.w3c.dom.Element activityElement = (org.w3c.dom.Element) document.getElementsByTagName("Activity").item(0);
      if (activityElement != null) {
        this.activity = new Activity();
        this.activity.deviceName = getTagValue("deviceName", activityElement);
        org.w3c.dom.Element userElement = (org.w3c.dom.Element) activityElement.getElementsByTagName("user").item(0);
        if (userElement != null) {
          boolean containsNull = nullValidator.clear ().add ("user fullName", getTagValue("fullName", userElement)).containsNull ();
          if (containsNull) {
            println ("NO FULL NAME IN VOUCHER");
            printArray (nullValidator.getNullTags ());
            cLogger.log ("NO FULL NAME IN VOUCHER");
            for (String nullTag : nullValidator.getNullTags ()) cLogger.log (nullTag);
            return null;
          }

          this.activity.employeeCode = getTagValue("employeeCode", userElement);
          this.activity.issuerName = getTagValue("fullName", userElement);
          this.activity.userName = getTagValue("userName", userElement);
        }
      }

      return this;
    }
    catch (Exception e) {
      cLogger.log (e.toString ());
      e.printStackTrace();
      return null;
    }
  }

  // Helper method to get text content of a tag
  private String getTagValue (String tag, org.w3c.dom.Element element) {
    NodeList nodeList = element.getElementsByTagName(tag);
    if (nodeList != null && nodeList.getLength() > 0) {
      Node node = nodeList.item(0);
      if (node != null) {
        String value = node.getTextContent().replace ("  ", " ").trim ();
        if (value.toLowerCase ().equals ("false")) return null;
        return value;
      }
    }
    return null;
  }

  // Getters for the fields
  public int getCopies () {
    return copies == null || !isValidNum (copies) || int (copies) < 1? DEFAULT_VOUCHER_PRINT_COPIES : int (copies);
  }
  public String getCopyType () {
    return copy_type;
  }
  public String getCode() {
    return code;
  }
  public String getCodeNumber () {
    return codeNumber;
  }
  public String getDate() {
    return date;
  }
  public String getReference() {
    return reference;
  }
  public String getDateQuoted() {
    return dateQuoted;
  }
  public String getTimeQuoted () {
    return timeQuoted;
  }
  public String getSalesperson() {
    return salesperson;
  }
  public String getPlateNumber() {
    return plateNumber;
  }
  public String getSite() {
    return stock;
  }
  public String getSiteNumber () {
    return getDigits (stock);
  }
  public String getPaymentTerm() {
    return paymentTerm;
  }
  public Customer getCustomer() {
    return customer;
  }
  public List<Order> getOrders() {
    return orders;
  }
  public VoucherDetails getVoucherSummary() {
    return voucherValues;
  }
  public Activity getActivity() {
    return activity;
  }

  public boolean hasNoOrders () {
    return getOrders ().isEmpty ();
  }
}
