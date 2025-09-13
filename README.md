# Business Continuity Handbook (BCH-IT)

A comprehensive reference of Automation Works, IT Systems, and supporting processes designed to safeguard critical operations and ensure seamless business continuity during and after personnel transitions.

---

Please read the details of this BCH over at [Google Sheets](https://docs.google.com/document/d/1_hEis_xVPHiJS8Y0dfEQNExM6SObiQz1FUnA3c57JGM/edit?tab=t.gknsv4hxkm6h)

---

## 🚨 Emergency Guide

This guide provides quick-reference procedures for handling critical IT and automation emergencies.
If unsure what to do or need help, please check this escalation matrix.

→ **Level 1 (Low):** minor, single-user issue, infrastructure related

- IT Support → System Admin → IT Manager → IT Director

→ **Level 2 (Mid):** system service down, a department or multiple users affected

- System Admin → IT Manager → IT Director → Vendor

→ **Level 3 (High):** critical system down

- IT Manager → IT Director → Vendor → Executive Leadership

### Contacts of: [TOP Staff](https://docs.google.com/document/d/1_hEis_xVPHiJS8Y0dfEQNExM6SObiQz1FUnA3c57JGM/edit?tab=t.p5r7sz95ao4n) | [External (Partners & Vendors)](https://docs.google.com/document/d/1_hEis_xVPHiJS8Y0dfEQNExM6SObiQz1FUnA3c57JGM/edit?tab=t.csmeknmtdzmk)

---

## 1. Database Emergencies

### Corrupted Odoo Database

- **Issue:** Database corruption - symptoms may include 500 Server error, erroneous modules, +
- **Solution:** Watch [this](https://youtu.be/aGOfS9IhpIw) guide to restore the most recent working backup

### Database Won't Backup at all or Change Backup Schedule

- **Issue:** A database won't backup entirely or want to change the schedule
- **Solution:** Watch [this](https://youtu.be/X_ZU2EnMgWg) guide to setup backup system and configure it

### Database Won’t Backup Correctly

- **Issue:** Backup fails or produces incomplete files
- **Solution:** Check storage space and permissions

### Other Critical Issues

- Find details [here](./Systems%20and%20Tools/System%20Errors%20and%20Fixes.md) (system issues) and [here](./Systems%20and%20Tools/ERP/CNET/Errors_and_Fixes.md) (CNET issues) and [here](/Production%20&%20Machines/Readme.md) (machines) or search for keywords in this repo.

---

## 2. Server & Service Failures

### Persistent Error 500 (Server Error)

- **Issue:** Odoo or web service throws persistent Error 500.
- **Possible Causes:** Corrupted modules, bad configs, database issues, syntax error in code.
- **Solution:** Restart webpage, Restart Odoo service, check logs, restore recent working state, or investigate recent changes in code.

### Critical Services Won’t Start

- **Issue:** One or more services fail to start.
- **Solution:** Verify dependencies, permissions, and configs. Restart services or restart manually.

---

## 3. File System / Storage Issues

### Corrupted or Compromised File Systems

- **Issue:** File system errors or compromise detected.
- **Solution:** Run repair tools (fsck/chkdsk), restore from backup (Windows Image Backup) if needed.

### Server Disk Full _(to be detailed)_

- Follow instructions laid out [here (1. System Health & Monitoring)](./Systems%20and%20Tools/Processes%20&%20Workflows.md)

---

## Tools & Software

## 🔹 Database & ERP Tools

- **pgAdmin** – PostgreSQL management and queries.
- **DB Browser (SQLite)** – Inspect and edit SQLite databases.
- **Task Scheduler** – Automate recurring jobs (backups, scripts, maintenance).

## 🔹 Development & Automation

- **VS Code** – Code editing, extensions, debugging.
- **AutoHotKey** – Keyboard macros, repetitive task automation.
- **Python** – General scripting, data wrangling, automation.
- **Processing (Java)** – Creative coding, data visualization, experimental projects.
- **Hyper-V** – Virtual machines for test environments.
- **AnyDesk / RustDesk / Remote Desktop Connection** – Remote access and troubleshooting.
- **Tailscale** – Secure VPN mesh networking for remote access.

## 🔹 Productivity & Workflow

- **Microsoft To Do** – Task and reminders management.
- **Search Everything** – Instant file search across Windows.
- **Telegram** – Quick communication and file sharing.
- **WPS Office** – Lightweight alternative to MS Office.

## 🔹 Creative & Design

- **Adobe XD** – UI/UX mockups.
- **Adobe Illustrator** – Vector graphics.
- **Adobe Photoshop** – Image editing.
- **Adobe Premiere Pro** – Video editing.
- **OBS Studio** – Screen recording and live streaming.
- **Pichon** – Icons and graphic assets.
- **ShoeBox** – Texture/asset management.

## 🔹 File Handling & Utilities

- **7-Zip** – Advanced archive/compression utility.
- **PDF24** – PDF editing, merging, OCR, and conversions.
- **IDM (Internet Download Manager)** – Manage and accelerate downloads.
- **Mega VPN** – Secure browsing and bypass restrictions.

## 🔹 Backup & Sync

- **MegaSync** – Sync files/folders with MEGA cloud.
- **Duplicati** – Encrypted backups to cloud/local storage.
- **FreeFileSync (optional, lightweight)** – Manual folder sync and compare.

## 🔹 Monitoring & Diagnostics

- **Glances** – Real-time cross-platform system monitoring.

## 🔹 Online Utilities

- **Image to Spreadsheet OCR** – Convert images into Excel (pdfeagle.com).
- **PDF OCR** – Convert scanned PDFs to searchable text (pdf24 tools).
- **Excel Merger** – Merge multiple Excel worksheets into one (Aspose).
