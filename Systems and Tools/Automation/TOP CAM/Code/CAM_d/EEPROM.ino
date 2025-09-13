#include <EEPROM.h>

void resetEEPROM () {
  for (int index = 0 ; index < EEPROM.length() ; index++)
    EEPROM [index] = 0;
}

double getEEPROMval (int addr) {
  double v;
  EEPROM.get (addr, v);

  return v;
}
double retrieve (int address, double resetVal) {
  double tempVal = getEEPROMval (address);
  if (tempVal < 0 || isnan (tempVal)) {
    EEPROM.put (address, resetVal);
    return resetVal;
  }
  return tempVal;
}

void putString (int address, const String &content) {
  int strLength = content.length();
  EEPROM.put (address, strLength);

  for (int i = 0; i < strLength; i++)
    EEPROM.write(address + 4 + i, content [i]);
}

String getString (int address) {
  int strLength;
  EEPROM.get (address, strLength);
  char content [strLength + 1];

  for (int i = 0; i < strLength; i++)
    content [i] = EEPROM.read(address + 4 + i);
  content [strLength] = '\0';

  return String(content);
}

String retrieve (int address, String resetData) {
  String content = getString (address);
  content.trim ();
  if (content.length () == 0) {
    putString (address, resetData);
    return resetData;
  }
  return content;
}
