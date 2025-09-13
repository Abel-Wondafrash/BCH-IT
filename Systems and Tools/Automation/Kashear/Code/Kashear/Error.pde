static class Error {
  static final String MISSING_SVG_DIR = "Sx0001";
  static final String MISSING_OR_CORRUPT_SVGS = "Sx0002";
  static final String MISSING_FONTS_DIR = "Fx0001";
  static final String MISSING_OR_CORRUPT_FONTS = "Fx0002";
}

void showCMDerror (String errorCode) {
  showCMDerror (errorCode, "");
}

void showCMDerror (String errorCode, String details) {
  details = details.replace ("\n", "& echo.");
  
  launch ("start cmd /C \"echo ERROR (" + errorCode + "): " + APP_NAME + " is missing critical files. & echo." +
    "FIX: Reinstall " + APP_NAME + " or contact your system provider to help you resolve this issue. & echo." +
    (details.isEmpty ()? "" : "Details: " + details) +
    " & color 0c & timeout /t 15 & start https://t.me/PocoThings\"");
}
