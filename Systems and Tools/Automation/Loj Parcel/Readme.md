# Loj Parcel

## Description:

Loj Parcel is an automation system that resolves the inefficiencies of manual record keeping by converting handover forms into digital slips. Initially designed for Finance-Fleet workflows, it can also extend to Marketing and other departments, enabling structured documentation, reduced paper consumption through thermal printing, faster processing, and a new digital audit trail known as the LPS (Loj Parcel Slip).

## Problem Statement:

Within finance operations, handovers of receipts and supporting attachments are managed through couriers traveling between sites. Traditionally, a finance officer would print an A5 sheet and manually complete it by pen—filling in destination site, time and date, reference numbers of each receipt, customer details, issuer and dispatcher names, and obtaining signatures. This process could take several minutes, depending on the volume of documents, which caused couriers to wait. As a result, customers waiting for the delivery of financial records also experienced delays. If the physical form was lost, the entire process would need to be repeated manually—going through non-fiscal copies, and reconstructing batches. Additionally, there was no way to quickly track batches of documents for auditing, and the absence of digitization meant a single missing paper could create significant operational headaches.

## Solution:

With Loj Parcel, the workflow transforms. Instead of filling out paper by hand, finance staff simply navigate to Sales / Orders by Warehouse, choose the warehouse, select the documents, and print. Parcel automatically generates a slip with all required fields pre-filled and sends it to a thermal printer, ensuring no more paper is used than necessary (significantly less than an A5 paper). Each step is digitally logged, and batches are grouped in a structured, searchable format consistent with Odoo. Slips are re-printable, traceable, and securely stored—removing delays, minimizing risk, and enabling efficient auditing.

Watch Loj Parcel in action [here](#)

---

## Configuration Essentials

All key configuration values are centralized in a remote configuration file. This ensures consistency across deployments and minimizes unauthorized or accidental tampering.

### Resources Required by Loj Parcel

- **Link configuration file:**

  - The local connection between Loj Parcel and the remote configuration server.
  - Must be named exactly `loj_parcel_config.xml`.

- **Libraries:**  
  Loj Parcel depends on the following libraries (must be present in `code/`):

  - `apache.commons.lang3`
  - `escpos-coffee-4.1.0`

### Configuration Details

#### Slip

- **slip_printer_name**

- Name of the thermal printer used for slip printing as it appears on the host machine. Must match exactly as listed under **Windows Settings → Printers & Scanners**. There is no fallback printer automatically selected as thermal printers are typically not set as default.
- **Default:** `Queti(1)`

#### Paths

**res_path**

- Resource folder location containing templates and related assets.
- **Default:** `\\\\WIN-P0OU438M5IM\Loj Parcel\res`

**xml_target_path**

- Network path where generated XML slips are saved. Find this in Odoo.
- **Default:** `\\\\WIN-P0OU438M5IM\Slips`
