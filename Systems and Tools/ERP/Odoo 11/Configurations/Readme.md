# Odoo 11 General Configurations

This section outlines system-wide configurations for Odoo 11, covering user interface adjustments, access rights, and settings such as timezone corrections and automated backups. These configurations do not involve code modifications or specific module updates.

> **Note**: Enable Developer Mode (_Settings > Activate Developer Mode_) to access advanced configuration options, as some fields may be hidden in standard user views.

---

## Enable Contact Creation

- **Path**: _Settings > Users & Companies > Users_
- **Action**: Check _Contact Creation_ to allow users to create bank account numbers for contacts among other privileges.

---

## Invoice Validation and Receipt Printing

- **Issue**: The _Validate Invoice_ option was not available, preventing the proper printing of receipts.
- **Solution**:
  - Create a contact record and associate it with the respective user (employee).
  - Assign a unique partner code to the contact to ensure proper linkage and validation.

---

## Incorrect Date-Time Display on SOV Due to Client Timezone Mismatch

- **Issue**: The system displays incorrect date-time values on Sales Order Views (SOV), caused by client machine timezone misconfiguration relative to the server's expected timezone (UTC+03:00).
- **Solution**: Align the client system's timezone with the server by setting the Timezone ID to UTC+03:00 (Nairobi).
  - Navigate to the client machine's system settings.
  - Set the timezone to "(UTC+03:00) Nairobi" explicitly.
  - Refresh the Odoo session to ensure correct date-time rendering in SOV.

---

## Grant Individual User Access to Inventory Dashboard via Operation Type Responsibility

- **Issue**: Users are unable to access the Inventory Dashboard despite having appropriate roles, due to missing assignment as a responsible person on relevant operation types.
- **Solution**: Assign individual users as responsible on specific Operation Types to grant dashboard visibility.
  - Go to **Inventory > Configuration > Warehouse Management > Operation Types**.
  - Select the relevant operation type (e.g., Receipts, Deliveries).
  - Click **Edit**, then scroll down to the **Responsible person** field.
  - Add or remove users in the assigned list as needed.
  - Click **Save** to apply changes; dashboard access will be updated immediately.

---

## Stock Input Account Missing Prevents Sale Validation for "Can Be Sold" Products

- **Issue**: Products marked as "Can be Sold" fail to validate with error: _"Cannot find a stock input account for the product..."_, typically when stock accounting is not configured for the product or category.
- **Solution**: Ensure the product has a Stock Input Account defined by inheriting from the category and explicitly setting it on the product.
  - Open the product form and go to the **General Information** tab.
  - Set **Product Type** to _Stockable Product_ and **Product Category** to _Raw Material_ (or appropriate category with accounting setup).
  - Navigate to **Inventory > Configuration > Product Categories**, select _Raw Material_.
  - In the **Account Stock Properties** section, copy the **Stock Input Account** value.
  - Return to the product, switch to the **Invoicing** tab.
  - Under **Stock Valuation**, paste the copied account into the **Stock Input Account** field.
  - Click **Save** to apply; the product can now be validated in sales operations.

---

## Validation Error on Bank Deposit: "The operation cannot be completed... [object with reference: account_id - account.id]"

- **Issue**: Bank deposit creation fails with the exact error:  
  _"Odoo Server Error - Validation Error: The operation cannot be completed, probably due to the following: deletion: you may be trying to delete a record while other records still reference it; creation/update: a mandatory field is not correctly set [object with reference: account_id - account.id]"_  
  This occurs when the customer is missing a required pre-payment account.
- **Solution**: Assign the Pre-Payment Account on the customer’s invoicing settings.
  - Identify the customer causing the error.
  - Open the customer record, go to **Edit > Invoicing** tab.
  - In the **Pre-Payment Accounting Entries** section, set:
    - **Pre-Payment Account**: _120000 Account Receivable_
  - Click **Save** to resolve the validation error and enable deposit processing.

---

