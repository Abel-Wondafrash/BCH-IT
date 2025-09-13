static final String JOURNAL_MODE_WAL = "WAL";
static final String DATE_PATTERN = "dd_MMM_yyyy";
static final String MONTH_PATTERN = "MMM";
static final String TIME_PATTERN = "hh:mm:ss a";
static final String TIME_PATTERN_MILLIS = "hh:mm:ss:SSS a";
static final String STATUS_JAMMED = "JAMMED", STATUS_STARVED = "STARVED", STATUS_UNKNOWN = "INCONCLUSIVE";

static final int STOP_TIME_THRESHOLD = 2*60*1000;
static final int DEFAULT_CYCLE_TIME = 1; // ms
static final int DEFAULT_SLOW_CYCLE_THRESHOLD = 10000; // ms
static final int DB_UPDATE_PERIOD = 5000; // ms
static final int DB_RECHECK_PERIOD = 1000; // ms
static final int MIN_PALLETIZER_PROCESSING_TIME = 2000; // ms

static final int TIMELINE_FRACTION = 3*60*1000;
