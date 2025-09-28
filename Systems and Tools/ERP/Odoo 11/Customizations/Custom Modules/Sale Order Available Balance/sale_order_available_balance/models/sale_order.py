from odoo import models, api, fields, _
from odoo.exceptions import UserError

class SaleOrder(models.Model):
    _inherit = 'sale.order'

    available_balance = fields.Monetary(
        string="Available Balance",
        currency_field="currency_id",
        help="Snapshot of the partner's available balance when partner is selected.",
    )

    @api.depends('order_line.price_total')
    def _amount_all(self):
        """
        Compute the total amounts of the SO.
        """
        for order in self:
            amount_untaxed = amount_tax = 0.0
            for line in order.order_line:
                amount_untaxed += line.price_subtotal
                amount_tax += line.price_tax
            order.update({
                'amount_untaxed': order.pricelist_id.currency_id.round(amount_untaxed),
                'amount_tax': order.pricelist_id.currency_id.round(amount_tax),
                'amount_total': amount_untaxed + amount_tax,
            })

    # UI update
    @api.onchange('partner_id')
    def _onchange_partner_id_update_balance(self):
        for order in self:
            if order.partner_id:
                order.available_balance = order._get_available_balance(
                    order.partner_id,
                    current_order=order,
                    use_cached_balance=True,
                )
            else:
                order.available_balance = 0.0

    # Validation logic (allows passing in precomputed balance)
    def _check_insufficient_balance(self, precomputed_balance=None):
        for order in self:
            if not order.partner_id or order.state not in ('draft', 'confirm', 'sale'):
                continue

            available_balance = (
                precomputed_balance
                if precomputed_balance is not None
                else order._get_available_balance(
                    order.partner_id,
                    current_order=order,
                    use_cached_balance=False,  # always fresh if not precomputed
                )
            )

            if order.amount_total > available_balance:
                # Active orders details for information
                active_orders = order._get_active_orders(exclude_order=order)

                active_order_lines = [
                    "- {} (State: {}, Amount: {:,.2f}, Invoices: {})".format(
                        ao.name, ao.state, ao.amount_total, len(ao.invoice_ids)
                    )
                    for ao in active_orders
                ]
                active_orders_info = "\n".join(active_order_lines) if active_order_lines else _("None")

                raise UserError(_(
                    "Insufficient Balance!\n\n"
                    "Available Balance: {:,.2f}\n"
                    "Order Total: {:,.2f}\n"
                    "Shortfall: {:,.2f}\n\n"
                    "Active Orders:\n{}"
                ).format(
                    available_balance,
                    order.amount_total,
                    order.amount_total - available_balance,
                    active_orders_info,
                ))

    @api.model
    def create(self, vals):
        order = super().create(vals)

        fresh_balance = order._get_available_balance(
            order.partner_id,
            current_order=order,
            use_cached_balance=False
        )

        super(SaleOrder, order).write({'available_balance': fresh_balance})
        order._check_insufficient_balance(precomputed_balance=fresh_balance)

        return order

    def write(self, vals):
        res = super().write(vals)
        for order in self:
            fresh_balance = order._get_available_balance(
                order.partner_id,
                current_order=order,
                use_cached_balance=False
            )

            super(SaleOrder, order).write({'available_balance': fresh_balance})
            order._check_insufficient_balance(precomputed_balance=fresh_balance)

        return res

    # Core conditional available balance computation
    def _get_available_balance(self, partner, current_order=None, use_cached_balance=False):
        if not partner:
            return 0.0

        # --- Current Balance ---
        if use_cached_balance and current_order:
            current_balance = current_order.current_balance
        else:
            current_balance_dict = partner.get_current_balance()
            current_balance = current_balance_dict.get(str(partner.id), 0.0)

        # --- Active sale orders (commitments) ---
        active_orders_total = sum(
            order.amount_total for order in self._get_active_orders(exclude_order=current_order)
        )

        available_balance = current_balance - active_orders_total
        return available_balance

    # Helper to fetch active sale orders for a partner, excluding a specific order
    def _get_active_orders(self, exclude_order=None):
        self.ensure_one()
        partner = self.partner_id if not exclude_order else exclude_order.partner_id
        current_order_id = exclude_order.id if exclude_order and exclude_order.id else -1

        all_orders = self.env['sale.order'].search([
            ('partner_id', '=', partner.id),
            ('id', '!=', current_order_id)
        ])

        active_orders = []
        for order in all_orders:
            if order.state not in ('draft', 'confirm', 'sale', 'sent'):
                continue
            
            if order.state == 'sent':
                all_invoices = order.invoice_ids
                if len(all_invoices) == 1:
                    inv = all_invoices[0]
                    if inv.type == 'out_invoice' and inv.state in ('paid', 'cancel'):
                        continue  # inactive
                    
            active_orders.append(order)

        return active_orders