## Document Access Denied: "Sorry, you are not allowed to access this document" for HR & Recruitment Models (skip.stage, hr.recruitment.note, appraisal.subject.line, hr.appraisal.parameter)

- **Issue**: Users receive the exact error:  
  _"Sorry, you are not allowed to access this document. Please contact your system administrator if you think this is an error."_  
  when accessing records in models such as `skip.stage`, `hr.recruitment.note`, `appraisal.subject.line`, or `hr.appraisal.parameter`. This occurs due to missing Access Control List (ACL) rules for these models, commonly after module customization or migration.
- **Solution**: Create individual ACL entries for each model to grant proper access.
  - Enable **Developer Mode**.
  - Go to **Settings > Technical > Access Controls List > Access Rights**.
  - Click **Create** and configure:
    - **Name**: Descriptive name (e.g., `HR Appraisal Models Access`)
    - **Object**: Set to one of the affected models (e.g., `appraisal.subject.line`)
    - **Group**: _Appraisals / Manager_ (or appropriate group)
    - **Permissions**: Enable **Read**, **Write**, **Create**, **Delete** as required
  - Repeat for each model:
    - `skip.stage`
    - `hr.recruitment.note`
    - `appraisal.subject.line`
    - `hr.appraisal.parameter`
  - Click **Save** for each entry. Access will be enforced immediately upon user session refresh.

---

## Accounting & Finance / Officer Access Persists Despite Being Unchecked in User Settings

- **Issue**: The _Accounting & Finance / Officer_ access checkbox remains effective for users even after being unchecked and saved in **Settings > Users & Companies > Manage Access Rights**, due to group membership being managed directly via the Groups interface, not the user form.
- **Solution**: Manually remove users from the group in the Groups configuration.
  - Enable **Developer Mode**.
  - Go to **Settings > Users & Companies > Groups**.
  - Search for and select the group: _Accounting & Finance / Officer_.
  - Click **Edit**, then remove any users who should not have officer privileges.
  - Click **Save** to enforce access restrictions.

---

## Customer Not Found in List View Despite Existing in Recent Documents

- **Issue**: A customer does not appear in **Sales > Orders > Customers** or **Accounting > Customers > Customers** list views, even though they are present in existing documents (e.g., SOVs, Invoices). This occurs because the customer is archived (inactive).
- **Solution**: Reactivate the customer record.
  - Locate a document (e.g., Sales Order, Invoice) linked to the customer.
  - Click on the customer name to open the partner form.
  - Ensure the **Active** checkbox is checked (if unchecked, enable it).
  - Click **Save**; the customer will now appear in customer list views.

---

## Purchases Approval Access Control via User Permission Settings

- **Issue**: Users lack or retain inappropriate access to approve purchase orders, requiring adjustment of Purchases module permissions.
- **Solution**: Modify user access rights to enable or restrict Purchases Manager privileges.
  - Go to **Settings > Users & Companies > Users**.
  - Select the target user and click **Edit**.
  - Navigate to the **Access Rights** tab.
  - Under the **Purchases** section:
    - Check **Manager** to grant approval rights (including validation of purchase orders).
    - Uncheck **Manager** to restrict to basic user permissions.
  - Click **Save** to apply changes; approval access will be updated immediately.

---

## Job Title-Specific Appraisal Parameters Not Loading in Appraisal Form

- **Issue**: When creating or editing an appraisal, parameters specific to a selected job title are not automatically displayed or applied, leading to inconsistent or manual evaluation criteria.
- **Solution**: Define job title-specific appraisal parameters and ensure they are linked via the job title field in the appraisal.
  - Go to **Human Resources > Appraisal > Appraisal Parameters > Create**.
  - Fill in the following:
    - **Job Title**: Select the relevant job title (e.g., Sales Executive, HR Officer)
    - **Out Of**: Enter maximum score value for the parameter
    - **Subject Name**: Define the evaluation criterion (e.g., Communication Skills, Punctuality)
  - Click **Save**.
  - Create a new **Appraisal** record.
  - In the appraisal form, set the **Job Title** field to the one configured above.
  - The system will automatically load the associated parameters defined under that job title.

