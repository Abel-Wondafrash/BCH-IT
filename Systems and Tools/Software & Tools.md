# Software & Tools

This section documents software utilities and tools, including code editors, design applications, OCR solutions, and printer drivers, designed to enhance efficiency and streamline workflows in business operations.

---

## Excel: Convert Numbers to Words (Including Decimal Values) Using Custom VBA Function

- **Issue**: Excel lacks a built-in function to convert numeric values into written words (e.g., for invoices or financial reports), especially when handling decimal amounts (e.g., 123.45 → "One Hundred Twenty-Three and Forty-Five").
- **Solution**: Implement a custom `NumberToWords` VBA function that supports integer and decimal parts.
  - Open Excel and press **Alt + F11** to open the VBA editor.
  - Insert a new module: **Insert > Module**.
  - Paste the code from [`NumberToWords.txt`](./Files/NumberToWords.txt) into the module.
  - Close the editor and return to Excel.
  - Use the function in any cell:  
    `=NumberToWords(A1)`  
    where A1 contains the number to convert.
  - Example: `=NumberToWords(123.45)` returns _"One Hundred Twenty-Three and Forty-Five"_.

---

## HID FARGO DTC1250e and Asure ID Software (ID Card Printer & Encoder Driver)

- **Description**: Utilities for managing the HID FARGO DTC1250e ID Card Printer & Encoder, including the driver for printer functionality and HID Asure ID Software for designing and printing ID cards.
- **Resources**:
  - **[HID FARGO DTC1250e Driver](./Files/SFW-00435_RevK_DTC1250e_v5.5.0.3_setup.zip)**
  - **[HID Asure ID Software](https://drive.google.com/file/d/1NYsjM2Fkdou67VqEZrJuH_PYcO5W1oL8/view?usp=drive_link)**

---
