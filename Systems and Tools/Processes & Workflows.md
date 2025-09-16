# 🟦 Business Continuity Handbook – IT

This section documents monitoring, maintenance, and support tasks required to safeguard critical IT and automation systems.

---

## SOP (Standard Operating Procedure)

### 🟦 Scope

This SOP covers systems, applications, and support tools used to maintain business continuity:

- **ERP Systems:** Odoo, CNET
- **Other Systems:** Peachtree
- **Backup Systems:** MegaSync (Odoo, CNET, Peachtree, WindowsImage)
- **Server & System Monitoring:** Server Manager, Windows Services, File Explorer
- **Application Tools:** pgAdmin, SO Engine, Loj Insights, Kashear, Machine Software, MaYet
- **Office Support Tools:** MS Tools, Printers, ID Software (TOP ID, Asure ID), Credentials
- **Test Environments:** Testbed databases (for upgrades, new developments, and validation)

---

### 🟦 Critical Daily Operations

#### 0. Power & UPS Management

- Frequently check **UPS setup**, especially during periods of frequent power outages.
- **Primary UPS (ECO-Flow E980):**
  - Monitor via mobile app for status and battery percentage.
  - Can support systems for 5+ hours but switches slower between mains and battery -- can sometimes cause hard shutdowns.
- **Secondary UPS (UPSilon 2000):**
  - Fast-switching backup, runtime ~10 minutes.

##### IMPORTANT:

- If the primary UPS is not running or extremely low on battery but servers remain on, immediately initiate a **proper shutdown sequence** using the secondary UPS through either RTD (Local, RustDesk, AnyDesk) or directly (physically) on the server.

#### 1. System Health & Monitoring

- Check **Server Manager alerts**.
- Verify **critical services** (Odoo, CNET, Peachtree) are running.
- Check **disk partitions** via File Explorer to prevent/resolve storage issues. Clearup old backups (10+ days old) starting from Odoo backups while double checking you are deleting the right files.

#### 2. Backups & Recovery

- Verify **MegaSync backup completion** for Odoo, CNET, Peachtree, and WindowsImage. If internet is unavailable, copy backup to at least two other machines (ideally with SSD) (and never trust just a simple thumbdrive which may easily be lost or corrupted).
- Confirm **backup integrity** through performing random restore check monthly.

#### 3. Sales & Operations Checks

- Verify **Tailscale** is running, especially after power outages or restarts.
- Confirm **Loj Insights** has generated daily and weekly sales report. (In Documents/Loj/Sales Report/ or Desktop/Sales Report shortcut)
- Verify **SO Engine** is running (Task Manager/Java ...) and through (C:/Users/Loj/Logs/... 'C\_ - Loj Server Log.csv's last logged contents), especially after power outages or restarts.

#### 4. Office & Support Tools

- Check **printer queues** (Marketing team) and clear if stuck.
- Verify **printer ink levels** (daily glance + on-demand).

#### 5. Remote Access / Monitoring

- Use **RustDesk** for remote access and maintenance from a computer / mobile.
- Use **AnyDesk** for remote access as an alternative to RustDesk.
- Use **Remote Desktop Connection** for faster remote access but from local network.
- Monitor system health, assist colleagues, and troubleshoot remotely as needed.

---

### 🟦 Periodic Operations

#### Weekly

- Provide support for Marketing and/or Finance teams on Purchase & Payment Requests Reporting / formatting.
- Maintain and promptly refill backup toner stock to ensure quick replacement during unforeseen ink shortages.
- Review IT inventory, submit purchase requests, and follow up with Procurement to prevent shortages that could disrupt workflow.

#### Biweekly (2x a week)

- Identify, document, and implement improvements for both hardware and software issues within the office environment.

#### Monthly

- Conduct physical inspections of systems (computers, printers, POS machines, switches, network cables, etc.), including dust cleaning, cable management, and general upkeep.

---

### 🟦 On-demand Operations

#### Maintain user accounts and access rights

- Video guide [here](https://youtu.be/BXI06p6BXbk)
- Change & Reset Password | Video guide [here](https://youtu.be/9VejQ505IbA)
- make use of this [Departmental Access Rights Matrix](https://docs.google.com/spreadsheets/d/1ZXbapSx-rJNSuL6kyG_qzd-jaXd-oAmvmHZmoYqik_s/edit?usp=sharing)

#### Maintain contacts (customer, vendor, employee)

- Video guide [here](https://youtu.be/NEsb_UmYwXc)
- Important Note:
  - Obtain the following from **MARKETING**
    - Sales & Purcahses > Sale Pricelist
  - Obtain the following from **FINANCE**
    - VAT (TIN)
    - Opening (Initial/Beginning) Balance
    - Invoicing > Customer Payment Terms
    - Invoicing > Pre-Payment Account

#### Maintain Loj SO Engine (Issuers)

- Convert image into vector digital signature | Video guide [here](https://youtu.be/lkRKYHP1fLg)
- Add Issuers' Digital Signatures to SO Engine [here](https://youtu.be/sE7V-jnQYKo)

#### Maintain sellable items creation

- Video guide [here](https://youtu.be/GOucVCyTxwM)
- Important Note:
  - _Product Name_ should be succinct, descriptive, and search optimized
  - _Shorthand Name_ should be less than 15 characters (absolute max). Leaving it blank will default to full _Product Name_ in Loj Insight's report.
  - If _Can be Sold_ is not checked, product won't be available in Quotation.
  - Select the correct _Category_ type as it won't always be _Finished Goods_.
  - _Pack Quantity_ is the number of individual items in a bundle as would be sold to a buyer.
  - _Sales Price_ is the price of an item that DOES NOT include VAT but may (depending on the product type) include Excise Tax
  - _Sales/Pricelist_ should be added only if more than a single price applies to the product.
  - Don't forget to _update cost_ (in _General Information / Cost / update cost_)after creating the product as leaving it at the default 0.000000 will make the invoice created from quotations invalidatable.
  - Obtain the following from **MARKETING:**
    - Pack Quantity
    - Product Name
    - Shorthand Product Name
  - Obtain the following from **FINANCE:**
    - Sales Price (main/standard and pricelist)
    - Excisability (for the _Invoicing / Is Excisable_ field)
    - Product WarehouseId and corresponding Warehouse

#### Maintain sales pricelist

- Video guide [here](https://youtu.be/zwxdr9eytnA)
- Note: as long as _Location_ is tied with _Pricelist_, it is recommended to use the same name for both _Location_ & _Pricelist_

#### Maintain sales locations

- Video guide [here](https://youtu.be/7NBnkiCJJBM)
- Note: as long as _Location_ is tied with _Pricelist_, it is recommended to use the same name for both _Location_ & _Pricelist_

#### Maintain Unit of Measure (UoM) and UoM Categories

- Video guide [here](https://youtu.be/hzYZWPO_XcA)
- For consistency, please use lowercase for UoM naming

#### Maintain company branches / locations

- Inventory > Configurations > Warehouse Management > Locations > Create

#### ID generation & printing

- Video guide [here](https://youtu.be/4cB1t63SZIQ)

#### Grant Individual User Access to Inventory Dashboard via Operation Type Responsibility

- Video guide [here](https://youtu.be/ewjsmZ4kAwI)

---
