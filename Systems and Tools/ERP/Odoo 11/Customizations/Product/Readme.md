# Odoo 11 Product Customizations

This section documents customizations to the Odoo 11 product module, including field additions and configuration changes to enhance product management and reporting.

---

## Added "Is Excisable" Field to Sellable Products for Excise Tax Identification

- **Issue**: No way to identify which products are subject to excise tax, making it difficult to apply correct tax treatment during sales and reporting.
- **Solution**: Add a Boolean field `is_excisable` to the product template, visible only for sellable products.
  - **Step 1**: Extend the model in `product/models/product_template.py`:
    ```python
    is_excisable = fields.Boolean(
        string='Is Excisable',
        default=False,
        help="Indicates whether this product is subject to excise tax."
    )
    ```
  - **Step 2**: Add the field to the form view in `product/views/product_template_views.xml`:
    ```xml
    <xpath expr="//field[@name='supplier_taxes_id']" position="before">
        <field name="is_excisable" attrs="{'invisible': [('sale_ok', '=', False)]}"/>
    </xpath>
    ```
    - The field appears only when **Can be Sold** is enabled.
  - Restart the Odoo service and upgrade the **Product** module.
  - After upgrade, users can mark applicable products as excisable, enabling accurate tax classification and downstream reporting.

---
