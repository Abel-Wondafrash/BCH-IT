# Software Configurations

This section documents setup and configuration procedures for software applications, including licensing, installation settings, and parameter adjustments, to ensure proper functionality in business operations.

---

## Peachtree Accounting Registration Required: "You Must Register Now to Continue"

- **Issue**: Upon launching Peachtree Accounting, the error appears:  
  _"Register Peachtree Accounting. You must register now to continue using Peachtree. You have no unregistered uses left."_  
  This occurs when the trial period has expired and no valid registration key is present.
- **Solution**: Register using a generated key from a compatible key generator (e.g., Peachtree 2010 Key Generator).
  - Launch the **[Peachtree 2010 Key Generator](./Files/gkeygen.exe)** tool.
  - Generate a valid serial number.
  - In the Peachtree registration window:
    - Enter the generated key in the **Serial Number** field.
    - Enter the same key in the **Customer ID** field.
    - Leave the **Recommender ID** field empty.
  - Click **Register** to activate the software.

---

## Asure ID License Activation via Online Method

- **Issue**: Asure ID software requires a valid license to unlock full functionality, but remains restricted until activation.
- **Solution**: Activate the license online through the built-in licensing tool.
  - Go to **File > Options > Licensing > License Key**.
  - Click **Activate Online**.
  - Ensure the machine has internet connectivity.

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
