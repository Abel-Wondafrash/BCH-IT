import java.util.LinkedHashMap;

public class Issuers {
  // Inner class representing an Issuer
  LinkedHashMap <String, PShape> pairs;
  String xmlFilePath;
  String errors;

  public class Issuer {
    private String name;
    private String signPath;
    private PShape signature;

    // Constructor for easier instantiation
    public Issuer(String name, String signPath) {
      this.name = name;
      this.signPath = signPath;
    }

    // Getters
    public String getName() {
      return name;
    }
    public String getSignPath() {
      return signPath;
    }
    public PShape getSignature () {
      return signature;
    }

    // Setters
    public void setSignature (PShape signature) {
      this.signature = signature;
      pairs.put (name, signature);
    }
  }

  // Main field: List of Issuers
  private List<Issuer> issuers;

  // Constructor
  public Issuers(String xmlFilePath) {
    this.issuers = new ArrayList<Issuer>();
    pairs = new LinkedHashMap <String, PShape> ();
    setPath (xmlFilePath);
  }

  boolean init () {
    errors = "";
    
    if (!new File (xmlFilePath).exists ()) {
      showCMDerror (Error.MISSING_ISSUERS_DETAILS);
      return false;
    }
    
    for (Issuer issuer : getIssuers()) {
      String signPath = issuer.getSignPath ();
      String issuerName = issuer.getName();
      if (signPath == null || issuerName == null || issuerName.isEmpty()) continue;
      
      File signFile = new File (signPath);
      if (!signFile.exists ()) continue;

      try {
        PShape signature = loadShape (signFile.getAbsolutePath ());
        signature.disableStyle ();
        issuer.setSignature (signature);
      } 
      catch (Exception e) {
        errors += "Error trying to loadShape (" + signFile.getAbsolutePath () + "):" + e + "\n";
      }
    }
    
    if (size () == 0) errors += "\nNO ISSUER FOUND";
    else if (size () < getIssuers ().size ()) errors += "\nSOME ISSUER'S DETAILS ARE MISSING, INCORRECT, OR SIGNATURE FILES ARE CORRUPTED";
    
    if (errors.isEmpty ()) return true;
    
    showCMDerror (Error.ISSUERS, errors);
    return false;
  }

  int size () {
    return pairs.size ();
  }
  boolean contains (String name) {
    return pairs.containsKey (name);
  }
  PShape getSignature (String name) {
    if (!contains (name)) return null;
    return pairs.get (name);
  }
  String getErrors () {
    return errors;
  }

  // Method to parse the XML and populate the Issuers list
  public void setPath(String xmlFilePath) {
    this.xmlFilePath = xmlFilePath;
    
    try {
      File file = new File(xmlFilePath);
      DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      DocumentBuilder builder = factory.newDocumentBuilder();
      Document document = builder.parse(file);
      document.getDocumentElement().normalize();

      // Parse all Issuers
      NodeList issuerNodes = document.getElementsByTagName("Issuers");
      for (int i = 0; i < issuerNodes.getLength(); i++) {
        Node issuerNode = issuerNodes.item(i);
        if (issuerNode != null && issuerNode.getNodeType() == Node.ELEMENT_NODE) {
          org.w3c.dom.Element issuerElement = (org.w3c.dom.Element) issuerNode;
          String name = getTagValue("name", issuerElement);
          String signPath = getTagValue("sign_path", issuerElement);
          this.issuers.add(new Issuer(name, signPath));
        }
      }
    } 
    catch (Exception e) {
      cLogger.log (e.toString ());
      e.printStackTrace();
    }
  }

  // Helper method to get text content of a tag
  private String getTagValue(String tag, org.w3c.dom.Element element) {
    NodeList nodeList = element.getElementsByTagName(tag);
    if (nodeList != null && nodeList.getLength() > 0) {
      Node node = nodeList.item(0);
      if (node != null) {
        return node.getTextContent().trim();
      }
    }
    return null;
  }

  // Getter for the Issuers list
  public List<Issuer> getIssuers() {
    return issuers;
  }
}
