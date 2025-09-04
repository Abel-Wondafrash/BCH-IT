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

## Relocate "Location" Field in Quotation Form to Follow "Sales Type"

- **Issue**: The **Location** field is buried in the _Other Information_ notebook tab of the quotation form, making it easy to overlook despite being a required field for operational fulfillment.
- **Solution**: Move the **Location** field to a prominent position immediately after **Sales Type** in the main form for improved visibility and workflow compliance.
  - Edit `sales_location/views/sale_views.xml` and add:
    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <odoo>
      <data>
        <!-- Inherit Sales Order Form View -->
        <record id="view_order_form_inherit_sales_location" model="ir.ui.view">
          <field name="name">sale.order.form.inherit.sales.location</field>
          <field name="model">sale.order</field>
          <field name="inherit_id" ref="sale.view_order_form"/>
          <field name="arch" type="xml">
            <!-- Insert location field right after sales_type -->
            <xpath expr="//field[@name='sales_type']" position="after">
              <field name="location"/>
            </xpath>
          </field>
        </record>
      </data>
    </odoo>
    ```
  - Save the file.
  - Restart the Odoo service.
  - Upgrade the **sales_location** module via **Apps > sales_location > Upgrade**.
  - After upgrade, the **Location** field appears directly after **Sales Type**, ensuring earlier user input and reducing missed entries.

---

## Automatically Update Order Line Prices When Pricelist Changes in Quotations

- **Issue**: Changing the pricelist on a quotation does not automatically update existing order line prices, forcing sales users to manually re-add products to apply correct regional or customer-specific pricing.
- **Solution**: Implement an `@onchange` method to dynamically recompute and apply prices from the selected pricelist to all order lines.
  - Add the following method to the `sale.order` model in the custom module:
    ```python
    @api.multi
    @api.onchange('pricelist_id')
    def _onchange_pricelist_update_order_lines(self):
        for order in self:
            if not order.pricelist_id:
                continue  # Skip if no pricelist set
            for line in order.order_line:
                if not line.product_id:
                    continue  # Skip lines without a product
                try:
                    # Get updated price using the new pricelist
                    price = order.pricelist_id.get_product_price(
                        line.product_id,
                        line.product_uom_qty,
                        order.partner_id
                    )
                    line.price_unit = price
                except Exception as e:
                    raise UserError(
                        _("Failed to update price for product '%s'.\n\nError: %s") % (
                            line.product_id.display_name,
                            str(e)
                        )
                    )
    ```
  - This ensures that when a user changes the **Pricelist** field, all existing order lines are recalculated using the correct pricing rules (e.g., regional, volume-based).
  - Restart the Odoo service and upgrade the relevant module (e.g., `sale` or custom pricing module).
  - After implementation, switching pricelists will immediately reflect accurate prices across all lines without requiring product re-entry.

---

## Auto-Fill Pricelist Based on Selected Location in Quotations

- **Issue**: Sales users must manually select the correct pricelist after choosing a location, increasing the risk of pricing errors and reducing efficiency.
- **Solution**: Automatically set the **Pricelist** field based on the selected **Location**, and make it read-only to enforce consistency.
  - **Step 1**: Extend the `sales_location` model to include a default pricelist on location:
    In `sales_location/models/sales_location.py`, add:
    ```python
    pricelist_id = fields.Many2one('product.pricelist', string="Default Pricelist")
    ```
  - **Step 2**: Implement auto-fill logic in `sale.py`:
    In `sales_location/models/sale.py`, add:
    ```python
    @api.onchange('location')
    def _onchange_location_set_pricelist(self):
        if self.location and self.location.pricelist_id:
            self.pricelist_id = self.location.pricelist_id
    ```
  - **Step 3**: Make the **Pricelist** field read-only in the form view (optional, for enforcement):
    Update the form view via XML:
    ```xml
    <field name="pricelist_id" readonly="1"/>
    ```
  - Restart the Odoo service and upgrade the **sales_location** module.
  - After setup, selecting a **Location** will automatically populate the **Pricelist**, ensuring accurate, location-specific pricing without manual intervention.

---

## Add Menu and Action to Manage Sales Locations with Required Pricelist

- **Issue**: There is no direct UI access to manage sales locations, and the critical `pricelist_id` field is not enforced, leading to incomplete configurations and pricing failures.
- **Solution**: Create a dedicated menu and action to manage locations, and enforce pricelist assignment.

  - **Step 1**: Create `sale_locations/views/sale_locations_view.xml`:

    ```xml
    <odoo>
      <!-- Tree View -->
      <record id="view_sale_locations_tree" model="ir.ui.view">
        <field name="name">sale.locations.tree</field>
        <field name="model">sale.locations</field>
        <field name="arch" type="xml">
          <tree string="Sales Locations">
            <field name="name"/>
            <field name="description"/>
            <field name="is_rural"/>
            <field name="pricelist_id"/>
          </tree>
        </field>
      </record>

      <!-- Form View -->
      <record id="view_sale_locations_form" model="ir.ui.view">
        <field name="name">sale.locations.form</field>
        <field name="model">sale.locations</field>
        <field name="arch" type="xml">
          <form string="Sales Location">
            <sheet>
              <group>
                <field name="name"/>
                <field name="description"/>
                <field name="is_rural"/>
                <field name="pricelist_id"/>
              </group>
            </sheet>
          </form>
        </field>
      </record>

      <!-- Action -->
      <record id="action_sales_locations" model="ir.actions.act_window">
        <field name="name">Sales Locations</field>
        <field name="res_model">sale.locations</field>
        <field name="view_mode">tree,form</field>
      </record>

      <!-- Menu Items -->
      <menuitem id="menu_sales_location_root"
                name="Sales Locations"
                parent="sale.sale_order_menu"
                sequence="30"/>
      <menuitem id="menu_sales_locations"
                name="Manage Locations"
                parent="menu_sales_location_root"
                action="action_sales_locations"
                sequence="10"/>
    </odoo>
    ```

  - **Step 2**: Make `pricelist_id` required in `sales_location/models/sales_location.py`:
    ```python
    pricelist_id = fields.Many2one(
        'product.pricelist',
        string="Default Pricelist",
        required=True
    )
    ```
  - **Step 3**: Restart the Odoo service and upgrade the **sales_location** module.
  - After upgrade, users can access **Sales > Sales Locations > Manage Locations** to create and manage location records, with enforced pricelist assignment.

---

## Removed Stock Availability Warning Modal in Sales Orders

- **Issue**: The modal _"You plan to sell X but only have Y available in warehouse Z"_ appears on every order line, requiring unnecessary confirmation clicks. Sales and marketing operate on forward commitments, not real-time stock, making the prompt redundant and inefficient.
- **Solution**: Disable the availability warning by commenting out the `@api.onchange` decorator and method call for `_onchange_product_id_check_availability`.
  - Edit `sale_stock/models/sale_order.py`.
  - Locate the method `_onchange_product_id_check_availability`.
  - **Step 1**: Comment out the `@api.onchange` decorator:
    ```python
    # @api.onchange('product_id', 'product_uom_qty', 'product_uom', 'warehouse_id')
    def _onchange_product_id_check_availability(self):
        # Method body remains, but not triggered on change
    ```
  - **Step 2**: Comment out the method call in the same file (if invoked elsewhere):
    ```python
    # self._onchange_product_id_check_availability()
    ```
  - Restart the Odoo service and upgrade the **Sale** module.
  - After deployment, users can add products to quotations and orders without interruption, regardless of current stock levels — aligning with business workflow.

---

## Removed Unused Batch Number Field and Input Prompt in Sales Order Lines

- **Issue**: The **Batch Number** field (`batch_no`) was marked as required but used inconsistently—sales teams entered arbitrary values to bypass validation. The field appeared in both the order line creation form and list view despite having no operational or traceability purpose.
- **Solution**: Remove the required constraint and hide the field from all sales order line interfaces.
  - **Step 1**: Update the model in `sale/models/sale.py`:
    ```python
    batch_no = fields.Char('Batch Number')  # Removed required=True
    ```
  - **Step 2**: Hide the field in the form views via `sale/views/sale_views.xml`:
    - In the **Order Lines notebook section**:
      ```xml
      <field name="batch_no" invisible="1"/>
      ```
    - In the **Create Order Lines** popup or form:
      ```xml
      <field name="batch_no" invisible="1"/>
      ```
  - **Step 3**: Restart the Odoo service and upgrade the **Sale** module.
  - After deployment, the `batch_no` field is no longer visible or enforced, eliminating unnecessary input and streamlining the sales workflow without affecting data integrity.

---

## Include ProductWarehouseId in SOV XML for Consistent Cross-System Product Identification

- **Issue**: The SOV XML uses generic product codes that do not align with warehouse-specific identifiers used in external systems (CNET, Peachtree), leading to mismatches during import and reconciliation.
- **Solution**: Replace the default product code in the XML with `productWarehouseId` — a warehouse-specific code from the `product.descriptor` model — falling back to template code if not found.
  - In `sale/models/sale.py`, update the code generation logic:
    ```python
    product = search_result_order_line.product_id
    sale_order = search_result_order_line.order_id
    product_descriptor = self.env['product.descriptor'].search([
        ('product_temp', '=', product.product_tmpl_id.id),
        ('warehouse_id', '=', sale_order.warehouse_id.id)
    ], limit=1)
    _logger.info("Product: %s, Template: %s, Warehouse: %s, Descriptor: %s, Code: %s",
                 product.name, product.product_tmpl_id.name, sale_order.warehouse_id.name,
                 product_descriptor, product_descriptor.productWarehouseId if product_descriptor else 'None')
    code_value = product_descriptor.productWarehouseId if product_descriptor else product.product_tmpl_id.code or ''
    childOfproduct = root.createElement('code')
    childOfproduct.appendChild(root.createTextNode(str(code_value)))
    fourth_root_child.appendChild(childOfproduct)
    ```
  - This ensures the `<code>` tag in the XML reflects the correct warehouse-specific product ID as defined in `product.descriptor`.
  - Restart the Odoo service and upgrade the **Sale** module.
  - After update, generated SOV XMLs will contain accurate `ProductWarehouseId`, ensuring seamless integration with Finance systems.

---
