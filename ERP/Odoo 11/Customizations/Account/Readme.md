# Odoo 11 Account Customizations

This section covers customizations to Odoo 11’s accounting module, including invoice validation fixes, partner balance methods, and new modules for customer balance exports.

---

## Added SOV Location to Invoice XML for Location-Based Reporting

- **Issue**: Invoice XML files lack the warehouse or delivery location inherited from the source Sales Order, preventing accurate classification in location-based financial or logistics reports.
- **Solution**: Extend the invoice XML generation to include the `location` field from the related SOV.
  - In `account/models/account_invoice.py`, within the `create_xml` method, add:
    ```python
    location_name = sale_order.location.name if sale_order and sale_order.location else 'No Location'
    childOfLocation = root.createElement('location')
    childOfLocation.appendChild(root.createTextNode(location_name))
    second_root.appendChild(childOfLocation)
    ```
  - This ensures the `<location>` tag is included in the generated XML using the location defined on the source quotation.
  - Example output:
    ```xml
    <location>Nairobi Store</location>
    ```
  - Restart the Odoo service and upgrade the **Accounting** module.
  - After upgrade, all validated invoices will include the SOV’s location in their XML, enabling accurate grouping and filtering in location-classified reports.

---

## Invoice XMLs Now Stored in Organized Date-Based Subdirectories (YYYY/MM/MM_DD_YYYY)

- **Issue**: All generated invoice XML files were saved in a single directory, causing performance degradation over time and making manual navigation and backups difficult.
- **Solution**: Reorganize the output path to use a hierarchical structure: `/YYYY/MM/MM_DD_YYYY` for improved file management and faster retrieval.

  - In `account/models/account_invoice.py`, within the `create_xml` method, update the path logic:

    ```python
    BASE_OUTPUT_DIR = r"C:\Users\Loj\XMLs\Invoices"
    now = datetime.today()
    year = now.strftime('%Y')          # e.g., 2025
    month = now.strftime('%B')         # e.g., May
    date_folder = now.strftime('%b_%d_%Y').upper()  # e.g., MAY_16_2025
    timestamp = now.strftime('%y%m%d%H%M%S')        # e.g., 2505160801

    invoices_path = os.path.normpath(os.path.join(BASE_OUTPUT_DIR, year, month, date_folder))
    ```

  - The system now creates and saves XMLs in structured folders:
    ```
    C:\Users\Loj\XMLs\Invoices\2025\May\MAY_16_2025\Inv-SOV001-2505160801.xml
    ```
  - Automatically creates directories if they don't exist.
  - Restart the Odoo service and upgrade the **Accounting** module to apply changes.
  - Result: Cleaner organization, faster file access, and easier daily backup isolation.

---

## Enforce Required Customer Payment Terms on Partner Save

- **Issue**: Partners can be saved without a configured Customer Payment Term, leading to missing or incorrect terms in quotations and invoices.
- **Solution**: Add a model constraint to enforce that `property_payment_term_id` is set before saving a customer record.
  - Edit `account/models/partner.py` and add the following constraint:
    ```python
    @api.constrains('property_payment_term_id')
    def _check_property_payment_term(self):
        for record in self:
            payment_term = record.sudo().with_context(force_company=record.company_id.id).property_payment_term_id
            if not payment_term:
                raise ValidationError("Customer Payment Terms must be set.")
    ```
  - This ensures that any attempt to save a partner (customer) without a defined payment term will be blocked with a clear error message.
  - Restart the Odoo service and upgrade the **Accounting** module.
  - After activation, users must select a payment term before saving a customer, improving data consistency and downstream accuracy in sales and invoicing.

---
