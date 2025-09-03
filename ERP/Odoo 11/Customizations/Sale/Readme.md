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