---

## Import Error: "Unknown error during import: <class 'NameError'>: name 'UserError' is not defined at row X"

- **Issue**: During CSV import, Odoo throws the exact error:  
  _"Unknown error during import: <class 'NameError'>: name 'UserError' is not defined at row X"_  
  This typically occurs not due to a code-level `UserError` reference, but because the system encounters duplicate or conflicting records (e.g., already existing entries) which trigger an exception in a context where `UserError` is not properly imported or available in the execution scope.
- **Solution**: Remove or correct the duplicate/invalid rows indicated in the error message.
  - Identify the rows listed in the error (e.g., _row 173_, and the 7 following).
  - Open the CSV file and remove or deduplicate entries that conflict with existing records (e.g., duplicate codes, names, or external IDs).
  - Ensure all reference fields (e.g., product, partner, category) point to valid, pre-existing entries.
  - Re-upload the cleaned CSV file; the import should proceed without the `NameError`.

---

## Job Title-Specific Appraisal Parameters Not Loading When Job Title is Selected

- **Issue**: Appraisal parameters configured for specific job titles do not automatically appear when a job title is selected during appraisal creation, resulting in missing evaluation criteria.
- **Solution**: Define parameters linked to job titles and ensure they are loaded by selecting the job title in the appraisal form.
  - Navigate to **Human Resources > Appraisal > Appraisal Parameters**.
  - Click **Create**.
  - Fill in:
    - **Job Title**: Select the target job position (e.g., Accountant, Team Lead)
    - **Out Of**: Set the maximum score for the parameter
    - **Subject Name**: Enter the evaluation item (e.g., Attendance, Technical Proficiency)
  - Click **Save**.
  - Create a new **Appraisal** record.
  - In the appraisal form, update the **Job Title** field to match the one configured.
  - The system will automatically load the associated parameters defined under that job title.

---

## Helpdesk Access Configuration for Users: Allow Read and Create on Personal Tickets

- **Issue**: Users require access to view and create helpdesk tickets limited to their own records, but lack appropriate permissions by default.
- **Solution**: Assign the user to the correct access group to enable read and create rights for personal tickets.
  - Go to **Settings > Users & Companies > Users**.
  - Select the target user and click **Edit**.
  - In the **Access Rights** tab, locate the **Helpdesk** section.
  - Set access level to:
    - **User: Personal Tickets** — enables the ability to **Read** and **Create** tickets.
  - Save the changes; the user can now access and create tickets in the Helpdesk module, restricted to their own.

---

## Odoo Server Error/Warning: "The cost of 'Product X' is currently equal to 0" During Invoice or Inventory Validation

- **Issue**: Validation fails or triggers a warning with the exact message:  
  _"The cost of 'Product X' is currently equal to 0. Change the cost or the configuration of your product to avoid an incorrect valuation."_  
  This occurs when a **stockable product** has a zero or undefined cost, typically during **invoice validation** or **inventory operations**, and prevents completion under real-time inventory valuation (AVCO, Standard Price, FIFO).
- **Solution**: Assign a valid, positive cost to the affected product.
  - Go to **Inventory > Master Data > Products**.
  - Locate and open the product referenced in the error.
  - Navigate to the **Inventory** tab.
  - In the **Costing** section, set the **Cost** field to a non-zero value (e.g., procurement cost or market value).
  - Click **Save**.
  - Return to the invoice or stock move and retry validation.
- **Note**: This check is enforced to ensure accurate financial reporting and correct stock valuation in accounting entries.

---

## Stock Move Validation Fails: "Not Possible to Reserve More Than Available in Stock"

