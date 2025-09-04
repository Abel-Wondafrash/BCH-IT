# Odoo 11 Custom Modules

This section documents custom-developed modules for Odoo 11, including new functionality, field extensions, and enhancements to support business-specific requirements.

---

## Added Bank Details Tab to Partner Form for Storing Multiple Bank Accounts

- **Issue**: Partner records lack a dedicated section to store multiple bank account details (e.g., account number, bank name), forcing users to rely on free-text fields or external references, leading to inconsistency and reduced usability.
- **Solution**: Create a custom module `partner_bank_details` that adds a structured **Bank Details** tab to the partner form, allowing multiple entries with validated account numbers and Odoo journal-linked banks.

  - **Step 1**: Define the model in `models/partner_bank_details.py`:

    ```python
    from odoo import models, fields, api
    from odoo.exceptions import ValidationError

    class ResPartnerBankDetail(models.Model):
        _name = 'res.partner.bank.detail'
        _description = 'Bank Detail for Contact'

        partner_id = fields.Many2one('res.partner', string='Partner', ondelete='cascade')
        account_number = fields.Char(string='Account Number')
        bank_name = fields.Many2one(
            'account.journal',
            string='Bank Name',
            domain=[('type', '=', 'bank')]
        )

        @api.model
        def create(self, vals):
            if 'account_number' in vals:
                cleaned = vals['account_number'].replace(" ", "")
                if not cleaned:
                    raise ValidationError("Account Number cannot be empty.")
                vals['account_number'] = cleaned
            return super(ResPartnerBankDetail, self).create(vals)

        def write(self, vals):
            if 'account_number' in vals:
                cleaned = vals['account_number'].replace(" ", "")
                if not cleaned:
                    raise ValidationError("Account Number cannot be empty.")
                vals['account_number'] = cleaned
            return super(ResPartnerBankDetail, self).write(vals)

    class ResPartner(models.Model):
        _inherit = 'res.partner'

        bank_detail_ids = fields.One2many(
            'res.partner.bank.detail', 'partner_id', string='Bank Details'
        )
    ```

  - **Step 2**: Add tab to form view in `views/res_partner_view.xml`:
    ```xml
    <odoo>
        <record id="view_partner_form_inherit_bank_details" model="ir.ui.view">
            <field name="name">res.partner.form.inherit.bank.details</field>
            <field name="model">res.partner</field>
            <field name="inherit_id" ref="base.view_partner_form"/>
            <field name="arch" type="xml">
                <xpath expr="//page[@name='sales_purchases']" position="after">
                    <page string="Bank Details">
                        <field name="bank_detail_ids">
                            <tree editable="bottom">
                                <field name="account_number"/>
                                <field name="bank_name"/>
                            </tree>
                        </field>
                    </page>
                </xpath>
            </field>
        </record>
    </odoo>
    ```
  - **Step 3**: Set up security and manifest:
    - `security/ir.model.access.csv`:
      ```csv
      id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
      access_res_partner_bank_detail,res.partner.bank.detail,model_res_partner_bank_detail,,1,1,1,1
      ```
    - `__manifest__.py`:
      ```python
      {
          'name': 'Partner Bank Details',
          'version': '11.0.1.0.0',
          'summary': 'Adds a Bank Details tab to Contacts',
          'category': 'Contacts',
          'author': 'Admin',
          'depends': ['base', 'account'],
          'data': [
              'security/ir.model.access.csv',
              'views/res_partner_view.xml',
          ],
          'installable': True,
          'application': False,
      }
      ```
  - **Step 4**: Initialize `__init__.py` files:
    - `__init__.py`: `from . import models`
    - `models/__init__.py`: `from . import partner_bank_details`
  - Restart Odoo, update Apps list, and install **Partner Bank Details**.
  - After installation, users can:
    - Open any **Contact**.
    - Navigate to the **Bank Details** tab.
    - Add one or more entries with **Account Number** and **Bank Name** (selected from existing `account.journal` of type _Bank_).
  - Ensures clean, reusable, and validated bank information per partner.

---
