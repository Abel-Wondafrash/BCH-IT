import logging
import time
from collections import OrderedDict
from odoo import api, fields, models, _
from odoo.osv import expression
from odoo.exceptions import RedirectWarning, UserError, ValidationError

_logger = logging.getLogger(__name__)
#----------------------------------------------------------
# Entries
#----------------------------------------------------------

class PaymentRequest(models.Model):
    _name = "payment.request"


    date = fields.Date(string="date")
    ref = fields.Char(string='reference',required=True, default="PO/")
    source = fields.Char(string='Source')
    payment_document = fields.Char(string='Payment Document')
    purchaser = fields.Many2one('hr.employee', string='Employee' )
    partner = fields.Many2one('res.partner', string='Partner' )
    description = fields.Text( string='Description' )
    journal = fields.Selection([('bank', 'Bank'), ('cash', 'Cash')],string='Journal',required=True)
    bank = fields.Many2one('account.journal', string='Bank Name') 
    amount = fields.Float(string='Amount')
    state = fields.Selection([('draft', 'Draft'), ('approved', 'Approved'), ('posted', 'Posted')],
     string='Status', required=True, readonly=True, copy=False, default='draft')
    approve_uid  = fields.Many2one('res.users', 'Approved By')
    create_uid = fields.Many2one('res.users', 'Request By')
    @api.multi
    def approve_request(self):
        _logger.info('-------!!!!!!!!click on approve')
        return {
                    'name':'Approve',
                    'view_type':'form',
                    'view_mode':'form',
                    'res_model':'payment.request.confirm.approve',
                    'type':'ir.actions.act_window',
                    'target':'new',
                }
    @api.multi
    def make_payment(self):
        return {
                    'name':'Post',
                    'view_type':'form',
                    'view_mode':'form',
                    'res_model':'payment.request.post',
                    'type':'ir.actions.act_window',
                    'target':'new',
                }
class ApprovePaymentRequest(models.Model):
    _name = 'payment.request.confirm.approve'
    @api.multi
    def yes(self, context):
        id=context.get('active_id')
        clause_final = [('id', '=', id)]
        search_results= self.env['payment.request'].search(clause_final).ids
        vals={}
        if search_results:
            for search_result in self.env['payment.request'].browse(search_results):
                # user_id=self.env['res.users'].search([('id', '=', self.env.uid)], limit=1).id
                user_id=self.env['res.users'].search([('id', '=', self.env.uid)], limit=1).id
                search_result.write({'state': 'approved','approve_uid':user_id})
               
            
            # vals={
            #     'source':search_result.id,
            #     'amount':search_result.amount_total
            #     }

            # req=self.env['payment.request'].create(vals)
        
            # return {
            #     'name': 'Payment Request',
            #     'type': 'ir.actions.act_window',
            #     'view_type': 'form',
            #     'view_mode': 'form',
            #     'res_model': 'payment.request',
            #     'target': 'new',
            #     'context': req,
            # }
            return {'type': 'ir.actions.act_window_close','tag': 'reload',}
    @api.multi
    def no(self):
        pass 
        
class PostPaymentRequest(models.Model):
    _name = 'payment.request.post'
    @api.multi
    def yes(self, context):
        id=context.get('active_id')
        clause_final = [('id', '=', id)]
        search_results= self.env['payment.request'].search(clause_final).ids
        vals={}
        if search_results:
            for search_result in self.env['payment.request'].browse(search_results):
                # user_id=self.env['res.users'].search([('id', '=', self.env.uid)], limit=1).id
    
                search_result.write({'state': 'posted'})
            if search_result.journal == 'cash':   
                account_search_results= self.env['account.journal'].search([('type', '=', search_result.journal)]).id
                for search_result2 in self.env['account.journal'].browse(account_search_results):
                    _logger.info('-------!!!!!!!!click on search_result2=%s',search_result2)
                    vals['journal_id']=search_result2.id
            else:
                vals['journal_id']=search_result.bank.id

            ref=search_result.ref
            refid=str(search_result.source)
            vals['ref']=ref+refid
            vals['payment_document']=search_result.payment_document
            vals['amount_val']=search_result.amount
            vals['employee_id']=search_result.purchaser.id
            vals['case']='purchase'
            vals['main_id']=search_result.source
                

            req=self.env['account.move'].create(vals)
        
            # return {
            #     'name': 'Payment Request',
            #     'type': 'ir.actions.act_window',
            #     'view_type': 'form',
            #     'view_mode': 'form',
            #     'res_model': 'payment.request',
            #     'target': 'new',
            #     'context': req,
            # }
            return {'type': 'ir.actions.act_window_close','tag': 'reload',}
    @api.multi
    def no(self):
        pass 
        