- **Issue**: Stock move fails to validate with error: _"It is not possible to reserve more products of <PRODUCT_NAME> than you have in stock"_, typically due to reservation conflicts, incorrect move state, or stale reservations blocking validation.
- **Solution**: Cancel the problematic stock move via a server action and reprocess.
  - **Step 1**: Activate **Developer Mode**.
  - **Step 2**: Go to **Inventory > [Selection from Dashboard]**, locate the problematic transfer, and note its **Reference**.
  - **Step 3**: Navigate to **Inventory > Reporting > Product Moves**, search using the reference, and confirm the move is stuck in _Reserved_ or _Assigned_ state despite insufficient stock.
  - **Step 4**: Create a server action:
    - Go to **Settings > Technical > Actions > Server Actions > Create**.
    - Set:
      - **Action Name**: `Cancel Stock Move Manually`
      - **Model**: `stock.move`
      - **Action To Do**: _Update the Record_
      - **Field**: `state`
      - **Evaluation Type**: _Value_
      - **Value**: `cancel`
    - Check **Create Contextual Action** to enable it in list views.
    - Click **Save**.
  - **Step 5**: Return to the **Product Moves** list, search for the move again, select it, click **Action > Cancel Stock Move Manually**.
  - **Step 6**: Go back to the original transfer, click **Mark as Done** or **Validate** — the system will recreate reservations cleanly if stock is available.

---

## HR Manager Cannot Delete Leave Requests Despite Sufficient Role

- **Issue**: Users in the _Employees / Manager_ group are unable to delete leave requests, even though they can create and edit them, due to missing delete access on the `hr.leave` model.
- **Solution**: Manually grant delete access to the HR Manager group via a custom access control rule.
  - **Step 1**: Activate **Developer Mode**.
  - **Step 2**: Go to **Settings > Technical > Database Structure > Models**.
  - **Step 3**: Search for model `hr.leave` (or create if not found — though typically exists).
  - **Step 4**: In the **Access Rights** tab, click **Add a line**:
    - **Group**: _Employees / Manager_
    - **Read Access**: ✅
    - **Write Access**: ✅
    - **Create Access**: ✅
    - **Delete Access**: ✅
    - **Access Rule Name**: `hr.leave.manager`
  - **Step 5**: Click **Save**.
  - After applying, HR Managers can now delete leave requests through the interface, provided the leave is in a deletable state (e.g., not approved or locked).

---

## Manufacturing Order "Mark as Done" Fails: "Expected singleton: mrp.bom(16, 28)" Due to Duplicate BOMs

- **Issue**: Clicking **Mark as Done** on a Manufacturing Order results in:  
  `ValueError: Expected singleton: mrp.bom(16, 28)`  
  This occurs when multiple active Bill of Materials (BOMs) exist for the same product template and BOM code, causing the system to retrieve more than one record where only one is expected.
- **Solution**: Identify and archive duplicate BOMs to ensure a single active BOM per product and code combination.
  - **Step 1**: Run SQL query to find duplicates:
    ```sql
    SELECT id, product_tmpl_id, product_id, code, type, active
    FROM mrp_bom
    WHERE product_tmpl_id IN (
        SELECT product_tmpl_id
        FROM mrp_bom
        GROUP BY product_tmpl_id, code
        HAVING COUNT(*) > 1
    )
    ORDER BY product_tmpl_id, code;
    ```
  - **Step 2**: Note the `product_tmpl_id` and `code` from the error and query results.
  - **Step 3**: Go to **Manufacturing > Master Data > Bill of Materials**.
  - **Step 4**: Search by the `code` from the results.
  - **Step 5**: For duplicate entries, select the outdated or incorrect BOM and click **Archive** (keep only the correct, active one).
  - **Step 6**: Retry **Mark as Done** on the manufacturing order — the error should now be resolved.

---

## Module Menus Visible to Unauthorized Users Despite Access Restrictions

