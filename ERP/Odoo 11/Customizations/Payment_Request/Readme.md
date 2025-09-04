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

## Added Prepared By, Approved By, and Approved On Fields to Payment Request for Audit Trail

- **Issue**: Payment requests lack accountability tracking — no clear record of who created, approved, or when approval occurred, limiting auditability and transparency.
- **Solution**: Add `Prepared By`, `Approved By`, and `Approved On` fields with automatic population upon creation and approval.
  - **Step 1**: Extend the model in `payment_request/models/models.py`:
    ```python
    prepared_by = fields.Many2one('res.users', string='Prepared By', readonly=True)
    approve_uid = fields.Many2one('res.users', string='Approved By', readonly=True)
    approve_date = fields.Datetime(string='Approved On', readonly=True)
    ```
  - **Step 2**: Auto-set `prepared_by` on creation:
    ```python
    @api.model
    def create(self, vals):
        if not vals.get('prepared_by'):
            vals['prepared_by'] = self.env.uid
        return super(paymentrequest, self).create(vals)
    ```
  - **Step 3**: Update approval logic in `button_done`:
    ```python
    @api.multi
    def button_done(self):
        for order in self:
            if order.selection_field == 'confirmed':
                order.write({
                    'selection_field': 'approved',
                    'approve_uid': self.env.uid,
                    'approve_date': fields.Datetime.now()
                })
        return True
    ```
  - **Step 4**: Update form view in `payment_request/views/views.xml`:
    ```xml
    <field name="prepared_by" readonly="1" attrs="{'invisible': [('id', '=', False)]}"/>
    <field name="approve_uid" readonly="1"/>
    <field name="approve_date" readonly="1"/>
    ```
    - `prepared_by` is hidden until the record is saved.
  - Restart the Odoo service and upgrade the `payment_request` module.
  - After upgrade, all payment requests display full approval metadata directly in the form, enabling full traceability.

---

## Added Sequence-Based Naming for Payment Requests

- **Issue**: Payment Requests were identified by internal database IDs, reducing clarity and professionalism in documentation and communication.
- **Solution**: Implement a sequence to automatically assign user-friendly, traceable request numbers (e.g., `PYR-00001`) upon creation.

  - In `payment_request/models/models.py`, update the `paymentrequest` model:

    ```python
    _rec_name = 'name'

    name = fields.Char(
        string='Request Number',
        required=True,
        readonly=True,
        copy=False,
        default='New'
    )
    ```

    - Override `create()` to use sequence:

    ```python
    @api.model
    def create(self, vals):
        if vals.get('name', 'New') == 'New':
            vals['name'] = self.env['ir.sequence'].next_by_code('payment.request') or 'New'
        return super(paymentrequest, self).create(vals)
    ```

  - Update the report template (`payment_request/reports/payment_request.xml`) to display the name:
    ```xml
    <h2>Payment Request - <span t-field="doc.name"/></h2>
    ```
  - In `payment_request/views/views.xml`:
    - Ensure `name` is displayed and readonly:
      ```xml
      <field name="name" readonly="1"/>
      ```
    - Confirm action window has proper name:
      ```xml
      <field name="name">Payment Request</field>
      ```
  - Restart the Odoo service and upgrade the `payment_request` module.
  - After upgrade, all new payment requests receive a sequential, readable reference, enhancing traceability and document presentation.

---

## Added Request Number to Payment Request List View for Improved Traceability

- **Issue**: The Payment Request list view did not display the **Request Number** (`name`), making it difficult to identify and track specific requests without opening each record.
- **Solution**: Add the `name` field to the list view to show the sequence-based request number (e.g., `PYR-00001`) directly in the grid.
  - In `payment_request/views/views.xml`, update the tree view:
    ```xml
    <record model="ir.ui.view" id="payment_request_tree">
        <field name="name">payment.request.tree</field>
        <field name="model">paymentrequest</field>
        <field name="arch" type="xml">
            <tree>
                <field name="name"/>
                <!-- other fields -->
            </tree>
        </field>
    </record>
    ```
  - This displays the **Request Number** as the first column, enabling quick scanning and reference.
  - Restart Odoo and upgrade the `payment_request` module.
  - After upgrade, users can easily locate and distinguish payment requests in the list view, improving navigation and operational efficiency.

