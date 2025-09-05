from odoo import models, api, fields, _
from odoo.exceptions import UserError

class SaleOrder(models.Model):
    _inherit = 'sale.order'

    available_balance = fields.Monetary(
        string="Available Balance",
        currency_field="currency_id",
        help="Snapshot of the partner's available balance when partner selected or quotation saved.",
        compute='_compute_available_balance',
        store=False,
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

    @api.depends('partner_id', 'amount_total', 'state')
    def _compute_available_balance(self):
        for order in self:
            if order.partner_id:
                order.available_balance = self._get_available_balance(order.partner_id, current_order=order)
            else:
                order.available_balance = 0.0

    def _check_insufficient_balance(self):
        """Raise UserError if the order total exceeds available balance."""
        if self.partner_id and self.state in ('draft', 'confirm', 'sale'):
            available_balance = self._get_available_balance(self.partner_id, current_order=self)
            if self.amount_total > available_balance:
                raise UserError(_(
                    "Insufficient Balance!\n\n"
                    "Available Balance: {:,.2f}\n"
                    "Order Total: {:,.2f}\n"
                    "Shortfall: {:,.2f}"
                ).format(
                    available_balance,
                    self.amount_total,
                    self.amount_total - available_balance,
                ))

    def write(self, vals):
        res = super().write(vals)
        for order in self:
            order._check_insufficient_balance()
        return res

    @api.model
    def create(self, vals):
        order = super().create(vals)
        order._check_insufficient_balance()
        return order

    def _get_available_balance(self, partner, current_order=None):
        if not partner:
            return 0.0

        current_balance = partner.current_balance or 0.0
        order_id = current_order.id if current_order and current_order.id else -1

        active_orders_total = sum(
            self.env['sale.order']
            .search([
                ('partner_id', '=', partner.id),
                ('state', 'in', ('draft', 'confirm', 'sale')),
                ('id', '!=', order_id)
            ])
            .mapped('amount_total')
        )

        unpaid_invoices_total = sum(
            self.env['account.invoice']
            .search([('partner_id', '=', partner.id), ('state', '!=', 'paid')])
            .mapped('amount_total')
        )

        return current_balance - (active_orders_total)