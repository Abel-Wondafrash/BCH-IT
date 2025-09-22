import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.charset.StandardCharsets;
import org.w3c.dom.*;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

class ParcelParser {
  private String copyType;
  private String batchRef;
  private String stock;
  private String issuerName; // required field
  private boolean valid = false;
  private ArrayList<Voucher> vouchers;

  ParcelParser () {
    vouchers = new ArrayList<Voucher>();
  }

  public boolean parse(String path) {
    vouchers.clear();
    valid = false;
    issuerName = null;

    File file = new File(path);
    if (!file.exists()) {
      println("File does not exist: " + path);
      return false;
    }

    try {
      // Read file as UTF-8 and sanitize
      byte[] bytes = Files.readAllBytes(Paths.get(path));
      String content = new String(bytes, StandardCharsets.UTF_8);
      content = sanitizeXmlString(content);

      // Parse with DOM
      DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
      dbf.setIgnoringComments(true);
      dbf.setIgnoringElementContentWhitespace(true);
      DocumentBuilder db = dbf.newDocumentBuilder();

      Document doc = db.parse(new java.io.ByteArrayInputStream(content.getBytes(StandardCharsets.UTF_8)));
      doc.getDocumentElement().normalize();

      org.w3c.dom.Element root = doc.getDocumentElement();
      if (!root.getNodeName().equals("VoucherXml")) {
        println("Invalid root element: " + root.getNodeName());
        return false;
      }

      copyType = getTagText(root, "copy_type");
      batchRef = getTagText(root, "batch_ref");
      stock = getTagText(root, "stock");

      if (copyType == null || batchRef == null || stock == null) {
        println("Missing required fields: copyType, batchRef, or stock.");
        return false;
      }

      // issuerName (required)
      NodeList activities = root.getElementsByTagName("Activity");
      if (activities.getLength() > 0) {
        org.w3c.dom.Element activity = (org.w3c.dom.Element) activities.item(0);
        NodeList users = activity.getElementsByTagName("user");
        if (users.getLength() > 0) {
          org.w3c.dom.Element user = (org.w3c.dom.Element) users.item(0);
          issuerName = getTagText(user, "fullName");
        }
      }
      if (issuerName == null) {
        println("Missing required field: issuerName.");
        return false;
      }

      // vouchers
      NodeList voucherNodes = root.getElementsByTagName("Voucher");
      for (int i = 0; i < voucherNodes.getLength(); i++) {
        org.w3c.dom.Element v = (org.w3c.dom.Element) voucherNodes.item(i);
        String code = getTagText(v, "code");
        String reference = getTagText(v, "reference");
        String customerName = null;

        NodeList customerNodes = v.getElementsByTagName("customer");
        if (customerNodes.getLength() > 0) {
          org.w3c.dom.Element customer = (org.w3c.dom.Element) customerNodes.item(0);
          customerName = getTagText(customer, "name");
        }

        if (code != null && reference != null && customerName != null) {
          vouchers.add(new Voucher(code, reference, customerName));
        }
      }

      valid = !vouchers.isEmpty();
      return valid;
    } 
    catch (Exception e) {
      println("Error parsing XML: " + e.getMessage());
      return false;
    }
  }

  public boolean isValid() {
    return valid;
  }

  public ArrayList<Voucher> getVouchers() {
    return vouchers;
  }

  public String getCopyType() {
    return copyType;
  }
  public String getBatchReference() {
    return batchRef;
  }
  public String getStock() {
    return stock;
  }
  public String getStockNumber () {
    return getDigits (stock);
  }
  public String getIssuerName() {
    return issuerName;
  }

  // Helpers
  private String getTagText(org.w3c.dom.Element parent, String tag) {
    NodeList list = parent.getElementsByTagName(tag);
    if (list.getLength() > 0) {
      Node n = list.item(0);
      return n.getTextContent().trim();
    }
    return null;
  }

  private String sanitizeXmlString(String input) {
    return input.replaceAll(
      "[^\\u0009\\u000A\\u000D\\u0020-\\uD7FF\\uE000-\\uFFFD]", 
      "?"
      );
  }
}

// Voucher class with getters
class Voucher {
  private String code;
  private String reference;
  private String customerName;

  Voucher(String code, String reference, String customerName) {
    this.code = code;
    this.reference = reference;
    this.customerName = customerName;
  }

  public String getCode() {
    return code;
  }
  public String getReference() {
    return reference;
  }
  public String getReferenceNumber () {
    return getDigits (reference);
  }
  public String getCustomerName() {
    return customerName;
  }
}
