# Productivity Tools

This section lists software utilities and tools, such as code editors, design applications, and OCR solutions, designed to enhance efficiency and streamline workflows in business operations.

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
