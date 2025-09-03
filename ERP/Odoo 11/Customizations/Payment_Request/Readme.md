# Odoo 11 Payment Request Customizations

This section covers customizations to the Odoo 11 payment request module, including sequence implementations, button visibility restrictions, and export wizards.

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
