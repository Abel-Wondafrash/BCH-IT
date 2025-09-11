# 🟦 Business Continuity Handbook – IT (SOP)

This SOP documents monitoring, maintenance, and support tasks required to safeguard critical IT and automation systems.

---

## 🟦 Scope

This SOP covers systems, applications, and support tools used to maintain business continuity:

- **ERP Systems:** Odoo, CNET
- **Other Systems:** Peachtree
- **Backup Systems:** MegaSync (Odoo, CNET, Peachtree, WindowsImage)
- **Server & System Monitoring:** Server Manager, Windows Services, File Explorer
- **Application Tools:** pgAdmin, SO Engine, Loj Insights, Kashear, Machine Software, MaYet
- **Office Support Tools:** MS Tools, Printers, ID Software (TOP ID, Asure ID), Credentials
- **Test Environments:** Testbed databases (for upgrades, new developments, and validation)

---

## 🟦 Critical Daily Operations

### 0. Power & UPS Management

- Frequently check **UPS setup**, especially during periods of frequent power outages.
- **Primary UPS (ECO-Flow E980):**
  - Monitor via mobile app for status and battery percentage.
  - Can support systems for 5+ hours but switches slower between mains and battery -- can sometimes cause hard shutdowns.
- **Secondary UPS (UPSilon 2000):**
  - Fast-switching backup, runtime ~10 minutes.

#### IMPORTANT:

- If the primary UPS is not running or extremely low on battery but servers remain on, immediately initiate a **proper shutdown sequence** using the secondary UPS through either RTD (Local, RustDesk, AnyDesk) or directly (physically) on the server.

### 1. System Health & Monitoring

- Check **Server Manager alerts**.
- Verify **critical services** (Odoo, CNET, Peachtree) are running.
- Check **disk partitions** via File Explorer to prevent/resolve storage issues. Clearup old backups (10+ days old) starting from Odoo backups while double checking you are deleting the right files.

### 2. Backups & Recovery

- Verify **MegaSync backup completion** for Odoo, CNET, Peachtree, and WindowsImage. If internet is unavailable, copy backup to at least two other machines (ideally with SSD) (and never trust just a simple thumbdrive which may easily be lost or corrupted).
- Confirm **backup integrity** through performing random restore check monthly.

### 3. Sales & Operations Checks

- Verify **Tailscale** is running, especially after power outages or restarts.
- Confirm **Loj Insights** has generated daily and weekly sales report. (In Documents/Loj/Sales Report/ or Desktop/Sales Report shortcut)
- Verify **SO Engine** is running (Task Manager/Java ...) and through (C:/Users/Loj/Logs/... 'C\_ - Loj Server Log.csv's last logged contents), especially after power outages or restarts.

### 4. Office & Support Tools

- Check **printer queues** (Marketing team) and clear if stuck.
- Verify **printer ink levels** (daily glance + on-demand).

### 5. Remote Access / Monitoring

- Use **RustDesk** for remote access and maintenance from a computer.
- Use **AnyDesk** for remote access from mobile devices.
- Use **Remote Desktop Connection** for faster remote access but from local network.
- Monitor system health, assist colleagues, and troubleshoot remotely as needed.

---

## 🟦 Periodic Operations

### Weekly

- Provide support for Marketing and/or Finance teams on Purchase & Payment Requests Reporting / formatting.
- Maintain and promptly refill backup toner stock to ensure quick replacement during unforeseen ink shortages.
- Review IT inventory, submit purchase requests, and follow up with Procurement to prevent shortages that could disrupt workflow.

### Biweekly (2x a week)

- Identify, document, and implement improvements for both hardware and software issues within the office environment.

### Monthly

- Conduct physical inspections of systems (computers, printers, POS machines, switches, network cables, etc.), including dust cleaning, cable management, and general upkeep.

### Occasional / On-Demand

- Maintain user accounts and access rights (make use of this [Departmental Access Rights Matrix](https://docs.google.com/spreadsheets/d/1ZXbapSx-rJNSuL6kyG_qzd-jaXd-oAmvmHZmoYqik_s/edit?usp=sharing))
- Maintain contacts (customer, vendor, employee)
- Setup salesperson in Loj SO Engine
- Maintain sellable items creation
- Update sales locations and pricelists
- Maintain units of measure
- Maintain company branches
- ID generation & printing

---

## 🟦 Annual Operations

- **Fiscal Year Closing & Opening**
  - Execute SQL scripts
  - Perform Odoo UI & tool updates
  - Reconcile and archive with Google Sheets
  - Validate new year setup on **Testbed** before applying to production

---

## 🟦 Notes

- All recurring tasks should be documented with **date, responsible person, and verification status**.
- On-demand tasks should record **request origin, resolution steps, and closure confirmation**.
- Any identified inefficiency or recurring issue should be flagged for **process improvement**.
