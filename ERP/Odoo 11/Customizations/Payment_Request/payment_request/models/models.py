# -*- coding: utf-8 -*-

from odoo import models, fields, api

class paymentrequest(models.Model):

    _name = 'payment_request'
    _rec_name = 'name' # Display name

    name = fields.Char(
        string='Request Number',
        required=True,
        readonly=True,
        copy=False,
        default='New'
    )

    description = fields.Text(string='Purpose of payment')
    start_datetime = fields.Datetime('Date Time', default=lambda self: fields.Datetime.now())
    # partner_id = fields.Many2one('res.partner', string='Pay to Vendor')
    partner_id = fields.Char(string='Pay to Vendor')
    amount_birr = fields.Float(string='Amount', store=True)
    requester_id = fields.Many2one('hr.employee', string='Requester')
    employee_id = fields.Many2one('hr.employee', string='Pay to Employee')
    branch_2 = fields.Many2one('company.branch', string='Branch')
    source_doc = fields.Char(string='Source Document')
    prepared_by = fields.Many2one(
        'res.users',
        string='Prepared By',
        readonly=True
    )

    approve_uid = fields.Many2one('res.users', 'Approved By', readonly=True)
    approve_date = fields.Datetime('Approved On', readonly=True)

    selection_field = fields.Selection([('draft', 'Draft'), ('confirmed', 'Confirmed'), ('approved', 'Approved')], string='STATUS', default='draft')
    current_user = fields.Many2one('res.users','Current User', default=lambda self: self.env.user)
    # approver_id = fields.Many2one('res.users','Current User', default=lambda self: self.env.user)

    # @api.multi 
    # def button_done(self):   
    #     for rec in self:       
    #         rec.write({'selection_field': 'approved'})
    
    @api.model
    def create(self, vals):
        if vals.get('name', 'New') == 'New':
            vals['name'] = self.env['ir.sequence'].next_by_code('payment.request') or 'New'
        if not vals.get('prepared_by'):
            vals['prepared_by'] = self.env.uid
        return super(paymentrequest, self).create(vals)

    @api.multi
    def button_confirmed(self):
        for order in self:
            user_id=self.env['res.users'].search([('id', '=', self.env.uid)], limit=1).id

            if order.selection_field  == 'draft':
                order.write({'selection_field': 'confirmed','current_user':user_id})
        return True

    @api.multi
    def button_done(self):
        for order in self:
            user_id = self.env.uid
            approval_time = fields.Datetime.now()
            
            if order.selection_field == 'confirmed':
                order.write({
                    'selection_field': 'approved',
                    'approve_uid': user_id,
                    'approve_date': approval_time
                })
        return True
    
    @api.multi
    def button_cancel(self):   
        for rec in self: 
            rec.write({'selection_field': 'draft'})