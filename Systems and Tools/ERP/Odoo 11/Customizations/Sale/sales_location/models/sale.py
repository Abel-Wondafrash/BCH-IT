# -*- coding: utf-8 -*-
from odoo import api, fields, models, _
from odoo.exceptions import UserError
import logging

_logger = logging.getLogger(__name__)

class SaleOrder(models.Model):
    _inherit = "sale.order"

    location = fields.Many2one('sale.locations', string="Location", required=True)
    plate_no = fields.Char(string='Plate Number', required=True)

    @api.onchange('partner_id')
    def _onchange_partner_set_pricelist_and_location(self):
        if not self.partner_id:
            return
        
        # 1. Set pricelist from partner
        if self.partner_id.property_product_pricelist:
            self.pricelist_id = self.partner_id.property_product_pricelist

        # 2. Set location based on that pricelist
        if self.pricelist_id:
            matching_location = self.env['sale.locations'].search([
                ('pricelist_id', '=', self.pricelist_id.id)
            ], limit=1)

            if matching_location:
                self.location = matching_location
            else:
                self.location = False
                raise UserError(_("No location found matching the selected customer's pricelist. "
                                  "Please configure a location with this pricelist or choose another customer."))

    @api.model
    def create(self, vals):
        # Ensure pricelist & location are synced on create, fallback from partner
        if 'partner_id' in vals:
            partner = self.env['res.partner'].browse(vals['partner_id'])
            if partner.property_product_pricelist and not vals.get('pricelist_id'):
                vals['pricelist_id'] = partner.property_product_pricelist.id

            if vals.get('pricelist_id') and not vals.get('location'):
                loc = self.env['sale.locations'].search([('pricelist_id', '=', vals['pricelist_id'])], limit=1)
                if loc:
                    vals['location'] = loc.id
                else:
                    raise UserError(_("No location found matching the customer's pricelist during order creation."))

        return super(SaleOrder, self).create(vals)

    def write(self, vals):
        # When partner_id is changed, update pricelist and location accordingly
        if 'partner_id' in vals:
            partner = self.env['res.partner'].browse(vals['partner_id'])
            if partner.property_product_pricelist:
                vals['pricelist_id'] = partner.property_product_pricelist.id

                loc = self.env['sale.locations'].search([('pricelist_id', '=', vals['pricelist_id'])], limit=1)
                if loc:
                    vals['location'] = loc.id
                else:
                    raise UserError(_("No location found matching the customer's pricelist when updating the order."))

        # When location changes, update pricelist automatically
        if 'location' in vals and 'pricelist_id' not in vals:
            location = self.env['sale.locations'].browse(vals['location'])
            if location.pricelist_id:
                vals['pricelist_id'] = location.pricelist_id.id

        res = super(SaleOrder, self).write(vals)

        # After write, update order lines prices based on pricelist change
        if 'pricelist_id' in vals:
            self._onchange_pricelist_update_order_lines()

        return res