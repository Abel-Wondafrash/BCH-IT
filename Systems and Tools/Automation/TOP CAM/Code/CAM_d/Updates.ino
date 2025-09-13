void saveStateUpdates () {
  // Retrieve data on EEPROM
  lastState = getString (0);
  // Brute Forcing
  bruteForced = lastState.equals (FORCED_ENTRY);

  // First Ever Run or Reset
  if (!lastState.equals (FORCED_ENTRY) && !lastState.equals (OPENED) && !lastState.equals (CLOSED)) {
    lastState = OPENED; // Default Value
    putString (0, lastState);
  }
  // Brute Force Type
  bruteForceType = getString (100);
  if (!bruteForceType.equals (FORCED_ONLINE) && !bruteForceType.equals (FORCED_OFFLINE) && !bruteForceType.equals (FORCED_NOT)) {
    bruteForceType = FORCED_NOT;
    putString (100, bruteForceType);
  }
  // Brute Forced While
  if (!bruteForced && lastState.equals (CLOSED) && contacts.isOn ()) {
    bruteForced = true;
    bruteForceType = FORCED_OFFLINE;
    putString (0, FORCED_ENTRY);
    putString (100, bruteForceType);
  }
  
  if (!bruteForced && lastState.equals (OPENED) && !contacts.isOn ()) {
    putString (0, CLOSED);
    lastState = CLOSED;
  }
}
