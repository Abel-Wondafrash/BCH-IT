# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

from odoo import fields, models, api
from odoo.exceptions import UserError

class Partner(models.Model):
    _name = 'res.partner'
    _inherit = 'res.partner'

    property_product_pricelist = fields.Many2one(
        'product.pricelist', 'Sale Pricelist', compute='_compute_product_pricelist',
        inverse="_inverse_product_pricelist", company_dependent=False,  # NOT A REAL PROPERTY
        help="This pricelist will be used, instead of the default one, for sales to the current partner")
    
    @api.model
    def create(self, vals):
        if not vals.get('property_product_pricelist'):
            default_pricelist = self.env['product.pricelist'].search([], limit=1)
            if not default_pricelist:
                raise UserError("No pricelist is defined in the system. Please create at least one.")
            vals['property_product_pricelist'] = default_pricelist.id
        return super().create(vals)

    @api.multi
    def write(self, vals):
        if 'property_product_pricelist' in vals and not vals['property_product_pricelist']:
            default = self.env['product.pricelist'].search([], limit=1)
            if not default:
                raise UserError("At least one pricelist must exist.")
            vals['property_product_pricelist'] = default.id
        return super().write(vals)
    
    @api.multi
    @api.depends('country_id')
    def _compute_product_pricelist(self):
        for p in self:
            if not isinstance(p.id, models.NewId):  # if not onchange
                p.property_product_pricelist = self.env['product.pricelist']._get_partner_pricelist(p.id)

    @api.one
    def _inverse_product_pricelist(self):
        pls = self.env['product.pricelist'].search(
            [('country_group_ids.country_ids.code', '=', self.country_id and self.country_id.code or False)],
            limit=1
        )
        default_for_country = pls and pls[0]
        actual = self.env['ir.property'].get('property_product_pricelist', 'res.partner', 'res.partner,%s' % self.id)

        # update at each change country, and so erase old pricelist
        if self.property_product_pricelist or (actual and default_for_country and default_for_country.id != actual.id):
            # keep the company of the current user before sudo
            self.env['ir.property'].with_context(force_company=self.env.user.company_id.id).sudo().set_multi(
                'property_product_pricelist',
                self._name,
                {self.id: self.property_product_pricelist or default_for_country.id},
                default_value=default_for_country.id
            )

    def _commercial_fields(self):
        return super(Partner, self)._commercial_fields() + ['property_product_pricelist']
