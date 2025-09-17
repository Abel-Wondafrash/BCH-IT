# -*- coding: utf-8 -*-
from odoo import models, fields, api, _
from odoo.exceptions import UserError

class SaleOrderLine(models.Model):
    _inherit = 'sale.order.line'

    @api.model
    def create(self, vals):
        record = super(SaleOrderLine, self).create(vals)
        record._check_duplicate_product_unique()
        return record

    def write(self, vals):
        res = super(SaleOrderLine, self).write(vals)
        self._check_duplicate_product_unique()
        return res

    def _check_duplicate_product_unique(self):
        for order in self.mapped('order_id'):
            # Group lines by product
            product_map = {}
            for line in order.order_line:
                if not line.product_id:
                    continue
                product_map.setdefault(line.product_id, []).append(line)

            # Collect duplicates
            duplicates = {p: lines for p, lines in product_map.items() if len(lines) > 1}

            if duplicates:
                product_list = "\n".join([
                    "- %s" % p.display_name for p in duplicates.keys()
                ])
                raise UserError(_(
                    "The following products are duplicated in this order:\n\n"
                    "%s\n\n"
                    "To add more of each, please update the quantity in the existing lines."
                ) % product_list)