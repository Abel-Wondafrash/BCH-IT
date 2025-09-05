# Odoo 11 Custom Modules

This section documents custom-developed modules for Odoo 11, including new functionality, field extensions, and enhancements to support business-specific requirements.

---

## Created Partner Customization Module to Rename and Protect Opening Balance Field

- **Issue**: The `inital_balance` field on the Partner form uses a technical label and lacks clear semantics, confusing end users. Additionally, direct modification of the base module for such changes complicates upgrades and maintenance.
- **Solution**: Create a dedicated `partner_customization` module to safely rename the field to **Opening Balance** and enforce read-only access via view inheritance.
  - **Step 1**: Create module structure:
    ```
    addons/partner_customization/
    ├── __init__.py
    ├── __manifest__.py
    └── views/res_partner_inherit.xml
    ```
  - **Step 2**: Define module metadata in `__manifest__.py`:
    ```python
    {
        'name': 'Partner Customization',
        'version': '1.0',
        'depends': ['base'],
        'category': 'Customization',
        'description': 'Customize Partner View (Initial Balance field)',
        'data': [
            'views/res_partner_inherit.xml',
        ],
        'installable': True,
        'auto_install': False,
    }
    ```
  - **Step 3**: In `views/res_partner_inherit.xml`, override field label and readonly status:
    ```xml
    <odoo>
        <record id="view_partner_form_inherit_custom" model="ir.ui.view">
            <field name="name">res.partner.form.inherit.custom</field>
            <field name="model">res.partner</field>
            <field name="inherit_id" ref="base.view_partner_form"/>
            <field name="arch" type="xml">
                <field name="inital_balance" position="attributes">
                    <attribute name="string">Opening Balance</attribute>
                    <attribute name="readonly">1</attribute>
                </field>
            </field>
        </record>
    </odoo>
    ```
  - **Step 4**: Leave `__init__.py` empty.
  - **Step 5**: Restart Odoo, update the Apps list, and install **Partner Customization**.
  - After installation, the field appears as **Opening Balance** and cannot be edited directly, ensuring data integrity while improving usability.

---

## Made VAT (TIN) Field Required for Customer Partners

- **Issue**: The VAT (Tax Identification Number) field was optional for customers, leading to incomplete tax records and non-compliance with fiscal reporting requirements.
- **Solution**: Enforce VAT entry when a partner is marked as a customer using conditional required attributes.
  - In `partner_customization/views/res_partner_inherit.xml`, extend the partner form view:
    ```xml
    <field name="vat" position="attributes">
        <attribute name="attrs">{'required': [('customer', '=', True)]}</attribute>
    </field>
    ```
  - This dynamically makes the **VAT** field mandatory whenever the **Is a Customer** checkbox is checked.
  - The field remains optional for non-customers.
  - Restart Odoo and upgrade the `partner_customization` module.
  - After implementation, all customer records must include a VAT number, ensuring compliance and accurate tax documentation.

---

## Restricted Access to Opening Balance Field Based on User Group

- **Issue**: The **Opening Balance** (`inital_balance`) field was either fully editable or completely locked, failing to balance control with operational needs. Finance staff require access, but general users must be restricted.
- **Solution**: Limit visibility and editability of the field to users in a dedicated security group.
  - **Step 1**: Define the group in `partner_customization/security/security.xml`:
    ```xml
    <record id="group_edit_opening_balance" model="res.groups">
        <field name="name">Edit Opening Balance</field>
        <field name="category_id" ref="base.module_category_accounting_and_finance"/>
        <field name="comment">Users in this group can edit the Opening Balance field on partners.</field>
    </record>
    ```
  - **Step 2**: Apply group restriction to the field in `views/res_partner_inherit.xml`:
    ```xml
    <field name="inital_balance" position="attributes">
        <attribute name="string">Opening Balance</attribute>
        <attribute name="readonly">1</attribute>
        <attribute name="groups">partner_customization.group_edit_opening_balance</attribute>
    </field>
    ```
    - The field remains **read-only**, but only visible and editable by members of the _Edit Opening Balance_ group.
  - **Step 3**: Ensure security file is loaded by adding to `__manifest__.py`:
    ```python
    'data': [
        'security/security.xml',
        'views/res_partner_inherit.xml',
    ],
    ```
  - Restart Odoo and upgrade the `partner_customization` module.
  - After implementation, only authorized finance users can view and modify opening balances, ensuring data integrity and compliance with internal controls.

---

## Enabled Chatter Logging for Initial Balance Changes on Partners

- **Issue**: Changes to the **Initial Balance** (`inital_balance`) field were not tracked, making it difficult to audit who modified the balance and when, despite access being restricted to authorized users.
- **Solution**: Enable Odoo's chatter logging to record all changes to the `inital_balance` field in the partner's communication log.

  - In `partner_customization/models/res_partner.py`, override the field to add tracking:

    ```python
    from odoo import models, fields

    class ResPartner(models.Model):
        _inherit = 'res.partner'

        inital_balance = fields.Float(
            string="Initial Balance",
            track_visibility='onchange'
        )
    ```

  - **Step 1**: Create `partner_customization/models/__init__.py`:
    ```python
    from . import res_partner
    ```
  - **Step 2**: Create `partner_customization/__init__.py`:
    ```python
    from . import models
    ```
  - Ensure the module’s `__manifest__.py` includes the models directory in `depends` or `data` (loaded via module structure).
  - Restart Odoo and upgrade the `partner_customization` module.
  - After activation, any change to **Initial Balance** generates an entry in the partner’s chatter, showing the old and new values along with the user and timestamp — enhancing auditability and transparency.

---
