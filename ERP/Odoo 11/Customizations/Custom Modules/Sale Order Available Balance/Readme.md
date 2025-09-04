# Odoo 11 Custom Modules

This section documents custom-developed modules for Odoo 11, including new functionality, field extensions, and enhancements to support business-specific requirements.

---

## Enforced Available Balance Validation in Sales Orders to Prevent Credit Overuse

- **Issue**: Sales users can create or confirm orders that exceed a customer’s available credit, leading to financial risk, overcommitment, and manual reconciliation between sales and finance.
- **Solution**: Introduce real-time **Available Balance** tracking and enforcement on sales orders, blocking overspending.

  - **Key Features**:
    - **Available Balance** = `Current Balance` – (`Unpaid Invoices` + `Active Draft/Confirmed/Sale Orders`)
    - Computed field displayed on the **Sales Order** form under customer balance.
    - Automatically recalculates when:
      - Partner changes
      - Order total changes
      - Order state changes
    - **Validation**:
      - On save or confirm: if `order_total > available_balance`, raise:
        ```
        UserError:
        "Available Balance: X\nOrder Total: Y\nShortfall: Z"
        ```
      - Blocks order creation/confirmation until amount is reduced or balance increased.
  - **Implementation**:

    - In `sale/models/sale_order.py`:

      ```python
      available_balance = fields.Monetary(
          string="Available Balance",
          compute="_compute_available_balance",
          store=False,
          help="Current balance minus unpaid invoices and active sales orders."
      )

      @api.depends('partner_id', 'amount_total')
      def _compute_available_balance(self):
          for order in self:
              partner = order.partner_id
              if not partner:
                  order.available_balance = 0.0
                  continue

              # Get current balance (from existing method)
              current_balance = partner.get_current_balance().get(str(partner.id), 0.0)

              # Sum unpaid invoices
              unpaid_invoices = sum(
                  inv.amount_total for inv in self.env['account.invoice'].search([
                      ('partner_id', '=', partner.id),
                      ('state', '=', 'open'),
                      ('type', '=', 'out_invoice')
                  ])
              )

              # Sum active SOs (draft, sent, sale) excluding self
              active_orders = self.env['sale.order'].search([
                  ('partner_id', '=', partner.id),
                  ('state', 'in', ['draft', 'sent', 'sale']),
                  ('id', '!=', order.id)
              ])
              committed_amount = sum(so.amount_total for so in active_orders)

              order.available_balance = current_balance - (unpaid_invoices + committed_amount)
      ```

    - Add validation in `action_confirm`:

      ```python
      def action_confirm(self):
          for order in self:
              if order.amount_total > order.available_balance:
                  raise UserError(_(
                      "Cannot confirm order.\n\n"
                      "Available Balance: %s\n"
                      "Order Total: %s\n"
                      "Shortfall: %s"
                  ) % (
                      order.available_balance,
                      order.amount_total,
                      order.amount_total - order.available_balance
                  ))
          return super(SaleOrder, self).action_confirm()
      ```

    - In `sale/views/sale_order_form.xml`, display field:
      ```xml
      <field name="available_balance" widget="monetary" options="{'currency_field': 'company_id.currency_id'}"/>
      ```

  - Restart Odoo and upgrade the **Sale** module.
  - After implementation, every sales order is validated against real-time credit availability, preventing overcommitment and aligning sales with financial constraints.

---