- **Issue**: Menus and submenus from restricted modules appear in user accounts that should not have access, due to missing or incorrect access group assignments on the menu items.
- **Solution**: Manually restrict menu visibility by assigning proper access groups.
  - **Step 1**: Activate **Developer Mode**.
  - **Step 2**: Go to **Settings > Technical > User Interface > Menu Items**.
  - **Step 3**: Search for the menu name causing unwanted visibility.
  - **Step 4**: Open the menu item, click **Edit**, then go to the **Access Rights** tab.
  - **Step 5**: Add or modify the required **Groups** to restrict access (e.g., only _Accounting / Manager_, _Inventory / User_, etc.).
  - **Step 6**: Repeat for associated **Submenus** to ensure full access control.
  - **Step 7**: Save changes; menu items will now only appear for users with the assigned groups.

---

## Enable Multiple Sales Prices by Region via Pricelist Selection

- **Issue**: Sales teams cannot apply region-specific pricing (e.g., Addis Ababa vs. other regions), leading to incorrect quotes and margin inconsistencies.
- **Solution**: Configure and use regional pricelists to enable location-based pricing with manual selection at quotation creation.
  - **Step 1**: Enable advanced pricing:
    - Go to **Sales > Configuration > Settings**.
    - Check **Multiple Sales Prices per Product**.
    - Click **Save**.
  - **Step 2**: Create regional pricelists:
    - Navigate to **Sales > Catalog > Pricelists > Create**.
    - Set **Name** (e.g., "Ethiopia - Addis Ababa", "Ethiopia - Regions").
    - Leave **Country Groups** blank to allow manual assignment.
  - **Step 3**: Define price rules:
    - In **Pricelist Items**, click **Add an item**.
    - Set:
      - **Apply On**: Product
      - **Product**: Select target product (e.g., _Steel Nail – 5 CM_)
      - **Compute Price**: Fixed Price
      - **Fixed Price**: Enter region-specific amount
    - Click **Save**.
  - **Step 4**: Use in quotations:
    - When creating a new quotation (**Sales > Orders > Create**):
      1. Select the **Customer**.
      2. Manually set the **Pricelist** field to the appropriate regional pricelist.
      3. Add order lines — prices will auto-apply based on the selected pricelist.
  - **Note**: Pricelist must be set **before** adding products to ensure correct pricing is loaded.

---

## Create or Update Sales Location with Associated Pricelist

- **Issue**: Sales locations must be explicitly linked to a pricelist to enable automatic pricing in quotations, but the association is not intuitive or documented.
- **Solution**: Use the Sales Locations interface to create new locations or update existing ones with a default pricelist.
  - Go to **Sales > Orders > Sales Locations > Manage Locations**.
  - Click **Create** to add a new location or **Edit** an existing one.
  - Fill in the following fields:
    - **Sale Location**: Name of the location (e.g., Addis Ababa, Dire Dawa)
    - **Description**: Optional details about the location
    - **Default Pricelist**: Select the pricelist to apply automatically when this location is chosen in a quotation
  - Click **Save**.
  - Once saved, selecting this location in a sales order will automatically apply the linked pricelist, ensuring correct regional pricing.

---

## Automatically Apply Partner-Specific Payment Terms in Quotations

- **Issue**: Quotations do not automatically reflect the correct payment terms for a customer, leading to inconsistencies in invoicing and cash flow expectations.
- **Solution**: Set the desired payment terms on the customer record; Odoo will automatically propagate them to new quotations.
  - Go to **Sales > Customers** and select the partner.
  - Click **Edit**.
  - In the **Invoicing** tab, locate **Customer Payment Terms**.
  - Select the appropriate term (e.g., _Immediate Payment_, _15 Days_, etc.).
  - Click **Save**.
  - When creating a new quotation for this customer, the **Payment Terms** field will be automatically populated based on the partner’s configuration.
  - Ensures consistent and accurate payment terms across all sales documents for the customer.

---

## Created User-Friendly Sequences for Purchase and Payment Requests

