# Odoo 11 Sale Customizations

This section documents customizations to the Odoo 11 sales module, including unit of measure enhancements, warehouse restrictions, and bulk quotation XML generation.

---

## Sales Unit of Measure: Dynamic PACK vs PIECES Handling in Sales Orders and Reports

- **Issue**: Products are sold in different units (e.g., PACK, PIECES), but the system lacks a dedicated field to define a per-product Sales Unit of Measure (UoM), leading to inconsistent or hardcoded reporting headers (e.g., always "Pack").
- **Solution**: Extend the product template with a `uom_sale_id` field and dynamically reflect it in the sales order report.
  - **Step 1**: Add `uom_sale_id` field in `product_template.py`:
    ```python
    uom_sale_id = fields.Many2one(
        'product.uom',
        'Sales Unit of Measure',
        default=_get_default_uom_sale_id,
        help="Default Unit of Measure used for Sales. This is typically PACK. Only change if otherwise."
    )
    ```
  - **Step 2**: Implement default method:
    ```python
    def _get_default_uom_sale_id(self):
        pack_uom = self.env['product.uom'].search([('name', '=', 'Pack')], limit=1)
        return pack_uom.id if pack_uom else self._get_default_uom_id()
    ```
  - **Step 3**: Add field to form view (`product_views.xml`):
    ```xml
    <field name="uom_sale_id" groups="product.group_uom" options="{'no_create': True}"/>
    ```
  - **Step 4**: Update QWeb report (`sale.report_saleorder_document`) for dynamic header:
    ```xml
    <th t-if="doc.order_line[0].product_id.uom_sale_id">
        <t t-esc="doc.order_line[0].product_id.uom_sale_id.name"/>
    </th>
    <th t-if="not doc.order_line[0].product_id.uom_sale_id">Pack</th>
    ```
  - **Step 5**: Upgrade modules:
    - Go to **Apps**, clear default filter, search for _Inventory Management_, click **Upgrade**.
    - Repeat for _Sales_ module.
  - After upgrade, set `uom_sale_id` per product; the sales order report header will now reflect the correct UoM (e.g., "Pieces", "Box") or default to "Pack".

---

## Bulk XML Generation for Multiple Quotations in List View

- **Issue**: Users can generate XML files from individual quotations using form buttons ("LOJ • 1 Copy", "LOJ • 2 Copy"), but lack the ability to perform this action in bulk from the list view.
- **Solution**: Add server actions to enable bulk XML generation with specified copy count via the Action menu.

  - Edit the file: `sale/views/sale_views.xml`.
  - Insert the following records before the closing `</odoo>` tag:

    ```xml
    <!-- Server Action for LOJ • 1 Copy -->
    <record id="action_sale_order_loj_1_copy" model="ir.actions.server">
      <field name="name">LOJ • 1 Copy</field>
      <field name="model_id" ref="sale.model_sale_order"/>
      <field name="binding_model_id" ref="sale.model_sale_order"/>
      <field name="binding_view_types">list</field>
      <field name="state">code</field>
      <field name="code">
        records.with_context(copies=1).action_confirm_create_xml()
      </field>
    </record>

    <!-- Server Action for LOJ • 2 Copy -->
    <record id="action_sale_order_loj_2_copy" model="ir.actions.server">
      <field name="name">LOJ • 2 Copy</field>
      <field name="model_id" ref="sale.model_sale_order"/>
      <field name="binding_model_id" ref="sale.model_sale_order"/>
      <field name="binding_view_types">list</field>
      <field name="state">code</field>
      <field name="code">
        records.with_context(copies=2).action_confirm_create_xml()
      </field>
    </record>
    ```

  - Save the file.
  - Restart the Odoo service.
  - Upgrade the **Sales** module via **Apps > Sales > Upgrade**.
  - After upgrade, select multiple quotations in **Sales > Quotations**, click **Action**, and choose either _LOJ • 1 Copy_ or _LOJ • 2 Copy_ to generate XML files in bulk with the corresponding `<copies>` value.

---

## Include Quotation Origin (SOV #) in Invoice XML and Customize Output Path

- **Issue**: Generated invoice XML files lack the source quotation (SOV) reference, use generic naming, and are saved in the default Odoo server directory, making traceability and organization difficult.
- **Solution**: Modify the `create_xml` method in `account_invoice.py` to embed the quotation origin, rename the file as `Inv-SOV-#####.xml`, and save to a dedicated directory.
  - Edit the file: `account/models/account_invoice.py`, locate the `create_xml` method.
  - Update the logic to:
    - Extract the linked sale order using `self.origin`.
    - Set a fixed output directory: `F:\Loj\XMLs\Invoices`.
    - Name the file in the format: `Inv-SOV-<SOV#>-<timestamp>.xml`.
    - Ensure the directory is created if it doesn't exist.
  - Key code additions:
    ```python
    sale_order = self.env['sale.order'].search([('name', '=', self.origin)], order='id desc', limit=1)
    OUTPUT_DIR = r"F:\Loj\XMLs\Invoices"
    name = 'Inv-' + (self.origin or self.name) + '-'
    now = datetime.today().strftime('%y%m%d%H%M%S')
    invoices_path = os.path.normpath(OUTPUT_DIR)
    if not os.path.exists(invoices_path):
        os.makedirs(invoices_path)
    OUTPUT_DIR = os.path.join(invoices_path, f"{name}{now}.xml")
    ```
  - Restart the Odoo service.
  - Upgrade the **Accounting** module via **Apps > Accounting > Upgrade**.
  - After validation, invoices will generate XMLs in the dedicated folder with the quotation origin in the filename and full traceability.

---
