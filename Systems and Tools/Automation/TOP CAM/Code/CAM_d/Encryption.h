class Encryption {
  private:
    String key;  // Key used for XOR encryption
    const char base64_chars[65] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  public:
    // Constructor to initialize with a key
    Encryption(String encryptionKey) {
      key = encryptionKey;
    }

    // Encrypt the text using XOR encryption and return Base64 encoded result
    String encrypt(String text) {
      String encryptedText = xorEncrypt(text);   // First XOR encrypt the text
      return base64Encode(encryptedText);        // Then Base64 encode it
    }

    // Decrypt the Base64 encoded and XOR encrypted text
    String decrypt(String encryptedBase64Text) {
      String decodedText = base64Decode(encryptedBase64Text);  // First Base64 decode the input
      return xorEncrypt(decodedText);                          // Then XOR decrypt it
    }

  private:
    // XOR encryption and decryption (same function since XOR is symmetric)
    String xorEncrypt(String text) {
      String result = "";
      int keyLength = key.length();
      for (int i = 0; i < text.length(); i++) {
        result += char(text[i] ^ key[i % keyLength]);  // XOR each character with the key
      }
      return result;
    }

    // Base64 encoding function
    String base64Encode(String input) {
      String encoded = "";
      int val = 0, valb = -6;
      for (int i = 0; i < input.length(); i++) {
        val = (val << 8) + input[i];
        valb += 8;
        while (valb >= 0) {
          encoded += base64_chars[(val >> valb) & 0x3F];
          valb -= 6;
        }
      }
      if (valb > -6) encoded += base64_chars[((val << 8) >> (valb + 8)) & 0x3F];
      while (encoded.length() % 4) encoded += '=';
      return encoded;
    }

    // Base64 decoding function
    String base64Decode(String input) {
      int val = 0, valb = -8;
      String decoded = "";
      for (int i = 0; i < input.length(); i++) {
        if (input[i] == '=') break;
        val = (val << 6) + strchr(base64_chars, input[i]) - base64_chars;
        valb += 6;
        if (valb >= 0) {
          decoded += char((val >> valb) & 0xFF);
          valb -= 8;
        }
      }
      return decoded;
    }
};
