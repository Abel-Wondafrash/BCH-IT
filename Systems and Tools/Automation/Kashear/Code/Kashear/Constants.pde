static final String KASHEAR_DNA_CONFIG_FILE = "kashear_dna_config.xml";

// General
boolean IS_MODE_DIRECT = true;
int PRICE_DP = 3;
float GRAND_TOTAL_NOMINAL_DELTA = 3;

// Excise Tax
float EXCISE_TAX_PERCENTAGE = 10;
String EXCISE_TAX_ITEM_CODE = "ITM-00002";
String EXCISE_TAX_ITEM_NAME = "Excise TaX";
String EXCISE_TAX_QUANTITY = "1";
String EXCISE_SALE_UOM = "pcs";

// Nomenclature
String SALES_ORDER_PREFIX = "SOV-";
String ATTACHMENT_PREFIX = "ATT-";
String FS_NUMBER_PREFIX = "FS No. ";
String FS_NUMBER_SAMPLE = "00000000";

// DB Details
String DB_NAME = "Testbed";
String DB_IP = "pgserver.local";
String DB_PORT = "5432";
String DB_USER = "openpg";
String DB_PASS = "openpgpwd";

// Odoo Details
String ODOO_IP = "pgserver.local";
String ODOO_PORT = "8069";
String KASHEAR_ODOO_EMAIL = "ka.shear";
String KASHEAR_ODOO_PASS  = "K4$H34r";

// Attachment
int FILE_CREATION_TIMEOUT = 5000;
boolean AUTO_CLOSE_VOUCHER_SAVED_MODAL = true;
boolean AUTO_CLOSE_PRINT_DIALOG = true;

void updateConstantsWithConfig (MainConfigurations config) {
  // General
  IS_MODE_DIRECT = config.isModeDirect();
  PRICE_DP = config.getPriceDp();
  GRAND_TOTAL_NOMINAL_DELTA = config.getGrandTotalNominalDelta();
  
  // Taxation
  EXCISE_TAX_PERCENTAGE = config.getExciseTaxPercentage();
  EXCISE_TAX_ITEM_CODE = config.getExciseTaxItemCode();
  EXCISE_TAX_ITEM_NAME = config.getExciseTaxItemName();
  EXCISE_TAX_QUANTITY = config.getExciseTaxQuantity();
  EXCISE_SALE_UOM = config.getExciseSaleUom();
  
  // Nomenclature
  SALES_ORDER_PREFIX = config.getSalesOrderPrefix();
  ATTACHMENT_PREFIX = config.getAttachmentPrefix();
  FS_NUMBER_PREFIX = config.getFsNumberPrefix();
  FS_NUMBER_SAMPLE = config.getFsNumberSample();
  
  // DB Details
  DB_NAME = config.getDbName();
  DB_IP = config.getDbIp();
  DB_PORT = config.getDbPort();
  DB_USER = config.getDbUser();
  DB_PASS = config.getDbPass();
  
  // Odoo Details
  ODOO_IP = config.getOdooIp();
  ODOO_PORT = config.getOdooPort();
  KASHEAR_ODOO_EMAIL = config.getKashearOdooEmail();
  KASHEAR_ODOO_PASS = config.getKashearOdooPass();
  
  // QR Scanner
  //--> Updated in setup ()
  
  // Attachment
  FILE_CREATION_TIMEOUT = config.getFileCreationTimeout();
  //--> Printer name is updated in setup ()
  AUTO_CLOSE_VOUCHER_SAVED_MODAL = config.isAutoCloseVoucherSavedModal();
  AUTO_CLOSE_PRINT_DIALOG = config.isAutoClosePrintDialog();
  
  // Paths
  //--> Updated in setup ()
  
  // Timeouts
  timeouts.set (config.getWinWait(), config.getFieldWait());
}

// Timeouts
class Timeouts {
  int winWait = 5000;
  int fieldWait = 5000;
  
  Timeouts () {
  }
  
  void set (int winWait, int fieldWait) {
    this.winWait = winWait;
    this.fieldWait = fieldWait;
  }
  
