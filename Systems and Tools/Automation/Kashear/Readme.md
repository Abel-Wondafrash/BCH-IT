# Kashear

Kashear is an automation bridge between Odoo, CNET, and POS that eliminates errors, speeds up processes, and transforms finance staff from clerks into strategic contributors. It enables accurate, scalable, and future-ready sales operations.

---

Watch Kashear in action [here](https://youtube.com/shorts/5uMb_Zu7hSY)

## Configuration Essentials

All critical configurations are designed to be stored on a **remote device** (typically a server). This minimizes unauthorized tampering that could disrupt or jeopardize operations.

### Resources required by Kashear

- **Link configuration file:**  
  The local link between Kashear and the remote server.  
  Must be named exactly `kashear_dna_config.xml`.  
  Contains a `config_file_path` tag pointing to the full path of the main config (`kashear_config.xml`).

- **Libraries:**  
  Kashear depends on the following libraries (must be present in `lib/`):

  - `icu4j-2.6.1.jar` – International Components for Unicode (text, locale, date/time formatting)
  - `jna-5.13.0.jar` – Java Native Access (bridge to native shared libraries)
  - `jna-platform-5.13.0.jar` – Extra JNA utilities for specific platforms
  - `pdfbox-app-3.0.4.jar` – Apache PDFBox (create and manipulate PDFs)
  - `postgresql-42.7.5.jar` – PostgreSQL JDBC driver
  - `ws-commons-util-1.0.2.jar` – Apache Commons utilities (XML, I/O helpers)
  - `xmlrpc-client-3.1.3.jar` – Apache XML-RPC client (remote procedure calls)
  - `xmlrpc-common-3.1.3.jar` – Shared classes for XML-RPC parsing & serialization

- **CNET ERP support:**  
  Only **CNET ERP V2016** is supported by this version of Kashear.

---

## Configuration Details

> ⚠️ **Important:** Any changes to these parameters should only be made under instruction from the Finance team. Wrong entries may cause corrupted data, database inconsistencies, or irrecoverable errors. Always double-check before saving.

---

### General

**is_mode_direct**

- Defines how Kashear interprets SOV numbers from QR scans.
- **Values:** `true` or `false` | default `true`
  - `true`: The scanned QR code content itself is taken as the SOV number (e.g., `04631`).
  - `false`: Scanning triggers a manual entry field where the user types the SOV number.
- **Note:** In both modes, the number must match the raw numeric SOV in Odoo (without the `SOV-` prefix).

**price_dp**

- Number of decimal places Kashear uses when formatting prices for CNET.
- **Default:** `3`
- **Tip:** Only change if CNET updates its decimal precision.

**grand_total_nominal_delta**

- The allowed tolerance (difference) between CNET’s and Odoo’s total calculations.
- **Default:** `3.000`
- **Warning:**
  - Lower = stricter, more rejections.
  - Higher = looser, may let errors slip.
  - Always confirm with Finance before adjusting.

---

### Taxation

**excise_tax_percentage**

- Percentage tax applied to all excisable products.
- **Default:** `10`

**excise_tax_item_code**

- Item code for excise tax in CNET.
- **Default:** `ITM-00002`

**excise_tax_item_name**

- Item name for excise tax in CNET.
- **Default:** `Excise TaX`

**excise_tax_quantity**

- Quantity used when applying excise tax.
- **Default:** `1`

**excise_sale_uom**

- Unit of measure for excise tax in attachments.
- **Default:** `pcs`

---

### Nomenclature

**sales_order_prefix**

- Prefix used by Odoo sales orders.
- **Default:** `SOV-`

**attachment_prefix**

- Prefix for generated attachment file names.
- **Default:** `ATT-`

**fs_number_prefix**

- Prefix to add before FS numbers in Odoo references.
- **Default:** `FS No. `

**fs_number_sample** _(legacy use)_

- Sample FS number pattern to validate digit count.
- **Default:** `00000000` (8 digits)

---

### Database Details

**db_name**

- PostgreSQL database name Kashear connects to.
- **Default:** `TOP_2018`

**db_ip**

- IP address of the PostgreSQL server.
- **Default:** `192.168.1.154`

**db_port**

- Port number for PostgreSQL.
- **Default:** `5432`

**db_user**

- Database username.
- **Default:** `openpg`

**db_pass**

- Database password.
- **Default:** `********`

---

### Odoo Details

**odoo_ip**

- Odoo server IP address.
- **Default:** `192.168.1.154`

**odoo_port**

- Odoo server port.
- **Default:** `8069`

**kashear_odoo_email**

- Odoo login email used by Kashear.
- **Default:** `ka.shear`

**kashear_odoo_pass**

- Odoo login password.
- **Default:** `********`

---

### QR Scanner

**qr_scanner_port**

- COM port assigned to the QR scanner.
- **Default:** `COM5`
- **How to find:**
  - Open **Device Manager** → **Ports (COM & LPT)** → find your scanner.

**qr_scanner_baud_rate**

- Baud rate for the QR scanner (must match scanner’s driver setting).
- **Default:** `9600`
- **How to verify:**
  - In **Device Manager**, right-click the COM port → **Properties** → **Port Settings** tab.

---

### Attachment

**file_creation_timeout**

- Maximum time (in milliseconds) to wait for attachment file creation.
- **Default:** `5000`

**attachment_printer_name**

- Name of the printer used for attachments. Must match exactly as listed under **Windows Settings → Printers & Scanners**.
- **Default:** `FFFFFF4003`
- **Fallback:** If not found, the system default printer will be used.

**auto_close_voucher_saved_modal**

- Whether to auto-close the "Congratulations!" modal after voucher save.
- **Default:** `true`

**auto_close_print_dialog**

- Whether to auto-close the print dialog automatically.
- **Default:** `true`

---

### Paths

**res_path**

- Resource directory path.
- **Default:** `\\\\WIN-P0OU438M5IM\Kashear\res`

**query_get_quotation_details_path**

- File path to SQL query that fetches quotation details by code.
- Eg. `\\WIN-P0OU438M5IM\Kashear\queries\quotation_details_by_code.txt`

**query_get_client_order_ref_by_code**

- File path to SQL query that fetches client order reference using SOV code.
- Eg. `\\WIN-P0OU438M5IM\Kashear\queries\get_client_order_ref_by_code.txt`

**query_set_client_order_ref_by_code**

- File path to SQL query that sets client order reference using SOV code.
- Eg. `\\WIN-P0OU438M5IM\Kashear\queries\set_client_order_ref_by_code.txt`

**query_get_partner_active_orders_by_code**

- File path to SQL query that fetches active partner orders by SOV code.
- Eg. `\\WIN-P0OU438M5IM\Kashear\queries\get_partner_active_orders_by_code.txt`

---

### Timeouts

**win_wait**

- Maximum time (in milliseconds) to wait for Windows UI responses.
- **Default:** `5000`

**field_wait**

- Maximum time (in milliseconds) to wait for field interactions.
- **Default:** `5000`

---
