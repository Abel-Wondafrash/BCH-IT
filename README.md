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
- **Solution:** Watch this guide to restore the most recent working backup

### Database Won't Backup at all or Change Backup Schedule

- **Issue:** A database won't backup entirely or want to change the schedule
- **Solution:** Watch this guide to setup backup system and configure it like this

### Database Won’t Backup Correctly

- **Issue:** Backup fails or produces incomplete files
- **Solution:** Check storage space and permissions

### Other Critical Issues

- Find details [here (system issues)](./Systems%20and%20Tools/System%20Errors%20and%20Fixes.md) and [here (CNET issues)](./Systems%20and%20Tools/ERP/CNET/Errors_and_Fixes.md) and [here (machines)](/Production%20&%20Machines/Readme.md) or search for keywords in this repo.

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
