import org.w3c.dom.*;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.File;

public class MainConfigurations {
  private String xmlFilePath;
  private Document document;

  public MainConfigurations(String xmlFilePath) {
    this.xmlFilePath = xmlFilePath;
  }
  
  boolean init () {
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
    } 
    catch (Exception e) {
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

  // ==== GENERAL ====
  public boolean isModeDirect() { 
    return Boolean.parseBoolean(getTagValue("is_mode_direct", "general"));
  }
  public int getPriceDp() { 
    return Integer.parseInt(getTagValue("price_dp", "general"));
  }
  public float getGrandTotalNominalDelta() { 
    return Float.parseFloat(getTagValue("grand_total_nominal_delta", "general"));
  }

  // ==== TAXATION ====
  public float getExciseTaxPercentage() { 
    return Float.parseFloat(getTagValue("excise_tax_percentage", "taxation"));
  }
  public String getExciseTaxItemCode() { 
    return getTagValue("excise_tax_item_code", "taxation");
  }
  public String getExciseTaxItemName() { 
    return getTagValue("excise_tax_item_name", "taxation");
  }
  public String getExciseTaxQuantity() { 
    return getTagValue("excise_tax_quantity", "taxation");
  }
  public String getExciseSaleUom() { 
    return getTagValue("excise_sale_uom", "taxation");
  }

  // ==== NOMENCLATURE ====
  public String getSalesOrderPrefix() { 
    return getTagValue("sales_order_prefix", "nomenclature");
  }
  public String getAttachmentPrefix() { 
    return getTagValue("attachment_prefix", "nomenclature");
  }
  public String getFsNumberPrefix() { 
    return getTagValue("fs_number_prefix", "nomenclature");
  }
  public String getFsNumberSample() { 
    return getTagValue("fs_number_sample", "nomenclature");
  }

  // ==== DB DETAILS ====
  public String getDbName() { 
    return getTagValue("db_name", "db_details");
  }
  public String getDbIp() { 
    return getTagValue("db_ip", "db_details");
  }
  public String getDbPort() { 
    return getTagValue("db_port", "db_details");
  }
  public String getDbUser() { 
    return getTagValue("db_user", "db_details");
  }
  public String getDbPass() { 
    return getTagValue("db_pass", "db_details");
  }

  // ==== ODOO DETAILS ====
  public String getOdooIp() { 
    return getTagValue("odoo_ip", "odoo_details");
  }
  public String getOdooPort() { 
    return getTagValue("odoo_port", "odoo_details");
  }
  public String getKashearOdooEmail() { 
    return getTagValue("kashear_odoo_email", "odoo_details");
  }
  public String getKashearOdooPass() { 
    return getTagValue("kashear_odoo_pass", "odoo_details");
  }

  // ==== QR SCANNER ====
  public String getQrScannerPort() { 
    return getTagValue("qr_scanner_port", "qr_scanner");
  }
  public int getQrScannerBaudRate() { 
    return Integer.parseInt(getTagValue("qr_scanner_baud_rate", "qr_scanner"));
  }

  // ==== ATTACHMENT ====
  public int getFileCreationTimeout() { 
    return Integer.parseInt(getTagValue("file_creation_timeout", "attachment"));
  }
  public String getAttachmentPrinterName() { 
    return getTagValue("attachment_printer_name", "attachment");
  }
  public boolean isAutoCloseVoucherSavedModal() { 
    return Boolean.parseBoolean(getTagValue("auto_close_voucher_saved_modal", "attachment"));
  }
  public boolean isAutoClosePrintDialog() { 
    return Boolean.parseBoolean(getTagValue("auto_close_print_dialog", "attachment"));
  }

  // ==== PATHS ====
  public String getResPath() { 
    return getTagValue("res_path", "paths");
  }
  public String getQueryGetQuotationDetailsPath() { 
    return getTagValue("query_get_quotation_details_path", "paths");
  }
  public String getQueryGetClientOrderRefByCode() { 
    return getTagValue("query_get_client_order_ref_by_code", "paths");
  }
  public String getQuerySetClientOrderRefByCode() { 
    return getTagValue("query_set_client_order_ref_by_code", "paths");
  }
  public String getQueryGetPartnerActiveOrdersByCode() { 
    return getTagValue("query_get_partner_active_orders_by_code", "paths");
  }

  // ==== TIMEOUTS ====
  public int getWinWait() { 
    return Integer.parseInt(getTagValue("win_wait", "timeouts"));
  }
  public int getFieldWait() { 
    return Integer.parseInt(getTagValue("field_wait", "timeouts"));
  }

  boolean validateConfig() {
    StringBuilder missing = new StringBuilder();

    // ==== GENERAL ====
    if (getTagValue("is_mode_direct", "general") == null) missing.append("general/is_mode_direct\n");
    if (getTagValue("price_dp", "general") == null) missing.append("general/price_dp\n");
    if (getTagValue("grand_total_nominal_delta", "general") == null) missing.append("general/grand_total_nominal_delta\n");

    // ==== TAXATION ====
    if (getTagValue("excise_tax_percentage", "taxation") == null) missing.append("taxation/excise_tax_percentage\n");
    if (getTagValue("excise_tax_item_code", "taxation") == null) missing.append("taxation/excise_tax_item_code\n");
    if (getTagValue("excise_tax_item_name", "taxation") == null) missing.append("taxation/excise_tax_item_name\n");
    if (getTagValue("excise_tax_quantity", "taxation") == null) missing.append("taxation/excise_tax_quantity\n");
    if (getTagValue("excise_sale_uom", "taxation") == null) missing.append("taxation/excise_sale_uom\n");

    // ==== NOMENCLATURE ====
    if (getTagValue("sales_order_prefix", "nomenclature") == null) missing.append("nomenclature/sales_order_prefix\n");
    if (getTagValue("attachment_prefix", "nomenclature") == null) missing.append("nomenclature/attachment_prefix\n");
    if (getTagValue("fs_number_prefix", "nomenclature") == null) missing.append("nomenclature/fs_number_prefix\n");
    if (getTagValue("fs_number_sample", "nomenclature") == null) missing.append("nomenclature/fs_number_sample\n");

    // ==== DB DETAILS ====
    if (getTagValue("db_name", "db_details") == null) missing.append("db_details/db_name\n");
    if (getTagValue("db_ip", "db_details") == null) missing.append("db_details/db_ip\n");
    if (getTagValue("db_port", "db_details") == null) missing.append("db_details/db_port\n");
    if (getTagValue("db_user", "db_details") == null) missing.append("db_details/db_user\n");
    if (getTagValue("db_pass", "db_details") == null) missing.append("db_details/db_pass\n");

    // ==== ODOO DETAILS ====
    if (getTagValue("odoo_ip", "odoo_details") == null) missing.append("odoo_details/odoo_ip\n");
    if (getTagValue("odoo_port", "odoo_details") == null) missing.append("odoo_details/odoo_port\n");
    if (getTagValue("kashear_odoo_email", "odoo_details") == null) missing.append("odoo_details/kashear_odoo_email\n");
    if (getTagValue("kashear_odoo_pass", "odoo_details") == null) missing.append("odoo_details/kashear_odoo_pass\n");

    // ==== QR SCANNER ====
    if (getTagValue("qr_scanner_port", "qr_scanner") == null) missing.append("qr_scanner/qr_scanner_port\n");
    if (getTagValue("qr_scanner_baud_rate", "qr_scanner") == null) missing.append("qr_scanner/qr_scanner_baud_rate\n");

    // ==== ATTACHMENT ====
    if (getTagValue("file_creation_timeout", "attachment") == null) missing.append("attachment/file_creation_timeout\n");
    if (getTagValue("attachment_printer_name", "attachment") == null) missing.append("attachment/attachment_printer_name\n");
    if (getTagValue("auto_close_voucher_saved_modal", "attachment") == null) missing.append("attachment/auto_close_voucher_saved_modal\n");
    if (getTagValue("auto_close_print_dialog", "attachment") == null) missing.append("attachment/auto_close_print_dialog\n");

    // ==== PATHS ====
    if (getTagValue("res_path", "paths") == null) missing.append("paths/res_path\n");
    if (getTagValue("query_get_quotation_details_path", "paths") == null) missing.append("paths/query_get_quotation_details_path\n");
    if (getTagValue("query_get_client_order_ref_by_code", "paths") == null) missing.append("paths/query_get_client_order_ref_by_code\n");
    if (getTagValue("query_set_client_order_ref_by_code", "paths") == null) missing.append("paths/query_set_client_order_ref_by_code\n");
    if (getTagValue("query_get_partner_active_orders_by_code", "paths") == null) missing.append("paths/query_get_partner_active_orders_by_code\n");

    // ==== TIMEOUTS ====
    if (getTagValue("win_wait", "timeouts") == null) missing.append("timeouts/win_wait\n");
    if (getTagValue("field_wait", "timeouts") == null) missing.append("timeouts/field_wait\n");

    if (missing.length() > 0) {
      showCMDerror("MISSING_TAGS", "The following tags are missing:\n" + missing.toString());
      return false;
    }

    return true;
  }
}

public class KashearDNAconfig {
  private final String xmlFilePath;
  private String kashearConfigPath;

  public KashearDNAconfig(String xmlFilePath) {
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
      if (node != null) kashearConfigPath = node.getTextContent().trim();
      else showCMDerror("MISSING_TAG", "Missing <config_file_path> in local config");

      return true;
    } 
    catch (Exception e) {
      showCMDerror("FAILED_TO_LOAD_LOCAL_CONFIG", e.getMessage());
      return false;
    }
  }

  public String getKashearConfigPath() {
    return kashearConfigPath;
  }
}