- **Issue**: Purchase and payment requests use internal database IDs as references, which are not user-friendly, lack context, and hinder traceability in communication and reporting.
- **Solution**: Implement human-readable sequences with prefixes `PUR-` and `PYR-` for clear identification.
  - **Step 1**: Activate **Developer Mode**.
  - **Step 2**: Go to **Settings > Technical > Sequences & Identifiers > Sequences**.
  - **Step 3**: Create new sequence for **Purchase Request**:
    - **Name**: Purchase Request
    - **Sequence Code**: `purchase.request`
    - **Prefix**: `PUR-`
    - **Sequence Size**: `5`
    - **Next Number**: `1`
    - **Step**: `1`
  - **Step 4**: Create new sequence for **Payment Request**:
    - **Name**: Payment Request
    - **Sequence Code**: `payment.request`
    - **Prefix**: `PYR-`
    - **Sequence Size**: `5`
    - **Next Number**: `1`
    - **Step**: `1`
  - Ensure the corresponding models use these sequences in their `create()` methods or via XML reference.
  - After setup, new requests will be numbered as `PUR-00001`, `PYR-00001`, etc., improving clarity and document tracking.

---

## Setup Automatic Backup in Odoo

- [Tutorial Video](https://www.youtube.com/watch?v=-29T309lw5U)

---

## Bulk Update `res_partner` Initial Balances in Odoo

**[This](https://docs.google.com/spreadsheets/d/1ohVzd0woPhkMUe9Pqgz8GaS5mukNPMGvil8_dP5ZKzA/edit?usp=sharing)** Google Sheets template allows you to **instantly generate SQL `UPDATE` statements** for setting the `inital_balance` of partners in Odoo.

### How it Works

1. Fill in **Column A** with `partner_code`.
2. Fill in **Column C** with `current_balance`.
3. The **ARRAYFORMULA** automatically generates the corresponding SQL `UPDATE` statements in another column.
4. Copy the generated queries and run them in your Odoo database.

### Formula Used

```excel
=ARRAYFORMULA(
  IF(A2:A="","",
    "UPDATE res_partner SET inital_balance = " & C2:C & " WHERE partner_code = '" & A2:A & "';"
  )
)
```

## 🚨 Database Cleanup Script (Year-End Reset)

**⚠️ WARNING – READ THIS FIRST ⚠️**  
This script **irreversibly deletes transactional data** (sales, purchases, payments, accounting, inventory, HR, CRM, quality, fleet, etc.).

- ✅ Always **backup your database** before running.
- ✅ Double-check that you are connected to the **correct target database** (e.g., `T19` instead of production).
- ✅ Run in a safe environment (staging/test) before applying to production.
- ❌ Do not run casually — this is meant for **planned year-end resets** only.

### Purpose

- Wipe old transactional records while preserving master data (partners, products, configurations).
- Reset important sequences (sale orders, invoices, stock pickings, production orders, payments, etc.).
- Optimize the database via **VACUUM** and **REINDEX**.

### Benefits

- Ensures a **lean, fast, and purposeful database** at the start of the new year.
- Avoids carrying forward unnecessary clutter.
- Provides a **repeatable, auditable process** for annual cleanup.

### Usage

1. Backup your database.
2. Confirm you are connected to the **intended database** (e.g., `T19`).
3. Open the `.txt` file containing the SQL script.
4. Execute it in your PostgreSQL console.

👉 [View the cleanup script](./Files/transactional_data_nuke_script.txt)

---

# Odoo ERP Access Rights Matrix

This repository contains the **Odoo ERP Access Rights Matrix**, a structured reference of how access rights are granted across departments.

## Structure

- Each **worksheet** in the Excel file represents a **department** (e.g. Finance, Procurement, HR, Sales, Manufacturing, etc.), arranged alphabetically.

📂 **[`Odoo ERP Access Rights Matrix`](https://docs.google.com/spreadsheets/d/1ZXbapSx-rJNSuL6kyG_qzd-jaXd-oAmvmHZmoYqik_s/edit?usp=sharing)**

---
