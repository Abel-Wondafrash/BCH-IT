# -*- coding: utf-8 -*-
from odoo import models, fields, api, _
from odoo.exceptions import UserError

class SaleOrderLine(models.Model):
    _inherit = 'sale.order.line'

    @api.onchange('product_id')
    def _check_duplicate_product(self):
        if not self.product_id or not self.order_id:
            return

        # Look for other lines in the same order with the same product
        for existing_line in self.order_id.order_line:
            if existing_line.id != self.id and existing_line.product_id.id == self.product_id.id:
                # Duplicate found, reject the selection
                self.product_id = False
                raise UserError(_(
                    "The product '%s' is already included in this order "
                    "(%s %s).\n\n"
                    "To add more, please update the quantity in the existing line."
                ) % (
                    existing_line.product_id.display_name,
                    existing_line.product_uom_qty,
                    existing_line.product_uom.name,
                ))
