static final String appName = "Loj Server";
static final String PATH_PREFERENCES = "configs/loj_server_preferences.xml";
static final String PATH_ISSUERS = "configs/loj_server_issuers_details.xml";
static final String GET_OR_DASH_DEFAULT = "-";
static final String PRINT_SUCCESS = "SUCCESS", PRINT_FAILED = "FAILED";
static final String COPIES_TYPES [] = {"B", "F", "S", "FS"};
static final String COPIES_LABELS [] [] = {{null}, {"FINANCE"}, {"STORE"}, {"FINANCE", "STORE"}};
static final String cLOG_HEADERS [] = {
  "timestamp", "log"
};
static final String LOG_HEADERS [] = {
  "print_date_time", "order_date_time", "voucher_code", "voucher_reference", "print_copies", "printed_copies", "printer",
  "salesperson", "device_name", "user_name", 
  "plate_number", "stock_site", "payment_term", "par_name", "par_code", "par_adress", "par_tin", 
  "item_name", "item_uom", "item_sales_uom", "item_quantity", "item_unit_price", "item_subtotal", "item_tax_type", "item_tax_amount", "item_total_amount", 
  "voucher_subtotal", "voucher_tax_total", "voucher_grand_total"
};

static final int XML_INPUT_CHECKIN_PERIOD = 1000;
static final int VOUCHER_QUEUER_CHECKIN_PERIOD = 1000;
static final int VOUCHER_RANDOM_CODE_LENGTH = 20;
static final int DEFAULT_VOUCHER_PRINT_COPIES = 1;
static final int FILE_CREATION_TIMEOUT = 5000;
static final int MIN_CUSTOMER_NAME_LENGTH = 3;
static final int PLATE_NUMBER_CUTOFF_LENGTH = 60;