---

## Restricted "Done" Button Visibility to Prevent Premature Finalization of Payment Requests

- **Issue**: The **Done** button was always visible to users in the _Payment Director_ group, regardless of the payment request’s status, allowing accidental or premature finalization.
- **Solution**: Make the **Done** button visible only when the request is in **Confirmed** state (`selection_field = 'confirmed'`).
  - In `payment_request/views/views.xml`, update the **Done** button in the form view:
    ```xml
    <button name="button_done" string="Done" type="object"
            attrs="{'invisible': [('selection_field', '!=', 'confirmed')]}"
            class="oe_highlight"/>
    ```
  - This ensures the button is hidden if the status is not _Confirmed_, enforcing proper workflow progression.
  - Restart Odoo and upgrade the `payment_request` module.
  - After implementation, users can only mark a request as done after it has been confirmed, improving data integrity and compliance with approval processes.

---

## Updated Payment Manager Role to Allow Confirmation of Payment Requests

- **Issue**: The _Payment Manager_ group lacked permission to confirm payment requests, disrupting the approval workflow and requiring higher-level roles to perform basic confirmations.
- **Solution**: Grant the _Payment Manager_ group access to the **Confirm** button while reserving **Done** for higher roles (e.g., Director).
  - In `payment_request/security/security_groups.xml`, ensure the group is defined with proper context:
    ```xml
    <record id="group_payment_manager" model="res.groups">
        <field name="name">Payment Manager</field>
        <field name="category_id" eval="52"/> <!-- Extra Rights -->
        <field name="comment">Payment Managers can Confirm payment requests.</field>
    </record>
    ```
  - In `payment_request/views/views.xml`, assign the group to the **Confirm** button:
    ```xml
    <button name="button_confirmed" string="Confirm" type="object"
            class="oe_highlight"
            groups="payment_request.group_payment_manager"/>
    ```
  - This allows Payment Managers to move requests from _Draft_ to _Confirmed_, while only _Payment Director_ (or similar) can mark them as _Done_.
  - Restart Odoo and upgrade the `payment_request` module.
  - After update, role-based approval workflow is enforced, improving security and process clarity.

---

## Added Payment Director Role for Final Approval and Cancellation of Payment Requests

- **Issue**: No dedicated role existed to finalize or cancel payment requests, leading to unclear accountability and potential misuse of elevated permissions.
- **Solution**: Introduce a **Payment Director** group with exclusive access to **Done** and **Cancel** actions, ensuring proper segregation of duties.
  - In `payment_request/security/security_groups.xml`, define the new group:
    ```xml
    <record id="group_payment_director" model="res.groups">
        <field name="name">Payment Director</field>
        <field name="category_id" eval="52"/> <!-- Extra Rights -->
        <field name="comment">Payment Directors can mark payment requests as Done or Cancelled.</field>
    </record>
    ```
  - In `payment_request/views/views.xml`, restrict critical buttons to this group:
    ```xml
    <button name="button_done" string="Done" type="object"
            groups="payment_request.group_payment_director"
            attrs="{'invisible': [('selection_field', '!=', 'confirmed')]}"/>
    <button name="button_cancel" string="Cancel" class="oe_highlight"
            type="object" groups="payment_request.group_payment_director"/>
    ```
  - This ensures only Payment Directors can:
    - Mark confirmed requests as **Done**
    - Cancel requests at any stage
  - Payment Managers can **Confirm**, but not finalize.
  - Restart Odoo and upgrade the `payment_request` module.
  - After implementation, approval workflows are clearly segmented by role, enhancing control and auditability.

---
