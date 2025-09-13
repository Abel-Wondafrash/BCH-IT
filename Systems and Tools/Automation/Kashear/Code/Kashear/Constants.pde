import java.util.Arrays;

static final String VALID_DATE_FORMAT = "yyyy-MM-dd";
static final String CONTROL_TEXT = "POSpal";
static final String [] winLabels = {"Customer*", "Remark", "Quantity", "Price", "FS No.", "Add", "Remove", "Cash Sales Voucher No", "MRC No."};
static final String [] winLabelsAll = concat (winLabels, new String [] {"Sub Total", "VAT [15 %]", "Grand Total"});
static final List <String> ORDER_STATE_UNPROCESSED =
  Collections.unmodifiableList(new ArrayList <String> (Arrays.asList (new String [] {"draft", "sale"})));

// Entry
static final float EXCISE_TAX_PERCENTAGE = 10;
static final int PRICE_DP = 3;
static final int SET_DISPLAY_WIDTH = 1366, SET_DISPLAY_HEIGHT = 768;
static final int CASH_SALES_VOUCHER_TITLE_IN_WINDOW_INDEX = 2;
static final String CONTENT_VALIDATION_TYPE_NUMBER = "NUM";
static final String CONTENT_VALIDATION_TYPE_POSITIVE_INTEGER = "INT";
static final String CONTENT_VALIDATION_TYPE_TEXT = "TXT";
static final int ATTACHMENT_RANDOM_CODE_LENGTH = 20;

// Excise Tax
static final String EXCISE_TAX_ITEM_CODE = "ITM-00002";
static final String EXCISE_TAX_ITEM_NAME = "Excise TaX";
static final String EXCISE_TAX_QUANTITY = "1";
static final String EXCISE_SALE_UOM = "pcs";
static final String SOV_PREFIX = "SOV-";
static final String ATTACHMENT_PREFIX = "ATT-";
static final String FS_NUMBER_PREFIX = "FS No. ";
static final String FS_NUMBER_SAMPLE = "00000000";
static final int FS_NUMBER_LENGTH = FS_NUMBER_SAMPLE.length ();
static final float NOMINAL_DELTA = 3;

// DB Connection Details
private static final String DB_NAME = "Testbed";
private static String DB_URL = "jdbc:postgresql://pgserver.local:5432/" + DB_NAME;
private static String DB_USER = "openpg";
private static String DB_PASS = "openpgpwd";
private static String authErrorMessage  = "Error while logging in.\nMake sure URL, DB Name, Username, and Password are correct.";

// Odoo User Details
private static String ODOO_URL = "http://pgserver.local:8069";
private static String ODOO_USER = "ka.shear";
private static String ODOO_PASS = "K4$H34r";

// Serial QR Scanner
static final String PORT = "COM5";
static final char bufferUntilChar = '\r';
static final int BAUD_RATE = 9600;

// Colors
static int SELECTION_BLUE = -7876885;


class Windows {
  static final String mainTitle = "CNET ERP V2016_Sales and Marketing Management System";
  static final String cashSalesVoucher = "Cash Sales Voucher";
  static final String addLineItemModal = "Add Lineitem Error";
  static final String removeLineItemModal = "Remove LineItem";
  static final String voucherSavedModal = "Congratulations!";
  static final String printDialog = "Print Dialog";
}

class Timeouts {
  static final int WIN_WAIT = 5000;
  static final int FIELD_WAIT = 5000;
}

class Paths_ {
  String appParentDir;
  String dataPath;
  String resPath;
  String queriesDir;
  String query_quotationDetailsPath;
  String query_get_client_order_ref_by_code;
  String query_set_client_order_ref_by_code;
  String query_get_partner_active_orders_by_code;
  String tempDir, tempPath;

  Paths_ () {
    appParentDir = System.getProperty("user.home") + "/AppData/Local/Kashear/";
    dataPath = dataPath ("") + "/";

    resPath = new File (dataPath).getParent () + "/res/";

    queriesDir = dataPath ("") + "/queries/";
    query_quotationDetailsPath = queriesDir + "quotation_details_by_code.txt";
    query_get_client_order_ref_by_code = queriesDir + "get_client_order_ref_by_code.txt";
    query_set_client_order_ref_by_code = queriesDir + "set_client_order_ref_by_code.txt";
    query_get_partner_active_orders_by_code = queriesDir + "get_partner_active_orders_by_code.txt";

    tempDir = appParentDir + "temp/";
    tempPath = tempDir + "temp.txt";
  }
}

static final String APP_NAME = "Kashear_AG";
static final String AG_DATE_TIME_PATTERN = "M/d/yyyy h:mm:ss a";
static final String NFC_BIG_BASE_PATTERN = "#,##0";
static final String AG_SUMMARY_LABELS [] = {"Sub Total", "VAT (15.00%)", "Grand Total"};
static final String GENERATOR_LABELS [] = new String [] {"Customer", "Finance Division"};

// Currency
static final String CURRENCY_NAME_BILL = "Birr";
static final String CURRENCY_NAME_CENTS = "Cents";

static final int FILE_CREATION_TIMEOUT = 5000;

static final color COL_GRAY = #C8C6C7;
static final color COL_GRAY_DARK = #C0C0C0;

static final float WATERMARK_OPACITY_PERCENTAGE = 0.225;
static final float STROKE_WEIGHT = 0.7;
static final float STROKE_WEIGHT_THICK = 1;
static final float AG_LINE_ITEMS_COL_Xs [] = {24.31, 42.31, 114.4, 333.1, 386.9, 433.7, 494.9, 564.6};
static final float AG_SUMMARY_COL_Xs [] = {333.1, 494.9, 565};

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
