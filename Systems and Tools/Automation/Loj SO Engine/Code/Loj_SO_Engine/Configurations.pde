public class Configurations {
  String xmlFilePath;

  // Inner class representing Preferences
  public class Preferences {
    private String xmlListenPath;
    private String xmlArchivePath;
    private String destPath;
    private String loggerRootPath;
    private String cLoggerRootPath;
    private String selectedPrinterName;

    // Getters
    public String getXmlListenPath() {
      return xmlListenPath;
    }
    public String getXmlArchivePath () {
      return xmlArchivePath;
    }
    public String getDestPath() {
      return destPath;
    }
    public String getLoggerRootPath () {
      return loggerRootPath;
    }
    public String getCloggerRootPath () {
      return cLoggerRootPath;
    }
    public String getSelectedPrinterName () {
      return selectedPrinterName;
    }
  }

  // Main fields of LojServerConfig
  private Preferences preferences;

  // Constructor
  public Configurations(String xmlFilePath) {
    this.preferences = new Preferences();
    setPath (xmlFilePath);
  }

  boolean init () {
    // Preferences Path
    if (!exists ()) {
      showCMDerror (Error.MISSING_SERVER_PREFERENCES);
      return false;
    }

    // XML Listening Path: Missing
    String xmlListeningPath = getPreferences().getXmlListenPath();
    if (xmlListeningPath == null) {
      showCMDerror (Error.XML_LISTENING_PATH_NOT_SET, "XML Listening Path is NOT SET. Check XML Integrity.");
      return false;
    }
    // XML Listening Path: Does NOT Exist
    if (!new File (xmlListeningPath).exists ()) {
      showCMDerror (Error.MISSING_XML_LISTENING_PATH, "XML Listening Path/Dir does NOT EXIST");
      return false;
    }

    // Destination Path: Not set
    String destinationPath = getPreferences ().getDestPath();
    if (destinationPath == null) {
      showCMDerror (Error.DESTINATION_NOT_SET, "Destination Path is NOT SET. Check XML Integrity.");
      return false;
    }

    return true;
  }

  // Method to parse the XML and populate the fields
  public void setPath(String xmlFilePath) {
    this.xmlFilePath = xmlFilePath;

    try {
      File file = new File(xmlFilePath);
      DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      DocumentBuilder builder = factory.newDocumentBuilder();
      Document document = builder.parse(file);
      document.getDocumentElement().normalize();

      // Parse Preferences
      Node preferencesNode = document.getElementsByTagName("Preferences").item(0);
      if (preferencesNode != null && preferencesNode.getNodeType() == Node.ELEMENT_NODE) {
        org.w3c.dom.Element preferencesElement = (org.w3c.dom.Element) preferencesNode;
        this.preferences.xmlListenPath = getTagValue("xml_listen_path", preferencesElement);
        this.preferences.xmlArchivePath = getTagValue("xml_archive_path", preferencesElement);
        this.preferences.destPath = getTagValue("dest_path", preferencesElement);
        this.preferences.loggerRootPath = getTagValue("log_root_path", preferencesElement);
        this.preferences.cLoggerRootPath = getTagValue("c_log_root_path", preferencesElement);
        this.preferences.selectedPrinterName = getTagValue("selected_printer_name", preferencesElement);
      }
    } 
    catch (Exception e) {
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

  boolean exists () {
    return new File (xmlFilePath).exists ();
  }

  // Getter for Preferences
  public Preferences getPreferences() {
    return preferences;
  }
}
