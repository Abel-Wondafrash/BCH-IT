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

## HR Appraisal Access Denied: "Sorry, you are not allowed to access this document" on appraisal.subject.line1

- **Issue**: Users receive the exact error:  
  _"Odoo Server Error - Access Error: Sorry, you are not allowed to access this document. Document model: appraisal.subject.line1"_  
  when opening appraisal records created prior to module update. This is caused by missing Access Control List (ACL) permissions for the `appraisal.subject.line1` model.
- **Solution**: Create an ACL entry to grant full access to the Appraisals/Manager group.
  - Enable **Developer Mode**.
  - Navigate to **Settings > Technical > Access Controls List > Access Rights**.
  - Click **Create**.
  - Set the following values:
    - **Name**: `hr.appraisal`
    - **Object**: `appraisal.subject.line1`
    - **Group**: _Appraisals / Manager_
    - **Read**, **Write**, **Create**, **Delete**: ✅ Enabled
  - Click **Save** to apply. Affected users can now access the appraisal records.

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

## Restrict Visibility of Confirm, Done, Cancel Buttons in payment_request Module via Custom Access Group

- **Issue**: Standard users must be restricted from seeing or using key action buttons ([Confirm], [Done], [Cancel]) in the `payment_request` module, requiring granular access control.
- **Solution**: Create a custom security group and apply it to target buttons through XML view and security definition.
  - **Step 1**: Identify the target buttons (`Confirm`, `Done`, `Cancel`) in the module’s `models.py` or corresponding view files.
  - **Step 2**: Edit the view in `security/views.xml` (or appropriate view file under `security/` folder):
    - Add the `groups` attribute to each button:
      ```xml
      <button name="button_confirmed" string="Confirm" type="object" class="oe_highlight" groups="payment_request.group_payment_manager"/>
      ```
    - Repeat for `button_done` and `button_cancel` with the same group restriction.
  - **Step 3**: Create `security/security_groups.xml` with:
    ```xml
    <odoo>
      <data noupdate="1">
        <record id="group_payment_manager" model="res.groups">
          <field name="name">Payment Manager</field>
          <field name="category_id" eval="52"/> <!-- Ensure 52 corresponds to target category (e.g., 'Extra Rights') -->
        </record>
      </data>
    </odoo>
    ```
    - Confirm `category_id` by running:
      ```sql
      SELECT id, name FROM ir_module_category;
      ```
      Use the integer `id` in `eval`, not `ref`.
  - **Step 4**: Update `__manifest__.py` to include:
    ```python
    'data': [
        'security/security_groups.xml',
        # ... other data files
    ],
    ```
  - **Step 5**: Upgrade the module:
    - Go to **Apps**, clear default filter, search for _payment_request_.
    - Click **Upgrade** to apply security changes.

---
