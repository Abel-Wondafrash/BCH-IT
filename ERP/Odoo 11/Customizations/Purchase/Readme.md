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
