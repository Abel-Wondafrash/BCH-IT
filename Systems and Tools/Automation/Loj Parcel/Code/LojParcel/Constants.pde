static final String APP_NAME = "Parcel";
static final String DATE_TIME_FORMAT = "dd-MM-yyyy • hh:mm:ss a";
static final String DNA_CONFIG_FILE = "loj_parcel_dna_config.xml";
static final int SLIP_RANDOM_CODE_LENGTH = 20;
static final int XML_PARSE_ATTEMPTS = 3;

class Paths_ {
  String appParentDir;
  String tempDir, tempPath;
  String logDir;
  String dnaConfigPath;

  Paths_ () {
    appParentDir = System.getProperty("user.home") + "/AppData/Local/Loj Parcel/";
    tempDir = appParentDir + "temp/";
    tempPath = tempDir + "temp.txt";
    logDir = appParentDir + "logs/";
    dnaConfigPath = new File (dataPath ("")).getParent () + "/config/" + DNA_CONFIG_FILE;
  }
  
  String getTempDir () {
    return tempDir;
  }
  String getDNAconfigPath () {
    return dnaConfigPath;
  }
}
