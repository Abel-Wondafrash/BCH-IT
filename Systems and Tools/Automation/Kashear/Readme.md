# Kashear

Kashear is an automation bridge between Odoo, CNET, and POS that eliminates errors, speeds up processes, and transforms finance staff from clerks into strategic contributors. It enables accurate, scalable, and future-ready sales operations.

---

Watch Kashear in action [here](https://youtube.com/shorts/5uMb_Zu7hSY)

## Configuration Essentials

All critical configurations are designed to be stored on a remote device (typically a server). This is to minimize unauthorized tampering that could disrupt or jeopardize operations.

### Resources required by Kashear

- **link configuration file:** this is the main link between Kashear and the remote device containing resources. It should be named exactly `kashear_dna_config.xml` and contain a `config_file_path` which is where resources should live.
- **libraries:** this is a list of libraries Kashear depends on.
  - icu4j-2.6.1.jar _(International Components for Unicode – text, locale, and date/time formatting support)_
  - jna-5.13.0.jar _(Java Native Access – allows Java to call native shared libraries without JNI)_
  - jna-platform-5.13.0.jar _(Extra platform-specific mappings and utilities built on JNA)_
  - pdfbox-app-3.0.4.jar _(Apache PDFBox – creating, manipulating, and extracting content from PDFs)_
  - postgresql-42.7.5.jar _(PostgreSQL JDBC driver – enables Java apps to connect to PostgreSQL databases)_
  - ws-commons-util-1.0.2.jar _(Apache Commons utilities for web services – helper classes for XML, I/O, etc.)_
  - xmlrpc-client-3.1.3.jar _(Apache XML-RPC client – allows calling remote procedures over XML-RPC)_
  - xmlrpc-common-3.1.3.jar \_(Shared classes for Apache XML-RPC client/server – parsing, serialization, \_utilities)
- **CNET:** it should be noted that this version of Kashear supports only CNET ERP V2016

### Configuration Details

Please give due attention when changing any of the following parameters as the wrong entry could mean incorrect, corrupted database, difficult to reverse operations, and more. Only proceed to change configuration files after reading and understanding the content below in its entirety.

**NOTICE:** Any changes made to the config file should be upon the request of the Finance team and should be communicated with the Finance team promptly.

#### General

**is_mode_direct:**

- description: this tells Kashear in which mode, 'manual' or 'direct', to take SOV number as input.
- value: only true or false
  - if value is `true` Kashear will treat the whole of the content read from the QR scanner as the SOV number.
  - if value is `false` Kashear will treat scanning as a trigger to launch a textfield where the SOV number should be inserted. In this mode, the content of the QR code used to trigger Kashear is irrelevant and will be rejected (only used for trigger).
- **IMPORTANT:** In either of the above cases/modes, the value scanned/entered should be a number with no prefix matching exactly the SOV number in Odoo. eg: _04631_ instead of _SOV-04631_

**price_dp:**

- description: is the decimal places after the decimal point Kashear should format a given price of an item/product when feeding it to CNET.
- value: default is 3. There should almost be need to change this unless CNET changes their dp values. Decreasing it to less than 3 will of course increase the calculation deviation between CNET, Odoo, and Kashear.
- **NOTE:** increasing it to a value above that of CNET's default is meaningless as CNET ignores figures after their set dp.

**grand_total_nominal_delta:**

- description: the delta (deviation) between CNET's calculation and that of Odoo's Kashear should consider as nominal (expected).
- value: default is 3.
- **WARNING:** This should only be set to a value the Finance team requires. _The lower the value, the more intolerant Kashear will become and the higher the value the more tolerant Kashear will become. _

#### Taxation

**excise_tax_percentage:**

- description: the percentage value of excise tax for all excisable items (as defined in Odoo).
- value: 1 - 100
- **WARNING:** This should only be set to a value the Finance team requires. Kashear takes this value for excise tax calculation for all products which are marked excisable.

**excise_tax_item_code:**

- description: the item code of excise tax as appears in CNET's item definition
- value: eg. ITM-00002
- **Warning:** This should only be set to a value the Finance team requires.

---
