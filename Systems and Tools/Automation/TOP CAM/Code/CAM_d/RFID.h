#include <SPI.h>
#include <MFRC522.h>

class RFID {
  private:
    String tagID;
    MFRC522 mfrc522;// SS_PIN, RST_PIN

    String getTagID () {
      if (!mfrc522.PICC_IsNewCardPresent() || ! mfrc522.PICC_ReadCardSerial()) return "";

      String tagID = "";
      for ( uint8_t i = 0; i < 4; i++) { // The MIFARE PICCs that we use have 4 byte UID
        tagID.concat(String(mfrc522.uid.uidByte[i], HEX)); // Adds the 4 bytes in a single String variable
      }

      tagID.toUpperCase();
      mfrc522.PICC_HaltA(); // Stop reading
      return tagID;
    }

  public:
    RFID(uint8_t ssPin, uint8_t rstPin) : mfrc522(ssPin, rstPin) {}

    void init () {
      SPI.begin();
      mfrc522.PCD_Init();
    }
    void scan () {
      tagID = getTagID ();
    }
    String getID () {
      return tagID;
    }
};
