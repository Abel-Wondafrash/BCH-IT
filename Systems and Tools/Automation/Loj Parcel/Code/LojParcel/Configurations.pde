public class DNAconfig {
  private final String xmlFilePath;
  private String configPath;

  public DNAconfig(String xmlFilePath) {
    this.xmlFilePath = xmlFilePath;
  }
  
  boolean init () {
    return loadConfig();
  }

  boolean loadConfig() {
    try {
      File file = new File(xmlFilePath);
      if (!file.exists()) {
        showCMDerror("MISSING_LOCAL_CONFIG", "Local config file not found at: " + xmlFilePath);
        return false;
      }

      DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      DocumentBuilder builder = factory.newDocumentBuilder();
      Document document = builder.parse(file);
      document.getDocumentElement().normalize();

      Node node = document.getElementsByTagName("config_file_path").item(0);
      if (node != null) configPath = node.getTextContent().trim();
      else showCMDerror("MISSING_TAG", "Missing <config_file_path> in local config");

      return true;
    } 
    catch (Exception e) {
      showCMDerror("FAILED_TO_LOAD_LOCAL_CONFIG", e.getMessage());
      return false;
    }
  }

  public String getConfigPath() {
    return configPath;
  }
}

public class MainConfigurations {
  private String xmlFilePath;
  private Document document;

  public MainConfigurations(String xmlFilePath) {
    this.xmlFilePath = xmlFilePath;
  }

  boolean init() {
    return loadConfig() && validateConfig();
  }

  boolean loadConfig() {
    try {
      File file = new File(xmlFilePath);
      if (!file.exists()) {
        showCMDerror("MISSING_MAIN_CONFIG", "Config file not found at: " + xmlFilePath);
        return false;
      }

      DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      DocumentBuilder builder = factory.newDocumentBuilder();
      document = builder.parse(file);
      document.getDocumentElement().normalize();

      return true;
    } catch (Exception e) {
      showCMDerror("FAILED_TO_LOAD_MAIN_CONFIG", e.getMessage());
      return false;
    }
  }

  private String getTagValue(String tag, String section) {
    if (document == null) return null; // safeguard if config not loaded
    Node sectionNode = document.getElementsByTagName(section).item(0);
    if (sectionNode != null && sectionNode.getNodeType() == Node.ELEMENT_NODE) {
      org.w3c.dom.Element sectionElement = (org.w3c.dom.Element) sectionNode;
      NodeList nodeList = sectionElement.getElementsByTagName(tag);
      if (nodeList != null && nodeList.getLength() > 0) {
        Node node = nodeList.item(0);
        return node.getTextContent().trim();
      }
    }
    return null;
  }

  // ==== SLIP ====
  public String getSlipPrinterName() {
    return getTagValue("slip_printer_name", "slip");
  }

  // ==== PATHS ====
  public String getResPath() {
    return getTagValue("res_path", "paths");
  }

  public String getXmlTargetPath() {
    return getTagValue("xml_target_path", "paths");
  }

  boolean validateConfig() {
    StringBuilder missing = new StringBuilder();

    // ==== SLIP ====
    if (getTagValue("slip_printer_name", "slip") == null)
      missing.append("slip/slip_printer_name\n");

    // ==== PATHS ====
    if (getTagValue("res_path", "paths") == null)
      missing.append("paths/res_path\n");
    if (getTagValue("xml_target_path", "paths") == null)
      missing.append("paths/xml_target_path\n");

    if (missing.length() > 0) {
      showCMDerror("MISSING_TAGS", "The following tags are missing:\n" + missing.toString());
      return false;
    }

    return true;
  }
}
