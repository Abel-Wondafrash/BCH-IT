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

## Enhanced XML Generation for Quotations: Support Blank, Finance, Store, and Combined Copy Types

- **Issue**: Printing single or dual copies (1 or 2) of SOVs leads to paper wastage when one copy (e.g., Finance or Store) fails due to printer jams or errors, with no option to selectively generate specific copy types.
- **Solution**: Redesign XML generation to support explicit copy type tagging (`B`, `F`, `S`, `FS`) and update UI actions for precise control.

  - **Step 1: Modify `sale.py` – Add `copy_type` to XML output**
    - In `create_xml` method, add:
      ```python
      copy_type = self.env.context.get('copy_type', 'B')  # Default: Blank
      ```
    - Inject into XML:
      ```python
      childOfproduct = root.createElement('copy_type')
      childOfproduct.appendChild(root.createTextNode(str(copy_type)))
      second_root.appendChild(childOfproduct)
      ```
  - **Step 2: Update `sale_views.xml` – Replace old buttons**
    - Remove legacy buttons for _LOJ • 1 Copy_ and _LOJ • 2 Copy_ from the form view.
    - Add new button:
      ```xml
      <button name="action_confirm_create_xml" type="object" string="LOJ • Finance &amp; Store" class="oe_highlight"
              confirm="Are you sure you want to send Finance &amp; Store copies to Loj?"
              context="{'copies': 1, 'copy_type': 'FS'}"/>
      ```
  - **Step 3: Replace server actions for bulk list-view operations**

    - Remove old actions: _LOJ • 1 Copy_, _LOJ • 2 Copy_.
    - Add new contextual actions:

      ```xml
      <!-- LOJ • Blank -->
      <record id="action_sale_order_loj_blank" model="ir.actions.server">
        <field name="name">LOJ • Blank</field>
        <field name="model_id" ref="sale.model_sale_order"/>
        <field name="binding_model_id" ref="sale.model_sale_order"/>
        <field name="binding_view_types">list</field>
        <field name="state">code</field>
        <field name="code">
          records.with_context(copies=1, copy_type='B').action_confirm_create_xml()
        </field>
      </record>

      <!-- LOJ • Finance -->
      <record id="action_sale_order_loj_finance_copy" model="ir.actions.server">
        <field name="name">LOJ • Finance</field>
        <field name="model_id" ref="sale.model_sale_order"/>
        <field name="binding_model_id" ref="sale.model_sale_order"/>
        <field name="binding_view_types">list</field>
        <field name="state">code</field>
        <field name="code">
          records.with_context(copies=1, copy_type='F').action_confirm_create_xml()
        </field>
      </record>

      <!-- LOJ • Store -->
      <record id="action_sale_order_loj_store_copy" model="ir.actions.server">
        <field name="name">LOJ • Store</field>
        <field name="model_id" ref="sale.model_sale_order"/>
        <field name="binding_model_id" ref="sale.model_sale_order"/>
        <field name="binding_view_types">list</field>
        <field name="state">code</field>
        <field name="code">
          records.with_context(copies=1, copy_type='S').action_confirm_create_xml()
        </field>
      </record>

      <!-- LOJ • Finance & Store -->
      <record id="action_sale_order_loj_finance_store" model="ir.actions.server">
        <field name="name">LOJ • Finance &amp; Store</field>
        <field name="model_id" ref="sale.model_sale_order"/>
        <field name="binding_model_id" ref="sale.model_sale_order"/>
        <field name="binding_view_types">list</field>
        <field name="state">code</field>
        <field name="code">
          records.with_context(copies=1, copy_type='FS').action_confirm_create_xml()
        </field>
      </record>
      ```

  - **Step 4**: Restart the Odoo service and upgrade the **Sales** module.
  - After upgrade, users can select quotations and choose _Blank_, _Finance_, _Store_, or _Finance & Store_ from the **Action** menu, generating XMLs with accurate `copy_type` for targeted, waste-minimized printing.

---

## Added Warehouse Location to SOV XML Export

- **Issue**: The generated SOV XML lacks warehouse location information, which is critical for logistics, picking, and fulfillment tracking.
- **Solution**: Extend the SOV XML generation to include the `location` field from the quotation/sales order.
  - In `sale.py`, within the `create_xml` method, add:
    ```python
    location_name = self.location.name if self.location else 'No Location'
    childOfLocation = root.createElement('location')
    childOfLocation.appendChild(root.createTextNode(location_name))
    second_root.appendChild(childOfLocation)
    ```
  - This injects a `<location>` tag into the XML output containing the name of the assigned warehouse location.
  - Example output in XML:
    ```xml
    <location>Stock</location>
    ```
  - Restart the Odoo service and upgrade the **Sales** module to apply the change.
  - Now, every SOV XML export will include location data, improving traceability and operational accuracy.

---

## Enforced Required Fields: Payment Terms, Plate Number, and Location in Sales Orders

- **Issue**: Users frequently issue quotations without setting **Payment Terms**, **Plate Number**, or **Location**, leading to operational delays, incorrect dispatch, and invoicing issues.
- **Solution**: Make the fields mandatory at the model level to prevent saving or confirming quotations without them.
  - **Step 1**: Update `sale/models/sale.py` in `SaleOrder` class:
    ```python
    payment_term_id = fields.Many2one(
        'account.payment.term',
        string='Payment Terms',
        required=True,
        default=lambda self: self.env.ref('account.account_payment_term_immediate').id
    )
    ```
  - **Step 2**: Update `sales_location/models/sale.py` in `SaleOrder` class:
    ```python
    location = fields.Many2one('sale.locations', string="Location", required=True)
    plate_no = fields.Char(string='Plate Number', required=True)
    ```
  - **Step 3**: Restart the Odoo service.
  - **Step 4**: Upgrade both modules:
    - Go to **Apps > sale** > Upgrade
    - Go to **Apps > sales_location** > Upgrade
  - After upgrade, users **must** fill in **Payment Terms**, **Plate Number**, and **Location** before saving or confirming a quotation, ensuring completeness for downstream operations.

---
