boolean initSD () {
  if (!SD.begin(chipSelect)) {
    Serial.println("SD Initialization Failed!");
    return false;
  }
  Serial.println ("SD Initialized");
  return true;
}

boolean saveSD (String content) {
  // Open the file for writing (append)
  File dataFile = SD.open(LOG_PATH, FILE_WRITE);
  if (dataFile) {
    dataFile.println(content);
    dataFile.close();
    Serial.println("New data saved to SD card.");
    delay (500);
    return true;
  } else {
    Serial.println("Error opening file for writing.");
  }
  return false;
}

boolean fileExists (String path) {
  return SD.exists (path);
}
