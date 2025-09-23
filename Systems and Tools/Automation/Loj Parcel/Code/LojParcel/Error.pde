static class Error {
  static final String MISSING_SERVER_PREFERENCES = "Px0001";
  static final String MISSING_XML_LISTENING_PATH = "Px0002";
  static final String XML_LISTENING_PATH_NOT_SET = "Px0003";
  static final String MISSING_DESTINATION = "Px0004";
  static final String DESTINATION_NOT_SET = "Px0005";
  
  static final String MISSING_ISSUERS_DETAILS = "Cx0001";
  static final String ISSUERS = "Cx0002";
  
  static final String MISSING_SVG_DIR = "Sx0001";
  static final String MISSING_OR_CORRUPT_SVGS = "Sx0002";
  static final String MISSING_FONTS_DIR = "Fx0001";
  static final String MISSING_OR_CORRUPT_FONTS = "Fx0002";
  static final String INSTANCE_ALREADY_RUNNING = "Ix0001";
  
  static final String MISSING_TARGET_DIR = "Fx0001";
}

void showCMDerror (String errorCode) {
  showCMDerror (errorCode, "");
}

void showCMDerror (String errorCode, String details) {
  details = details.replace ("\n", "& echo.");
  
  launch ("start cmd /C \"echo ERROR (" + errorCode + "): " + APP_NAME + " is missing critical files. & echo." +
    "FIX: Reinstall " + APP_NAME + " or contact your system provider to help you resolve this issue. & echo." +
    (details.isEmpty ()? "" : "Details: " + details) +
    " & color 0c & timeout /t 30 & start https://t.me/PocoThings\"");
}
void showCMDerror (String errorCode, String details, boolean show) {
  details = details.replace ("\n", "& echo.");
  
  cLogger.log (errorCode + " - " + details);
  
  launch ("start cmd /C \"echo ERROR (" + errorCode + "): Another instance of " + APP_NAME + " is already running! & echo." +
    "FIX: Either close the other instance and start Loj again or keep using the existing instance. & echo." +
    (details.isEmpty ()? "" : "Details: " + details) +
    " & color 0c & timeout /t 30 & start https://t.me/PocoThings\"");
}