  int getWinWait () {
    return winWait;
  }
  int getFieldWait () {
    return fieldWait;
  }
}

class Paths_ {
  String appParentDir;
  String tempDir, tempPath;
  String dnaConfigPath;

  Paths_ () {
    appParentDir = System.getProperty("user.home") + "/AppData/Local/Kashear/";
    tempDir = appParentDir + "temp/";
    tempPath = tempDir + "temp.txt";
    dnaConfigPath = new File (dataPath ("")).getParent () + "/config/" + KASHEAR_DNA_CONFIG_FILE;
  }
}

class Windows {
  static final String mainTitle = "CNET ERP V2016_Sales and Marketing Management System";
  static final String cashSalesVoucher = "Cash Sales Voucher";
  static final String addLineItemModal = "Add Lineitem Error";
  static final String removeLineItemModal = "Remove LineItem";
  static final String voucherSavedModal = "Congratulations!";
  static final String printDialog = "Print Dialog";
}

// jna WinUser constants
class WinMessages {
  static final int WM_SETTEXT = 0x000C;
  static final int WM_GETTEXT = 0x000D;
  static final int WM_COMMAND = 0x0111;
  static final int BM_CLICK   = 0x00F5;
  static final int WM_LBUTTONDOWN = 0x0201;
  static final int WM_LBUTTONUP = 0x0202;
  static final int WM_CLOSE = 0x0010;
}

static class Company {
  static final String TITLE = "TOP BEVERARIES INDUSTRIES AND TRADING";
  static final String TIN = "0001470176";
  static final String VAT = "65441";
  static final String TEL = ""; // +251-112-601617
  static final String FAX = "";
  static final String WEB = ""; // www.topwaterethiopia.com
  static final String EMAIL = ""; // info@topwaterethiopia.com
  static final String POBOX = ""; // 8086
}

import java.util.Arrays;

static final String VALID_DATE_FORMAT = "yyyy-MM-dd";
static final String [] winLabels = {"Customer*", "Remark", "Quantity", "Price", "FS No.", "Add", "Remove", "Cash Sales Voucher No", "MRC No."};
static final String [] winLabelsAll = concat (winLabels, new String [] {"Sub Total", "VAT [15 %]", "Grand Total"});
static final List <String> ORDER_STATE_UNPROCESSED =
  Collections.unmodifiableList(new ArrayList <String> (Arrays.asList (new String [] {"draft", "sale"})));

// Attachment Generator
static final color COL_GRAY = #C8C6C7;
static final color COL_GRAY_DARK = #C0C0C0;
static final float WATERMARK_OPACITY_PERCENTAGE = 0.225;
static final float STROKE_WEIGHT = 0.7;
static final float STROKE_WEIGHT_THICK = 1;
static final float AG_LINE_ITEMS_COL_Xs [] = {24.31, 42.31, 114.4, 333.1, 386.9, 433.7, 494.9, 564.6};
static final float AG_SUMMARY_COL_Xs [] = {333.1, 494.9, 565};

static final int SET_DISPLAY_WIDTH = 1366, SET_DISPLAY_HEIGHT = 768;

// Colors
static int SELECTION_BLUE = -7876885;

static final String APP_NAME = "Kashear_AG";
static final String AG_DATE_TIME_PATTERN = "M/d/yyyy h:mm:ss a";
static final String NFC_BIG_BASE_PATTERN = "#,##0";
static final String AG_SUMMARY_LABELS [] = {"Sub Total", "VAT (15.00%)", "Grand Total"};
static final String GENERATOR_LABELS [] = new String [] {"Customer", "Finance Division"};

// Currency
static final String CURRENCY_NAME_BILL = "Birr";
static final String CURRENCY_NAME_CENTS = "Cents";

// Content Validation
static final String CONTENT_VALIDATION_TYPE_NUMBER = "NUM";
static final String CONTENT_VALIDATION_TYPE_POSITIVE_INTEGER = "INT";
static final String CONTENT_VALIDATION_TYPE_TEXT = "TXT";

static final char serialBufferUntilChar = '\r';

static final int ATTACHMENT_RANDOM_CODE_LENGTH = 20;
