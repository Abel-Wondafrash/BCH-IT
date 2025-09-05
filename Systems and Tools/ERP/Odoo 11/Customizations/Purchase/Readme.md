# Odoo 11 Purchase Customizations

This section details customizations to the Odoo 11 purchase module, including sequence additions, tracking fields, and a new module for purchase request exports.

---

## Added Submission and Approval Metadata to Purchase Requests for Auditability

- **Issue**: Purchase Requests lack accountability — no record of who submitted or approved a request, or when these actions occurred, reducing transparency and complicating audits.
- **Solution**: Add `Submitted By`, `Submitted On`, `Approved By`, and `Approved On` fields that auto-populate upon submission and approval.
  - **Step 1**: Extend the model in `purchase/models/purchase.py`:
    ```python
    submitted_by = fields.Many2one('res.users', 'Submitted By', readonly=True)
    submitted_on = fields.Datetime('Submitted On', readonly=True)
    approve_uid = fields.Many2one('res.users', 'Approved By', readonly=True)
    approve_date = fields.Datetime('Approved On', readonly=True)
    ```
  - **Step 2**: Auto-populate on submission:
    ```python
    def submit_request(self):
        for order in self:
            if not order.submitted_by:
                order.write({
                    'submitted_by': self.env.uid,
                    'submitted_on': fields.Datetime.now(),
                })
    ```
  - **Step 3**: Set approver and timestamp on approval:
    ```python
    def approve_request(self):
        for order in self:
            order.write({
                'state': 'PR Approved',
                'approve_uid': self.env.uid,
                'approve_date': fields.Datetime.now(),
            })
    ```
  - **Step 4**: Update form view in `purchase/views/purchase_views.xml` to show fields only after submission:
    ```xml
    <field name="submitted_by" readonly="1" attrs="{'invisible': ['|', ('state', '=', 'draft'), ('state', '=', 'item_filled')]}"/>
    <field name="submitted_on" readonly="1" attrs="{'invisible': ['|', ('state', '=', 'draft'), ('state', '=', 'item_filled')]}"/>
    <field name="approve_uid" readonly="1" attrs="{'invisible': ['|', ('state', '=', 'draft'), ('state', '=', 'item_filled')]}"/>
    <field name="approve_date" readonly="1" attrs="{'invisible': ['|', ('state', '=', 'draft'), ('state', '=', 'item_filled')]}"/>
    ```
  - Restart the Odoo service and upgrade the **Purchase Management** (`purchase`) module.
  - After upgrade, all purchase requests display full submission and approval audit trail directly in the form, enhancing accountability and reporting.

---

## Added Sequence-Based Naming for Purchase Requests

- **Issue**: Purchase Requests used generic names or internal IDs, reducing readability and traceability in reports and communication.
- **Solution**: Implement a sequence to generate unique, human-readable request numbers (e.g., `PUR-00001`) on creation.

  - In `purchase/models/purchase.py`, update the `PurchaseRequest` model:

    ```python
    _rec_name = "name"

    name = fields.Char(
        string="Request Number",
        required=True,
        copy=False,
        default='New'
    )
    ```

    - Override `create()` to assign sequence:

    ```python
    @api.model
    def create(self, vals):
        if vals.get('name', 'New') == 'New':
            vals['name'] = self.env['ir.sequence'].next_by_code('purchase.request') or 'New'
        return super(PurchaseRequest, self).create(vals)
    ```

  - Update reports (`purchase/report/purchase_request.xml`) to display `name` instead of `id`:
    ```xml
    <h2>Purchase Request - <span t-field="o.name"/></h2>
    ```
  - Update tree view (`purchase/views/purchase_views.xml`) to show `name` and additional fields:
    ```xml
    <field name="name"/>
    <field name="branch_2"/>
    <field name="date_order"/>
    <field name="create_uid2"/>
    <field name="category_type"/>
    <field name="grand_total_expected_price"/>
    <field name="state"/>
    ```
  - Restart the Odoo service and upgrade the **Purchase Management** module.
  - After upgrade, all new Purchase Requests are automatically assigned a sequence-based number, improving document clarity and tracking.

---
