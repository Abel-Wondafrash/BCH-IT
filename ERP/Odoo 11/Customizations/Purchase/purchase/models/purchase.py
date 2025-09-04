# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.


from datetime import datetime
from dateutil.relativedelta import relativedelta

from odoo import api, fields, models, SUPERUSER_ID, _
from odoo.tools import DEFAULT_SERVER_DATETIME_FORMAT
from odoo.tools.float_utils import float_is_zero, float_compare
from odoo.exceptions import UserError, AccessError
from odoo.tools.misc import formatLang
from odoo.addons.base.res.res_partner import WARNING_MESSAGE, WARNING_HELP
from odoo.addons import decimal_precision as dp
import logging
_logger = logging.getLogger(__name__)

class PurchaseRequestCategory(models.Model):
    _name = "purchase.request.category"
    name = fields.Char('Name', required=True)
    is_production = fields.Boolean('Is Production')    
    
class PurchaseRequest(models.Model):
    _name = "purchase.request"
    _description = "Purchase Request"
    _rec_name = "name"
    
    name = fields.Char(
        string="Request Number",
        required=True,
        copy=False,
        default='New',
    )

    READONLY_STATES = {
        'purchase': [('readonly', True)],
        'done': [('readonly', True)],
        'cancel': [('readonly', True)],
    }

    @api.model
    def create(self, vals):
        if vals.get('name', 'New') == 'New':
            vals['name'] = self.env['ir.sequence'].next_by_code('purchase.request') or 'New'
        return super(PurchaseRequest, self).create(vals)

    def _default_user(self):
        return self.env['res.users'].search([('id', '=', self.env.uid)], limit=1)
    
    # department_id = fields.Many2one('hr.department', string='Department', required=True)
    date_order = fields.Datetime('Order Date',
     required=True,  index=True, copy=False, default=fields.Datetime.now,\
        help="Depicts the date where the Quotation should be validated and converted into a purchase order.")
    state = fields.Selection([
        ('draft', 'Purchase Request'),
        ('item_filled', 'Purchase Request'),
        ('PRsent', 'PR sent For Approval'),
        ('PR Approved', 'PR Approved'),
        ('cancel', 'Cancelled'),
        ('done', 'Done')
        ], string='Status', readonly=True, index=True, copy=False, default='draft', track_visibility='onchange')
   
    create_uid2 = fields.Many2one('hr.employee', 'Request By')
    prepared = fields.Many2one('res.users', 'Prepared By') 
    order_line = fields.One2many('purchase.order.line1', 'request_id', string='Order Lines', states={'cancel': [('readonly', True)], 'done': [('readonly', True)]}, copy=True)
   
    partner_id = fields.Many2one('res.partner', string='Vendor',
      states=READONLY_STATES, change_default=True, track_visibility='always')
    category = fields.Many2one('purchase.request.category', string='Category')
    branch_2 = fields.Many2one('company.branch', string='Branch')
    category_type = fields.Boolean("Is Production",related='category.is_production')
    budget_id= fields.Integer( string="Budget Id", store=True)
    approve_uid  = fields.Many2one('res.users', 'Approved By')
    grand_total_expected_price = fields.Float(string="Grand Total Expected Price", compute="_compute_grand_total_expected_price", store=True)
    submitted_by = fields.Many2one('res.users', 'Submitted By', readonly=True)
    submitted_on = fields.Datetime('Submitted On', readonly=True)
    approve_uid = fields.Many2one('res.users', 'Approved By', readonly=True)
    approve_date = fields.Datetime('Approved On', readonly=True)
    

    @api.depends('order_line.expected_total_price')
    def _compute_grand_total_expected_price(self):
        for record in self:
            total = sum(line.expected_total_price for line in record.order_line)
            record.grand_total_expected_price = total
    
    @api.onchange('date_order')
    def onchange_date_order(self):
        clause_final = ['&',('start_date', '<', datetime.now()),('end_date', '>', datetime.now())]
        _logger.info('-------clause_final************ = %s',clause_final)
        search_results= self.env['accounting.period'].search(clause_final,order='id desc', limit=1).id
        self.budget_id=search_results
            
    @api.multi
    def submit_request(self):
        for order in self:
            if not order.submitted_by:
                order.write({
                    'submitted_by': self.env.uid,
                    'submitted_on': fields.Datetime.now(),
                })
        return {
            'name': 'Confirm',
            'view_type': 'form',
            'view_mode': 'form',
            'res_model': 'purchase.reqest.confirm.submit',
            'type': 'ir.actions.act_window',
            'target': 'new',
        }
        # for order in self:
        #     if order.state  == 'draft':
        #         order.write({'state': 'PRsent'})
        # return True
    @api.multi
    def approve_request(self):
        for order in self:
            user_id=self.env['res.users'].search([('id', '=', self.env.uid)], limit=1).id
    
            order.write({
                'state': 'PR Approved',
                'approve_uid': self.env.uid,
                'approve_date': fields.Datetime.now(),
            })
        return True
    @api.multi
    def cancel_request(self):
        for order in self:
            if order.state  == 'PRsent':
                order.write({'state': 'cancel'})
        return True
class purchase_request_confirm_submit(models.Model):
    _name = 'purchase.reqest.confirm.submit'
    @api.multi
    def yes(self, context):
        terms=[]
        id=context.get('active_id')
        clause_final = ['&',('request_id', '=',id),('state','=','draft')]
        search_results= self.env['purchase.order.line1'].search(clause_final).ids
        if search_results:
            _logger.info('-------search_results************ = %s',search_results)
            # _logger.info('-------term--------- = %s',terms)
            # terms=self.env['purchase.order.line'].browse(search_results)
            for search_result2 in self.env['purchase.order.line1'].browse(search_results):
                _logger.info('-------search_result2************ = %s',search_result2)
            # _logger.info('-------terms************ = %s',terms)
                # search_result2.write({'state': 'RFQ')
                for rec in search_result2:
                    values = {}
                    values['name'] = rec.name
                    values['product_id'] = rec.product_id
                    values['product_qty'] = rec.product_qty
                    terms.append((0, 0, values))
        if terms == []:
            _logger.warning("Can't submit empty request.")
            pass
            raise UserError(_("Can't submit empty request."))
            
        else:
            clause_final = [('id', '=', id)]
            search_results= self.env['purchase.request'].search(clause_final).ids
            
            if search_results:
                for search_result in self.env['purchase.request'].browse(search_results):
                    
                    _logger.error("!before update loop----------- vals=%s",search_result)     
                    search_result.write({'state': 'PRsent'})

            
            return {'type': 'ir.actions.act_window_close','tag': 'reload',}
    @api.multi
    def no(self):
        pass 


class purchase_order_confirm_approve(models.Model):
    _name = 'purchase.order.confirm.approve'
    @api.multi
    def yes(self, context):
        id=context.get('active_id')
        clause_final = [('id', '=', id)]
        search_results= self.env['purchase.order'].search(clause_final).ids
        vals={}
        if search_results:
            for search_result in self.env['purchase.order'].browse(search_results):
                user_id=self.env['res.users'].search([('id', '=', self.env.uid)], limit=1).id
    
                search_result.write({'state': 'purchase','approve_uid':user_id})
                search_result._create_picking()
                if search_result.payment_type!="pre_payment":
                    vals={
                        'source':search_result.id,
                        'amount':search_result.amount_total,
                        'journal':'bank'
                        }

                    req=self.env['payment.request'].create(vals)
        
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
        
class PurchaseOrder(models.Model):
    _name = "purchase.order"
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _description = "Purchase Order"
    _order = 'date_order desc, id desc'

    @api.depends('order_line.price_total')
    def _amount_all(self):
        for order in self:
            amount_untaxed = amount_tax = 0.0
            for line in order.order_line:
                amount_untaxed += line.price_subtotal
                amount_tax += line.price_tax
            order.update({
                'amount_untaxed': order.currency_id.round(amount_untaxed),
                'amount_tax': order.currency_id.round(amount_tax),
                'amount_total': amount_untaxed + amount_tax,
            })

    @api.depends('order_line.date_planned')
    def _compute_date_planned(self):
        for order in self:
            min_date = False
            for line in order.order_line:
                if not min_date or line.date_planned < min_date:
                    min_date = line.date_planned
            if min_date:
                order.date_planned = min_date

    @api.depends('state', 'order_line.qty_invoiced', 'order_line.qty_received', 'order_line.product_qty')
    def _get_invoiced(self):
        precision = self.env['decimal.precision'].precision_get('Product Unit of Measure')
        for order in self:
            if order.state not in ('purchase', 'done'):
                order.invoice_status = 'no'
                continue

            if any(float_compare(line.qty_invoiced, line.product_qty if line.product_id.purchase_method == 'purchase' else line.qty_received, precision_digits=precision) == -1 for line in order.order_line):
                order.invoice_status = 'to invoice'
            elif all(float_compare(line.qty_invoiced, line.product_qty if line.product_id.purchase_method == 'purchase' else line.qty_received, precision_digits=precision) >= 0 for line in order.order_line) and order.invoice_ids:
                order.invoice_status = 'invoiced'
            else:
                order.invoice_status = 'no'

    @api.depends('order_line.invoice_lines.invoice_id')
    def _compute_invoice(self):
        for order in self:
            invoices = self.env['account.invoice']
            for line in order.order_line:
                invoices |= line.invoice_lines.mapped('invoice_id')
            order.invoice_ids = invoices
            order.invoice_count = len(invoices)

    @api.model
    def _default_picking_type(self):
        type_obj = self.env['stock.picking.type']
        company_id = self.env.context.get('company_id') or self.env.user.company_id.id
        types = type_obj.search([('code', '=', 'incoming'), ('warehouse_id.company_id', '=', company_id)])
        if not types:
            types = type_obj.search([('code', '=', 'incoming'), ('warehouse_id', '=', False)])
        return types[:1]

    @api.depends('order_line.move_ids.returned_move_ids',
                 'order_line.move_ids.state',
                 'order_line.move_ids.picking_id')
    def _compute_picking(self):
        for order in self:
            pickings = self.env['stock.picking']
            for line in order.order_line:
                # We keep a limited scope on purpose. Ideally, we should also use move_orig_ids and
                # do some recursive search, but that could be prohibitive if not done correctly.
                moves = line.move_ids | line.move_ids.mapped('returned_move_ids')
                pickings |= moves.mapped('picking_id')
            order.picking_ids = pickings
            order.picking_count = len(pickings)

    @api.depends('picking_ids', 'picking_ids.state')
    def _compute_is_shipped(self):
        for order in self:
            if order.picking_ids and all([x.state == 'done' for x in order.picking_ids]):
                order.is_shipped = True
    @api.model
    def _default_so_tc(self):
       self.onchange_purchase_request()
    # @api.model
    # def _default_purchase_request(self):
    #     return self.env['purchase.request'].search([('state', '=','PRsent')])
    #     # terms_obj = self.purchase_request
        # _logger.info('!!!------------------ terms_obj = %s',terms_obj)
        # clause_final = [('state','=','PRsent')]
        # _logger.info('!!!------------------ clause_final = %s',clause_final)
           
        # search_results= self.env['purchase.request'].search(clause_final).ids
        # _logger.info('!!!------------------ search_results = %s',search_results)
        # terms = []
        # if search_results:
        #     _logger.info('-------search_results************ = %s',search_results)
        #     # _logger.info('-------term--------- = %s',terms)
        #     # terms=self.env['purchase.order.line'].browse(search_results)

        #     #return search_results
        #     for rec in self.env['purchase.request'].browse(search_results):
        #         if( rec.state == 'PRsent'):
        #             values = {}
        #             values['id'] = rec.id
        #             values['date_order'] = rec.date_order
        #             values['department_id'] = rec.department_id
        #             values['order_line'] = rec.order_line
        #             values['state'] = rec.state
        #             terms.append((0, 0, values))
        # _logger.info('!!!------------------ terms = %s',terms)
        
        # return terms

    def _compute_purchase_request(self):
        _logger.info('-------start computing purchase request')
        
        search_result_request= self.env['purchase.request'].search([]).ids
        if search_result_request:
            _logger.info('-------search_results************ = %s',search_result_request)
            # _logger.info('-------term--------- = %s',terms)
            # terms=self.env['purchase.order.line'].browse(search_results)
            for search_result_request_detail in self.env['purchase.request'].browse(search_result_request):
                _logger.info('-------search_result_request_detail************ = %s',search_result_request_detail)
                terms = []
                request_id=''
                request_id=search_result_request_detail.id
                clause_final1 = ['&',('request_id', '=',search_result_request_detail.id),('state','=','draft')]
                search_results= self.env['purchase.order.line1'].search(clause_final1).ids
                if search_results:
                    _logger.info('-------search_results************ = %s',search_results)
                    # _logger.info('-------term--------- = %s',terms)
                    # terms=self.env['purchase.order.line'].browse(search_results)
                    for search_result2 in self.env['purchase.order.line1'].browse(search_results):
                        _logger.info('-------search_result2************ = %s',search_result2)
                    # _logger.info('-------terms************ = %s',terms)
                        # search_result2.write({'state': 'RFQ')
                        for rec in search_result2:
                            values = {}
                            values['name'] = rec.name
                            values['product_id'] = rec.product_id
                            values['product_qty'] = rec.product_qty
                            terms.append((0, 0, values))
            
                _logger.info('-------terms************ = %s',terms)
                if terms == []:
                    _logger.info('-------terms array is empty')
                    clause_final = [('id', '=',request_id)]
                    search_results= self.env['purchase.request'].search(clause_final).ids
                    if search_results:
                        _logger.info('-------search_results************ = %s',search_results)
                        # _logger.info('-------term--------- = %s',terms)
                        # terms=self.env['purchase.order.line'].browse(search_results)
                        for search_result2 in self.env['purchase.request'].browse(search_results):
                            search_result2.write({"state":"done"})
            
        # self.order_line=terms
        # self.order_line = self.env["purchase.request"].search([("state", "=","PR Approved")])
        # return  
        # self.onchange_purchase_request()
        # res = self.pool.get('purchase.request').search(cr, uid, [('state','=','PR Approved')], context=context)
        # res=self.env['purchase.request'].search([("state","=","PR Approved")]).ids
        # return res and res[0] or False
        # for line in self:
        #     line.purchase_request=self.env['purchase.request'].search([("state","=","PR Approved")]).ids
    @api.model
    def calculate_remaining_price(self,date_order,department,product_id):

        remaning_budget_price=0
        
        clause_final = ['&',('start_date', '<',date_order),('end_date', '>', date_order)]
        _logger.info('-------clause_final************ = %s',clause_final)
        _logger.info('-------self.department************ = %s',department)
        search_results= self.env['accounting.period'].search(clause_final,order='id desc', limit=1).id
        _logger.info('!!!!!!!!!!!-------search_results************ = %s',search_results)
        total_remaining_qty=0
        if search_results:  
            # for search_result in self.env['accounting.period'].browse(search_results):
            #     _logger.info('-------search_result************ = %s',search_result)
            clause_final2 = ['&',('budget_period', '=', search_results),('department_id', '=', department.id)]
            _logger.info('-------clause_final3************ = %s',clause_final2)
            search_results2= self.env['purchase.budget'].search(clause_final2).ids
            _logger.info('-------search_results2 --------************ = %s',search_results2)
            if search_results2:  
                for search_result2 in self.env['purchase.budget'].browse(search_results2):
                    clause_final3 = ['&',('budget_id', '=', search_result2.id),('product_id', '=', product_id.id)]
                    _logger.info('-------clause_final3************ = %s',clause_final3)
                    search_results3= self.env['purchase.budget.items'].search(clause_final3,order='date desc', limit=1).ids
                    
                    if search_results3:  
                        for search_result3 in self.env['purchase.budget.items'].browse(search_results3):
                            _logger.info('-------search_result3.actual_qty************ = %s',search_result3.actual_qty)
                            remaning_budget_price=remaning_budget_price + search_result3.actual_total_price
        return remaning_budget_price

        
    @api.onchange('purchase_request')
    def onchange_purchase_request(self):
        _logger.info("++++++++++++++++++++++++++");
        _logger.info(self.purchase_request)
        terms_obj = self.purchase_request
        if self.purchase_request:
            _logger.info('!!!------------------ branch name = %s',self.purchase_request.branch_2.id)
            self.branch=self.purchase_request.branch_2.id
        terms = []
        request_id=''
        if terms_obj:
            for search_result in terms_obj:
                _logger.info('!!!------------------ search_result = %s',search_result)
                _logger.info('!!!------------------ search_result = %s',search_result.id)
                request_id=search_result.id
                clause_final = ['&',('request_id', '=',search_result.id),('state','=','draft')]
                _logger.info('!!!------------------ clause_final = %s',clause_final)
                search_results= self.env['purchase.order.line1'].search(clause_final).ids
                if search_results:
                    _logger.info('-------search_results************ = %s',search_results)
                    # _logger.info('-------term--------- = %s',terms)
                    # terms=self.env['purchase.order.line'].browse(search_results)
                    for search_result2 in self.env['purchase.order.line1'].browse(search_results):
                        _logger.info('-------search_result2************ = %s',search_result2)
                        # _logger.info('-------product_id************ = %s',search_result2.product_id)
                        _logger.info('-------product_id templet************ = %s',search_result2.product_id.product_tmpl_id)
                    # _logger.info('-------terms************ = %s',terms)
                        # search_result2.write({'state': 'RFQ')
                        product_templet_id=search_result2.product_id.product_tmpl_id.id
                        _logger.info('-------product_templet_id************ = %s',product_templet_id)
                        
                        for rec in search_result2:
                            values = {}

                            clause_final_product_templet = [('id', '=',product_templet_id)]
                            _logger.info('!!!------------------ clause_final_product = %s',clause_final_product_templet)
                            search_results_product_templet= self.env['product.template'].search(clause_final_product_templet).ids
                            if search_results_product_templet:
                                _logger.info('-------search_results_product_templet************ = %s',search_results_product_templet)
                                # _logger.info('-------term--------- = %s',terms)
                                # terms=self.env['purchase.order.line'].browse(search_results)
                                for search_result_product_templet in self.env['product.template'].browse(search_results_product_templet):
                                    _logger.info('-------unit of Measurment************ = %s',search_result_product_templet.uom_id)
                                    # unit_of_measurment=search_result_product_templet.uom_id.id

                                    values['product_uom'] = search_result_product_templet.uom_id.id


                            
                            values['name'] = rec.name
                            values['product_id'] = rec.product_id
                            
                            values['product_uom'] = rec.product_uom
                            values['product_qty'] = rec.product_qty
                            values['department'] = rec.department
                            values['date_order'] = rec.date_order
                            values['remaning_budget_price'] =self.calculate_remaining_price(rec.date_order,rec.department,rec.product_id)
                            
                            terms.append((0, 0, values))
            
            _logger.info('-------terms************ = %s',terms)
            # if terms == []:
            #     _logger.info('-------terms array is empty')
            #     clause_final = [('id', '=',request_id)]
            #     search_results= self.env['purchase.request'].search(clause_final).ids
            #     if search_results:
            #         _logger.info('-------search_results************ = %s',search_results)
            #         # _logger.info('-------term--------- = %s',terms)
            #         # terms=self.env['purchase.order.line'].browse(search_results)
            #         for search_result2 in self.env['purchase.request'].browse(search_results):
            #             search_result2.write({"state":"done"})
            self.order_line=terms
            return 
    approve_uid  = fields.Many2one('res.users', 'Approved By')
    READONLY_STATES = {
        'purchase': [('readonly', True)],
        'done': [('readonly', True)],
        'cancel': [('readonly', True)],
    }
    department_id = fields.Many2one('hr.department', string='Department')
    purchase_request = fields.Many2one('purchase.request',required=True,
    string='Purchase request')
    branch = fields.Many2one('company.branch', string='Branch')
    name = fields.Char('Order Reference', required=True, index=True, copy=False, default='New')
    origin = fields.Char('Source Document', copy=False,\
        help="Reference of the document that generated this purchase order "
             "request (e.g. a sales order)")
    partner_ref = fields.Char('Vendor Reference (PI)',required=False, copy=False,\
        help="Reference of the sales order or bid sent by the vendor. "
             "It's used to do the matching when you receive the "
             "products as this reference is usually written on the "
             "delivery order sent by your vendor.")
    date_order = fields.Datetime('Order Date', states=READONLY_STATES, index=True, copy=False, default=fields.Datetime.now,\
        help="Depicts the date where the Quotation should be validated and converted into a purchase order.")
    date_approve = fields.Date('Approval Date', readonly=1, index=True, copy=False)
    partner_id = fields.Many2one('res.partner', string='Vendor',
      states=READONLY_STATES, change_default=True,required=True, track_visibility='always')
    dest_address_id = fields.Many2one('res.partner', string='Drop Ship Address', 
    states=READONLY_STATES,\
        help="Put an address if you want to deliver directly from the vendor to the customer. "\
             "Otherwise, keep empty to deliver to your own company.")
    currency_id = fields.Many2one('res.currency', 'Currency',  states=READONLY_STATES,\
        default=lambda self: self.env.user.company_id.currency_id.id)
    state = fields.Selection([

        ('RFQ', 'RFQ'),
        ('sent', 'RFQ Sent'),
        ('approved', 'RFQ Approved'),
        ('to approve', 'To Approve'),
        ('draft purchase', 'Draft PO'),
        ('purchase', 'Purchase Order'),
        ('done', 'Locked'),
        ('cancel', 'Cancelled')
        ], string='Status', readonly=True, index=True, copy=False, default='RFQ',
         track_visibility='onchange')
    order_line = fields.One2many('purchase.order.line', 'order_id', 
    string='Order Lines', states={'cancel': [('readonly', True)], 'done': [('readonly', True)]},
     copy=True,default=_default_so_tc)
    notes = fields.Text('Terms and Conditions')

    invoice_count = fields.Integer(compute="_compute_invoice", string='# of Bills', copy=False, default=0, store=True)
    invoice_ids = fields.Many2many('account.invoice', compute="_compute_invoice", string='Bills', copy=False, store=True)
    invoice_status = fields.Selection([
        ('no', 'Nothing to Bill'),
        ('to invoice', 'Waiting Bills'),
        ('invoiced', 'No Bill to Receive'),
        ], string='Billing Status', compute='_get_invoiced', store=True, readonly=True, copy=False, default='no')

    picking_count = fields.Integer(compute='_compute_picking', string='Receptions', default=0, store=True)
    picking_ids = fields.Many2many('stock.picking', compute='_compute_picking', string='Receptions', copy=False, store=True)

    # There is no inverse function on purpose since the date may be different on each line
    date_planned = fields.Datetime(string='Scheduled Date',  store=True, index=True)

    amount_untaxed = fields.Monetary(string='Untaxed Amount', store=True, readonly=True, compute='_amount_all', track_visibility='always')
    amount_tax = fields.Monetary(string='Taxes', store=True, readonly=True, compute='_amount_all')
    amount_total = fields.Monetary(string='Total', store=True, readonly=True, compute='_amount_all')

    fiscal_position_id = fields.Many2one('account.fiscal.position', string='Fiscal Position', oldname='fiscal_position')
    payment_term_id = fields.Many2one('account.payment.term', 'Payment Terms')
    incoterm_id = fields.Many2one('stock.incoterms', 'Incoterm', states={'done': [('readonly', True)]}, help="International Commercial Terms are a series of predefined commercial terms used in international transactions.")

    product_id = fields.Many2one('product.product', related='order_line.product_id',
     string='Product')
    create_uid = fields.Many2one('res.users', 'Responsible')
    company_id = fields.Many2one('res.company', 'Company', index=True, 
    states=READONLY_STATES, default=lambda self: self.env.user.company_id.id)

    picking_type_id = fields.Many2one('stock.picking.type', 'Deliver To', required=True,
        help="This will determine operation type of incoming shipment")
    default_location_dest_id_usage = fields.Selection(related='picking_type_id.default_location_dest_id.usage', string='Destination Location Type',\
        help="Technical field used to display the Drop Ship Address", readonly=True)
    group_id = fields.Many2one('procurement.group', string="Procurement Group", copy=False)
    is_shipped = fields.Boolean(compute="_compute_is_shipped")

    website_url = fields.Char(
        'Website URL', compute='_website_url',
        help='The full URL to access the document through the website.')
    payment_type= fields.Selection([
        ('bank', 'Bank'),
        ('pre_payment', 'Pre Payment'),
        ('credit', 'Credit'),
        ],'Payment Type')

    @api.multi
    def action_convert_to_RFQ(self):
        for order in self:
            if order.state  == 'approved':
                order.write({'state': 'RFQ'})
        return True
    @api.multi
    def approve_request(self):
        for order in self:
            if order.state  == 'draft':
                order.write({'state': 'approved'})
        return True
        
    @api.multi
    def cancel_request(self):
        for order in self:
            if order.state  == 'draft':
                order.write({'state': 'cancel'})
        return True
    def _website_url(self):
        for order in self:
            order.website_url = '/my/purchase/%s' % (order.id)

    @api.model
    def name_search(self, name, args=None, operator='ilike', limit=100):
        args = args or []
        domain = []
        if name:
            domain = ['|', ('name', operator, name), ('partner_ref', operator, name)]
        pos = self.search(domain + args, limit=limit)
        return pos.name_get()

    @api.multi
    @api.depends('name', 'partner_ref')
    def name_get(self):
        result = []
        for po in self:
            name = po.name
            if po.partner_ref:
                name += ' ('+po.partner_ref+')'
            if self.env.context.get('show_total_amount') and po.amount_total:
                name += ': ' + formatLang(self.env, po.amount_total, currency_obj=po.currency_id)
            result.append((po.id, name))
        return result

    @api.model
    def create(self, vals):
        self._compute_purchase_request()
        if vals.get('name', 'New') == 'New':
            vals['name'] = self.env['ir.sequence'].next_by_code('purchase.order') or '/'
        return super(PurchaseOrder, self).create(vals)

    @api.multi
    def unlink(self):
        for order in self:
            if not order.state == 'cancel':
                raise UserError(_('In order to delete a purchase order, you must cancel it first.'))
        return super(PurchaseOrder, self).unlink()

    @api.multi
    def copy(self, default=None):
        new_po = super(PurchaseOrder, self).copy(default=default)
        for line in new_po.order_line:
            seller = line.product_id._select_seller(
                partner_id=line.partner_id, quantity=line.product_qty,
                date=line.order_id.date_order and line.order_id.date_order[:10], uom_id=line.product_uom)
            line.date_planned = line._get_date_planned(seller)
        return new_po

    @api.multi
    def _track_subtype(self, init_values):
        self.ensure_one()
        # if 'state' in init_values and self.state == 'purchase':
        #     return 'purchase.mt_rfq_approved'
        # elif 'state' in init_values and self.state == 'to approve':
        #     return 'purchase.mt_rfq_confirmed'
        # elif 'state' in init_values and self.state == 'done':
        #     return 'purchase.mt_rfq_done'
        return super(PurchaseOrder, self)._track_subtype(init_values)

    @api.onchange('partner_id', 'company_id')
    def onchange_partner_id(self):
        if not self.partner_id:
            self.fiscal_position_id = False
            self.payment_term_id = False
            self.currency_id = False
        else:
            self.fiscal_position_id = self.env['account.fiscal.position'].with_context(company_id=self.company_id.id).get_fiscal_position(self.partner_id.id)
            self.payment_term_id = self.partner_id.property_supplier_payment_term_id.id
            self.currency_id = self.partner_id.property_purchase_currency_id.id or self.env.user.company_id.currency_id.id
        return {}

    @api.onchange('fiscal_position_id')
    def _compute_tax_id(self):
        """
        Trigger the recompute of the taxes if the fiscal position is changed on the PO.
        """
        for order in self:
            order.order_line._compute_tax_id()

    @api.onchange('partner_id')
    def onchange_partner_id_warning(self):
        if not self.partner_id:
            return
        warning = {}
        title = False
        message = False

        partner = self.partner_id

        # If partner has no warning, check its company
        if partner.purchase_warn == 'no-message' and partner.parent_id:
            partner = partner.parent_id

        if partner.purchase_warn != 'no-message':
            # Block if partner only has warning but parent company is blocked
            if partner.purchase_warn != 'block' and partner.parent_id and partner.parent_id.purchase_warn == 'block':
                partner = partner.parent_id
            title = _("Warning for %s") % partner.name
            message = partner.purchase_warn_msg
            warning = {
                'title': title,
                'message': message
                }
            if partner.purchase_warn == 'block':
                self.update({'partner_id': False})
            return {'warning': warning}
        return {}

    @api.onchange('picking_type_id')
    def _onchange_picking_type_id(self):
        if self.picking_type_id.default_location_dest_id.usage != 'customer':
            self.dest_address_id = False

    @api.multi
    def action_rfq_send(self):
        '''
        This function opens a window to compose an email, with the edi purchase template message loaded by default
        '''
        self.ensure_one()
        ir_model_data = self.env['ir.model.data']
        try:
            if self.env.context.get('send_rfq', False):
                template_id = ir_model_data.get_object_reference('purchase', 'email_template_edi_purchase')[1]
            else:
                template_id = ir_model_data.get_object_reference('purchase', 'email_template_edi_purchase_done')[1]
        except ValueError:
            template_id = False
        try:
            compose_form_id = ir_model_data.get_object_reference('mail', 'email_compose_message_wizard_form')[1]
        except ValueError:
            compose_form_id = False
        ctx = dict(self.env.context or {})
        ctx.update({
            'default_model': 'purchase.order',
            'default_res_id': self.ids[0],
            'default_use_template': bool(template_id),
            'default_template_id': template_id,
            'default_composition_mode': 'comment',
            'custom_layout': "purchase.mail_template_data_notification_email_purchase_order",
            'force_email': True
        })
        return {
            'name': _('Compose Email'),
            'type': 'ir.actions.act_window',
            'view_type': 'form',
            'view_mode': 'form',
            'res_model': 'mail.compose.message',
            'views': [(compose_form_id, 'form')],
            'view_id': compose_form_id,
            'target': 'new',
            'context': ctx,
        }

    @api.multi
    def print_quotation(self):
        return self.env.ref('purchase.report_purchase_quotation').report_action(self)

    @api.multi
    def button_approve(self, force=False):
        self.write({'state': 'purchase', 'date_approve': fields.Date.context_today(self)})
        self._create_picking()
        if self.company_id.po_lock == 'lock':
            self.write({'state': 'done'})
        return {}

    @api.multi
    def button_draft(self):
        self.write({'state': 'RFQ'})
        return {}

    @api.multi
    def button_confirm(self):
        for order in self:
            # if order.state not in ['draft', 'sent']:
            #     continue
            # order._add_supplier_to_product()
            # # Deal with double validation process
            # if order.company_id.po_double_validation == 'one_step'\
            #         or (order.company_id.po_double_validation == 'two_step'\
            #             and order.amount_total < self.env.user.company_id.currency_id.compute(order.company_id.po_double_validation_amount, order.currency_id))\
            #         or order.user_has_groups('purchase.group_purchase_manager'):
            #     order.button_approve()
            # else:
            _logger.info('-------purchase_request************ = %s',order.purchase_request.id)
            if order.purchase_request.id > 0: 
                order.write({'state': 'draft purchase'})
            else:
                raise UserError('Unable to confirm this RFQ. You must first select purchase request.')
        return True
    @api.multi
    def button_approve_order(self):
        return {
                    'name':'Approve',
                    'view_type':'form',
                    'view_mode':'form',
                    'res_model':'purchase.order.confirm.approve',
                    'type':'ir.actions.act_window',
                    'target':'new',
                }
        

    @api.multi
    def button_cancel(self):
        for order in self:
            for pick in order.picking_ids:
                if pick.state == 'done':
                    raise UserError(_('Unable to cancel purchase order %s as some receptions have already been done.') % (order.name))
            for inv in order.invoice_ids:
                if inv and inv.state not in ('cancel', 'draft'):
                    raise UserError(_("Unable to cancel this purchase order. You must first cancel related vendor bills."))

            # If the product is MTO, change the procure_method of the the closest move to purchase to MTS.
            # The purpose is to link the po that the user will manually generate to the existing moves's chain.
            if order.state in ('draft', 'sent', 'to approve'):
                for order_line in order.order_line:
                    if order_line.move_dest_ids:
                        siblings_states = (order_line.move_dest_ids.mapped('move_orig_ids')).mapped('state')
                        if all(state in ('done', 'cancel') for state in siblings_states):
                            order_line.move_dest_ids.write({'procure_method': 'make_to_stock'})

            for pick in order.picking_ids.filtered(lambda r: r.state != 'cancel'):
                pick.action_cancel()

        self.write({'state': 'cancel'})

    @api.multi
    def button_unlock(self):
        self.write({'state': 'purchase'})

    @api.multi
    def button_done(self):
        self.write({'state': 'done'})

    @api.multi
    def _get_destination_location(self):
        self.ensure_one()
        if self.dest_address_id:
            return self.dest_address_id.property_stock_customer.id
        return self.picking_type_id.default_location_dest_id.id

    @api.model
    def _prepare_picking(self):
        source_doc=len(str(self.id))
        _logger.error("!!!!!!!!----------- vals source_doc= =%s",source_doc)
        _logger.error("!!!!!!!!----------- vals self-name= =%s",self.name)
        if not self.group_id:
            self.group_id = self.group_id.create({
                'name': self.name,
                'partner_id': self.partner_id.id
            })
        if not self.partner_id.property_stock_supplier.id:
            raise UserError(_("You must set a Vendor Location for this partner %s") % self.partner_id.name)
        count=6- source_doc
        new_id=''
        for i in range(1,count):
            new_id=new_id + '0'
        
        _logger.error("!!!!!!!!----------- vals new_id= =%s",new_id)
        new_id='PO'+new_id + str(self.id)
        _logger.error("!!!!!!!!----------- vals new_id= =%s",new_id)
        return {
            'picking_type_id': self.picking_type_id.id,
            'partner_id': self.partner_id.id,
            'date': self.date_order,
            'origin': new_id,
            'is_local_purchase':True,
            'purchase_order':self.id,
            'state': 'assigned',
            'location_dest_id': self._get_destination_location(),
            'location_id': self.partner_id.property_stock_supplier.id,
            'company_id': self.company_id.id,
        }

    @api.multi
    def _create_picking(self):
        StockPicking = self.env['stock.picking']
        for order in self:
            if any([ptype in ['product', 'consu'] for ptype in order.order_line.mapped('product_id.type')]):
                pickings = order.picking_ids.filtered(lambda x: x.state not in ('done','cancel'))
                if not pickings:
                    res = order._prepare_picking()
                    picking = StockPicking.create(res)
                else:
                    picking = pickings[0]
                moves = order.order_line._create_stock_moves(picking)
                moves = moves.filtered(lambda x: x.state not in ('done', 'cancel'))._action_confirm()
                seq = 0
                for move in sorted(moves, key=lambda move: move.date_expected):
                    seq += 5
                    move.sequence = seq
                moves._action_assign()
                picking.message_post_with_view('mail.message_origin_link',
                    values={'self': picking, 'origin': order},
                    subtype_id=self.env.ref('mail.mt_note').id)
        return True

    @api.multi
    def _add_supplier_to_product(self):
        # Add the partner in the supplier list of the product if the supplier is not registered for
        # this product. We limit to 10 the number of suppliers for a product to avoid the mess that
        # could be caused for some generic products ("Miscellaneous").
        for line in self.order_line:
            # Do not add a contact as a supplier
            partner = self.partner_id if not self.partner_id.parent_id else self.partner_id.parent_id
            if partner not in line.product_id.seller_ids.mapped('name') and len(line.product_id.seller_ids) <= 10:
                currency = partner.property_purchase_currency_id or self.env.user.company_id.currency_id
                supplierinfo = {
                    'name': partner.id,
                    'sequence': max(line.product_id.seller_ids.mapped('sequence')) + 1 if line.product_id.seller_ids else 1,
                    'product_uom': line.product_uom.id,
                    'min_qty': 0.0,
                    'price': self.currency_id.compute(line.price_unit, currency),
                    'currency_id': currency.id,
                    'delay': 0,
                }
                vals = {
                    'seller_ids': [(0, 0, supplierinfo)],
                }
                try:
                    line.product_id.write(vals)
                except AccessError:  # no write access rights -> just ignore
                    break

    @api.multi
    def action_view_picking(self):
        '''
        This function returns an action that display existing picking orders of given purchase order ids.
        When only one found, show the picking immediately.
        '''
        action = self.env.ref('stock.action_picking_tree')
        result = action.read()[0]

        #override the context to get rid of the default filtering on operation type
        result['context'] = {}
        pick_ids = self.mapped('picking_ids')
        #choose the view_mode accordingly
        if len(pick_ids) > 1:
            result['domain'] = "[('id','in',%s)]" % (pick_ids.ids)
        elif len(pick_ids) == 1:
            res = self.env.ref('stock.view_picking_form', False)
            result['views'] = [(res and res.id or False, 'form')]
            result['res_id'] = pick_ids.id
        return result

    @api.multi
    def action_view_invoice(self):
        '''
        This function returns an action that display existing vendor bills of given purchase order ids.
        When only one found, show the vendor bill immediately.
        '''
        action = self.env.ref('account.action_invoice_tree2')
        result = action.read()[0]

        #override the context to get rid of the default filtering
        result['context'] = {'type': 'in_invoice', 'default_purchase_id': self.id}

        if not self.invoice_ids:
            # Choose a default account journal in the same currency in case a new invoice is created
            journal_domain = [
                ('type', '=', 'purchase'),
                ('company_id', '=', self.company_id.id),
                ('currency_id', '=', self.currency_id.id),
            ]
            default_journal_id = self.env['account.journal'].search(journal_domain, limit=1)
            if default_journal_id:
                result['context']['default_journal_id'] = default_journal_id.id
        else:
            # Use the same account journal than a previous invoice
            result['context']['default_journal_id'] = self.invoice_ids[0].journal_id.id

        #choose the view_mode accordingly
        if len(self.invoice_ids) != 1:
            result['domain'] = "[('id', 'in', " + str(self.invoice_ids.ids) + ")]"
        elif len(self.invoice_ids) == 1:
            res = self.env.ref('account.invoice_supplier_form', False)
            result['views'] = [(res and res.id or False, 'form')]
            result['res_id'] = self.invoice_ids.id
        return result

    @api.multi
    def action_set_date_planned(self):
        for order in self:
            order.order_line.update({'date_planned': order.date_planned})

class PurchaseOrderLine1(models.Model):
    _name = 'purchase.order.line1'
    product_qty = fields.Float(string='Quantity', digits = (16, 0), required=True,default=0)
    # product_uom = fields.Many2one('product.uom', string='Product Unit of Measure')
    # digits=dp.get_precision('Product Unit of Measure') -- use this if qty should be an integer
    remaning_budget_qty=fields.Float(string='Remaning Budget Quantity', digits = (16, 0))
    name = fields.Text(string='Description', required=True)
    product_id = fields.Many2one('product.product', string='Product', 
    domain=[('purchase_ok', '=', True)], change_default=True, required=True)
    request_id = fields.Many2one('purchase.request', string='Order Reference', 
    index=True, ondelete='cascade')
    date_order=fields.Datetime(related='request_id.date_order', store=True)
    department=fields.Many2one('hr.department',required=True,
    string='Department',store=True)
    expected_price= fields.Float( string="Expected Unit of Price", store=True)
    expected_total_price = fields.Float(
        string="Expected Total Price", 
        compute="_compute_expected_total_price", 
        store=True, 
        readonly=True
    )

    state = fields.Selection([
        ('draft', 'Draft'),
        ('PR Approved', 'PR Approved'),
         ('RFQ', 'RFQ'),
        ('sent', 'RFQ Sent'),
        ('approved', 'RFQ Approved'),
        ('to approve', 'To Approve'),
        ('purchase', 'Purchase Order'),
        ('done', 'Locked'),
        ('cancel', 'Cancelled')], default='draft' ,store=True)
    partner_id = fields.Many2one('res.partner', related='request_id.partner_id', 
    string='Partner', readonly=True, store=True)
    product_uom = fields.Many2one('product.uom', string='Product Unit of Measure')
    
    # @api.onchange('expected_price', 'expected_total_price', 'product_qty')
    # def _onchange_liter_price_amount(self):
	
    #     expected_price = float(self.expected_price)
    #     product_qty = float(self.product_qty)
    #     expected_total_price = float(self.expected_total_price)

    #     if expected_price > 0 and product_qty > 0 and round(expected_price * product_qty, 2) != expected_total_price:
    #         self.expected_total_price = round(expected_price * product_qty, 2)
    #     elif expected_total_price > 0 and expected_price > 0 and round(expected_total_price / expected_price, 2) != product_qty:
    #         self.product_qty = round(expected_total_price / expected_price, 2)
    #     elif expected_total_price > 0 and product_qty > 0 and round(expected_total_price / product_qty, 2) != expected_price:
    #         self.liter = round(expected_total_price / product_qty, 2)

    @api.depends('expected_price', 'product_qty')
    def _compute_expected_total_price(self):
        for line in self:
            if line.expected_price > 0 and line.product_qty > 0:
                line.expected_total_price = round(line.expected_price * line.product_qty, 2)
            else:
                line.expected_total_price = 0

    @api.onchange('expected_price', 'product_qty')
    def _onchange_liter_price_amount(self):
        expected_price = self.expected_price
        product_qty = self.product_qty

        # Ensure both expected_price and product_qty are positive to calculate expected_total_price
        if expected_price > 0 and product_qty > 0:
            self.expected_total_price = round(expected_price * product_qty, 2)
        else:
            self.expected_total_price = 0  # Reset if either of the fields is zero
    
    @api.model
    def create(self, vals):
        if vals.get('remaning_budget_qty'):
            request_id_val=0
            if vals.get('product_qty') > vals.get('remaning_budget_qty'):
                raise UserError(_('Please make budget adjustment before request this product')) 
            else:
                val1=vals.get('request_id')
                _logger.error("!!!!!!!!----------- vals request id= =%s",vals.get('request_id'))
                for search_result3 in self.env['purchase.request'].browse(val1):
                    request_id_val=search_result3.id
                        
                clause_final = [('id', '=', request_id_val)]
                search_results= self.env['purchase.request'].search(clause_final).ids
                
                if search_results:
                    for search_result in self.env['purchase.request'].browse(search_results):
                        
                        _logger.error("!before update loop----------- vals=%s",search_result)     
                        search_result.write({'state': 'item_filled'})
                return super(PurchaseOrderLine1, self).create(vals)
        else:
            raise UserError(_('Please make budget adjustment before request this product')) 
    @api.onchange('remaning_budget_qty')
    def onchange_remaning_budget_qty(self):
        if self.product_qty > self.remaning_budget_qty:
            raise UserError(_('--Please make budget adjustment before request this product')) 
    @api.onchange('product_qty')
    def onchange_product_qty(self):
        if self.product_qty >1:
            if self.product_qty > self.remaning_budget_qty:
                raise UserError(_('!!Please make budget adjustment before request this product')) 
        
    @api.onchange('department')
    def onchange_department(self):
        self.onchange_product_id()
    @api.onchange('product_id')
    def onchange_product_id(self):
        if self.department and self.product_id:
            self.product_uom = self.product_id.uom_po_id or self.product_id.uom_id
            self.remaning_budget_qty=0
            self.product_qty=0

            product_lang = self.product_id.with_context(
                lang=self.partner_id.lang,
                partner_id=self.partner_id.id,
            )
            self.name = product_lang.display_name
            self._suggest_quantity()
            clause_final = ['&',('start_date', '<', datetime.now()),('end_date', '>', datetime.now())]
            _logger.info('-------clause_final************ = %s',clause_final)
            _logger.info('-------self.department************ = %s',self.department)
            search_results= self.env['accounting.period'].search(clause_final,order='id desc', limit=1).id
            _logger.info('!!!!!!!!!!!-------search_results************ = %s',search_results)
            total_remaining_qty=0
            if search_results:  
                # for search_result in self.env['accounting.period'].browse(search_results):
                #     _logger.info('-------search_result************ = %s',search_result)
                clause_final2 = ['&',('budget_period', '=', search_results),('department_id', '=', self.department.id)]
                _logger.info('-------clause_final3************ = %s',clause_final2)
                search_results2= self.env['purchase.budget'].search(clause_final2).ids
                _logger.info('-------search_results2 --------************ = %s',search_results2)
                if search_results2:  
                    for search_result2 in self.env['purchase.budget'].browse(search_results2):
                        clause_final3 = ['&',('budget_id', '=', search_result2.id),('product_id', '=', self.product_id.id)]
                        _logger.info('-------clause_final3************ = %s',clause_final3)
                        search_results3= self.env['purchase.budget.items'].search(clause_final3,order='date desc', limit=1).ids
                        
                        if search_results3:  
                            for search_result3 in self.env['purchase.budget.items'].browse(search_results3):
                                _logger.info('-------search_result3.actual_qty************ = %s',search_result3.actual_qty)
                                total_remaining_qty=total_remaining_qty + search_result3.actual_qty
                    self.remaning_budget_qty=total_remaining_qty
                else:
                    raise UserError(_('Please make budget adjustment before request this product')) 
        

    def _suggest_quantity(self):
        '''
        Suggest a minimal quantity based on the seller
        '''
        if not self.product_id:
            return

        seller_min_qty = self.product_id.seller_ids\
            .filtered(lambda r: r.name == self.request_id.partner_id)\
            .sorted(key=lambda r: r.min_qty)
        if seller_min_qty:
            self.product_qty = seller_min_qty[0].min_qty or 1.0
            self.product_uom = seller_min_qty[0].product_uom
        else:
            self.product_qty = 1.0

class PurchaseOrderLine(models.Model):
    _name = 'purchase.order.line'
    _description = 'Purchase Order Line'
    _order = 'order_id, sequence, id'

    @api.depends('product_qty', 'price_unit', 'taxes_id')
    def _compute_amount(self):
        for line in self:
            taxes = line.taxes_id.compute_all(line.price_unit, line.order_id.currency_id, line.product_qty, product=line.product_id, partner=line.order_id.partner_id)
            line.update({
                'price_tax': sum(t.get('amount', 0.0) for t in taxes.get('taxes', [])),
                'price_total': taxes['total_included'],
                'price_subtotal': taxes['total_excluded'],
            })
            
            _logger.info('-------onchange of price line=************ =%s ',line)
            _logger.info('-------onchange of price line.remaning_budget_price=************ =%s ',line.remaning_budget_price)
            _logger.info('-------onchange of price price_subtotal=************ =%s ',line.price_subtotal)
            # if line.remaning_budget_price < line.price_subtotal:
            #     raise UserError('You cannot make RFQ for this purchase request.\n'
            #                         'Make buget adjustment first.')

    @api.multi
    def _compute_tax_id(self):
        for line in self:
            fpos = line.order_id.fiscal_position_id or line.order_id.partner_id.property_account_position_id
            # If company_id is set, always filter taxes by the company
            taxes = line.product_id.supplier_taxes_id.filtered(lambda r: not line.company_id or r.company_id == line.company_id)
            line.taxes_id = fpos.map_tax(taxes, line.product_id, line.order_id.partner_id) if fpos else taxes

    @api.depends('invoice_lines.invoice_id.state', 'invoice_lines.quantity')
    def _compute_qty_invoiced(self):
        for line in self:
            qty = 0.0
            for inv_line in line.invoice_lines:
                if inv_line.invoice_id.state not in ['cancel']:
                    if inv_line.invoice_id.type == 'in_invoice':
                        qty += inv_line.uom_id._compute_quantity(inv_line.quantity, line.product_uom)
                    elif inv_line.invoice_id.type == 'in_refund':
                        qty -= inv_line.uom_id._compute_quantity(inv_line.quantity, line.product_uom)
            line.qty_invoiced = qty

    @api.depends('order_id.state', 'move_ids.state', 'move_ids.product_uom_qty')
    def _compute_qty_received(self):
        for line in self:
            if line.order_id.state not in ['purchase', 'done']:
                line.qty_received = 0.0
                continue
            if line.product_id.type not in ['consu', 'product']:
                line.qty_received = line.product_qty
                continue
            total = 0.0
            for move in line.move_ids:
                if move.state == 'done':
                    if move.location_dest_id.usage == "supplier":
                        if move.to_refund:
                            total -= move.product_uom._compute_quantity(move.product_uom_qty, line.product_uom)
                    else:
                        total += move.product_uom._compute_quantity(move.product_uom_qty, line.product_uom)
            line.qty_received = total

    @api.model
    def create(self, values):

        _logger.info("+++++++++++++create order line+++++++++++++")
        _logger.info("+++++++++++++values=%s",values)
        _logger.info("+++++++++++++self.product_uom=%s",self.product_uom)
        _logger.info("+++++++++++++value-product_uom=%s",values.get('product_uom'))
        _logger.info("+++++++++++++value-product_id=%s",values.get('product_id'))
        _logger.info(self.product_id)
        product_tmpl_id= self.env['product.product'].search( [('id', '=',values.get('product_id'))]).product_tmpl_id
        _logger.info("+++++++++++++value-product_tmpl_id=%s",product_tmpl_id)
        clause_final = [('id', '=',product_tmpl_id.id)]
        search_results= self.env['product.template'].search(clause_final).ids
        if search_results:
            _logger.info('-------search_results************ = %s',search_results)
            for search_result2 in self.env['product.template'].browse(search_results):
                _logger.info('-------search_result2.uom_id************ = %s',search_result2.uom_id)
                values['product_uom']=search_result2.uom_id.id
        _logger.info("#######++++++")
        _logger.info("+++++++++++++remaning_budget_price=%s",values.get('remaning_budget_price'))
        _logger.info("+++++++++++++price_subtotal=%s",values.get('price_subtotal'))
        # if values.get('remaning_budget_price') < values.get('price_subtotal'):
        #     raise UserError('You cannot make RFQ for this purchase request.\n'
        #                             'Make buget adjustment first.')
        # else:
        line = super(PurchaseOrderLine, self).create(values)

        _logger.info("#######++++++ product id")
        _logger.info(line.product_id.id)
        _logger.info("#######++++++ request")
        _logger.info(line.purchase_request.id)
        clause_final = ['&',('product_id', '=',line.product_id.id),('request_id','=',line.purchase_request.id)]
        search_results= self.env['purchase.order.line1'].search(clause_final).ids
        if search_results:
            _logger.info('-------search_results************ = %s',search_results)
            # _logger.info('-------term--------- = %s',terms)
            # terms=self.env['purchase.order.line'].browse(search_results)
            for search_result2 in self.env['purchase.order.line1'].browse(search_results):
                search_result2.write({"state": "RFQ"})
        if line.order_id.state == 'purchase':
            line._create_or_update_picking()
            msg = _("Extra line with %s ") % (line.product_id.display_name,)
            line.order_id.message_post(body=msg)
        return line

    @api.multi
    def write(self, values):
        if 'product_qty' in values:
            for line in self:
                if line.order_id.state == 'purchase':
                    line.order_id.message_post_with_view('purchase.track_po_line_template',
                                                         values={'line': line, 'product_qty': values['product_qty']},
                                                         subtype_id=self.env.ref('mail.mt_note').id)
        result = super(PurchaseOrderLine, self).write(values)
        # Update expected date of corresponding moves
        if 'date_planned' in values:
            self.env['stock.move'].search([
                ('purchase_line_id', 'in', self.ids), ('state', '!=', 'done')
            ]).write({'date_expected': values['date_planned']})
        if 'product_qty' in values:
            self.filtered(lambda l: l.order_id.state == 'purchase')._create_or_update_picking()
        return result

    name = fields.Text(string='Description', required=True)
    department=fields.Many2one('hr.department', string='Department',store=True)
    sequence = fields.Integer(string='Sequence', default=10)
    product_qty = fields.Float(string='Quantity', digits=dp.get_precision('Product Unit of Measure'))
    date_planned = fields.Datetime(string='Scheduled Date', index=True)
    taxes_id = fields.Many2many('account.tax', string='Taxes', domain=['|', ('active', '=', False), ('active', '=', True)])
    product_id = fields.Many2one('product.product', string='Product', 
    domain=[('purchase_ok', '=', True)], change_default=True, required=True)
    product_uom = fields.Many2one('product.uom', string='Product Unit of Measure',
    readonly=True,store=True, index=True, copy=True)
    product_image = fields.Binary(
        'Product Image', related="product_id.image",
        help="Non-stored related field to allow portal user to see the image of the product he has ordered")
    move_ids = fields.One2many('stock.move', 'purchase_line_id', string='Reservation', readonly=True, ondelete='set null', copy=False)
    price_unit = fields.Float(string='Unit Price',required=True,  digits=dp.get_precision('Product Price'))

    price_subtotal = fields.Monetary(compute='_compute_amount', string='Subtotal', store=True)
    remaning_budget_price = fields.Monetary(string='Remaining Budget Price', store=True)
    
    date_order=fields.Datetime(string="date_order", store=True)
    price_total = fields.Monetary(compute='_compute_amount', string='Total', store=True)
    price_tax = fields.Float(compute='_compute_amount', string='Tax', store=True)
    # request_id = fields.Many2one('purchase.request', string='Order Reference', 
    # index=True, ondelete='cascade')
    order_id = fields.Many2one('purchase.order', string='Order Reference', 
    index=True, ondelete='cascade')
    account_analytic_id = fields.Many2one('account.analytic.account', string='Analytic Account')
    analytic_tag_ids = fields.Many2many('account.analytic.tag', string='Analytic Tags')
    company_id = fields.Many2one('res.company', 
    related='order_id.company_id', string='Company', store=True, readonly=True)
    state = fields.Selection(related='order_id.state', store=True)
    purchase_request = fields.Many2one(related='order_id.purchase_request', store=True)
    
    invoice_lines = fields.One2many('account.invoice.line', 'purchase_line_id', string="Bill Lines", readonly=True, copy=False)

    # Replace by invoiced Qty
    qty_invoiced = fields.Float(compute='_compute_qty_invoiced', string="Billed Qty", digits=dp.get_precision('Product Unit of Measure'), store=True)
    qty_received = fields.Float(compute='_compute_qty_received', string="Received Qty", digits=dp.get_precision('Product Unit of Measure'), store=True)

    partner_id = fields.Many2one('res.partner', related='order_id.partner_id', 
    string='Partner', readonly=True, store=True)
    currency_id = fields.Many2one(related='order_id.currency_id',
     store=True, string='Currency', readonly=True)
    date_order = fields.Datetime(related='order_id.date_order', string='Order Date')

    orderpoint_id = fields.Many2one('stock.warehouse.orderpoint', 'Orderpoint')
    move_dest_ids = fields.One2many('stock.move', 'created_purchase_line_id', 'Downstream Moves')

    @api.multi
    def _create_or_update_picking(self):
        for line in self:
            if line.product_id.type in ('product', 'consu'):
                # Prevent decreasing below received quantity
                if float_compare(line.product_qty, line.qty_received, line.product_uom.rounding) < 0:
                    raise UserError('You cannot decrease the ordered quantity below the received quantity.\n'
                                    'Create a return first.')

                if float_compare(line.product_qty, line.qty_invoiced, line.product_uom.rounding) == -1:
                    # If the quantity is now below the invoiced quantity, create an activity on the vendor bill
                    # inviting the user to create a refund.
                    activity = self.env['mail.activity'].sudo().create({
                        'activity_type_id': self.env.ref('mail.mail_activity_data_todo').id,
                        'note': _('The quantities on your purchase order indicate less than billed. You should ask for a refund. '),
                        'res_id': line.invoice_lines[0].invoice_id.id,
                        'res_model_id': self.env.ref('account.model_account_invoice').id,
                    })
                    activity._onchange_activity_type_id()

                # If the user increased quantity of existing line or created a new line
                pickings = line.order_id.picking_ids.filtered(lambda x: x.state not in ('done', 'cancel') and x.location_dest_id.usage in ('internal', 'transit'))
                picking = pickings and pickings[0] or False
                if not picking:
                    res = line.order_id._prepare_picking()
                    picking = self.env['stock.picking'].create(res)
                move_vals = line._prepare_stock_moves(picking)
                for move_val in move_vals:
                    self.env['stock.move']\
                        .create(move_val)\
                        ._action_confirm()\
                        ._action_assign()

    @api.multi
    def _get_stock_move_price_unit(self):
        self.ensure_one()
        line = self[0]
        order = line.order_id
        price_unit = line.price_unit
        if line.taxes_id:
            price_unit = line.taxes_id.with_context(round=False).compute_all(
                price_unit, currency=line.order_id.currency_id, quantity=1.0, product=line.product_id, partner=line.order_id.partner_id
            )['total_excluded']
        if line.product_uom.id != line.product_id.uom_id.id:
            price_unit *= line.product_uom.factor / line.product_id.uom_id.factor
        if order.currency_id != order.company_id.currency_id:
            price_unit = order.currency_id.compute(price_unit, order.company_id.currency_id, round=False)
        return price_unit

    @api.multi
    def _prepare_stock_moves(self, picking):
        """ Prepare the stock moves data for one order line. This function returns a list of
        dictionary ready to be used in stock.move's create()
        """
        self.ensure_one()
        
        _logger.info('-------self.ensure_one()************ = %s',self.ensure_one())
        _logger.info('-------self.id************ = %s',self.id)
        _logger.info('-------self.move_ids************ = %s',self.move_ids)
        res = []
        if self.product_id.type not in ['product', 'consu']:
            return res
        qty = 0.0
        price_unit = self._get_stock_move_price_unit()
        p = self.env['stock.move']
        p_obj = p.search([]) 
        # p_obj.filtered(lambda r: r.origin_id.id IN order_ids)
        is_found=False
        for move in self.move_ids.filtered(lambda x: x.state != 'cancel' and not x.location_dest_id.usage == "supplier"):
            is_found=True
            _logger.info('-------move.product_uom_qty=************ = %s',move.product_uom_qty)
            _logger.info('-------self.product_uom,=************ = %s',self.product_uom)
            qty += move.product_uom._compute_quantity(move.product_uom_qty, self.product_uom, rounding_method='HALF-UP')
            _logger.info('-------qty=************ = %s',qty)
        _logger.info('-------TOTAl qty=************ = %s',qty)
        # if is_found == False:
        #     for move in p_obj.filtered(lambda x: x.product_id == self.product_id  and x.state != 'cancel' and not x.location_dest_id.usage == "supplier"):
        #         _logger.info('-------move1.product_uom_qty=************ = %s',move.product_uom_qty)
        #         qty += move.product_uom._compute_quantity(move.product_uom_qty, self.product_uom, rounding_method='HALF-UP')
        #         _logger.info('-------qty=************ = %s',qty)
        # _logger.info('--@@-----TOTAl qty=************ = %s',qty)
        
        
        template = {
            'name': self.name or '',
            'product_id': self.product_id.id,
            'product_uom': self.product_uom.id,
            'date': self.order_id.date_order,
            # 'date_expected': self.date_planned,
            'location_id': self.order_id.partner_id.property_stock_supplier.id,
            'location_dest_id': self.order_id._get_destination_location(),
            'picking_id': picking.id,
            'partner_id': self.order_id.dest_address_id.id,
            'move_dest_ids': [(4, x) for x in self.move_dest_ids.ids],
            'state': 'draft',
            'purchase_line_id': self.id,
            'company_id': self.order_id.company_id.id,
            'price_unit': price_unit,
            'picking_type_id': self.order_id.picking_type_id.id,
            'group_id': self.order_id.group_id.id,
            'origin': self.order_id.name,
            'route_ids': self.order_id.picking_type_id.warehouse_id and [(6, 0, [x.id for x in self.order_id.picking_type_id.warehouse_id.route_ids])] or [],
            'warehouse_id': self.order_id.picking_type_id.warehouse_id.id,
        }
        diff_quantity = self.product_qty - qty
        _logger.info('-------diff_quantity=************ = %s',diff_quantity)
        _logger.info('-------self.product_qty =************ = %s',self.product_qty )
        if float_compare(diff_quantity, 0.0,  precision_rounding=self.product_uom.rounding) > 0:
            _logger.info('--@@@@@@@@@@@** = %s',diff_quantity)
            quant_uom = self.product_id.uom_id
            get_param = self.env['ir.config_parameter'].sudo().get_param
            if self.product_uom.id != quant_uom.id and get_param('stock.propagate_uom') != '1':
                _logger.info('##if')
                product_qty = self.product_uom._compute_quantity(diff_quantity, quant_uom, rounding_method='HALF-UP')
                template['product_uom'] = quant_uom.id
                template['product_uom_qty'] = product_qty
            else:
                _logger.info('$$else')
                # template['product_qty'] = diff_quantity
                template['product_uom_qty'] = diff_quantity
            _logger.info('@@-------template=************ = %s',template)
            res.append(template)
        return res

    @api.multi
    def _create_stock_moves(self, picking):
        moves = self.env['stock.move']
        done = self.env['stock.move'].browse()
        for line in self:
            for val in line._prepare_stock_moves(picking):
                done += moves.create(val)
        return done

    @api.multi
    def unlink(self):
        for line in self:
            if line.order_id.state in ['purchase', 'done']:
                raise UserError(_('Cannot delete a purchase order line which is in state \'%s\'.') %(line.state,))
        return super(PurchaseOrderLine, self).unlink()

    @api.model
    def _get_date_planned(self, seller, po=False):
        """Return the datetime value to use as Schedule Date (``date_planned``) for
           PO Lines that correspond to the given product.seller_ids,
           when ordered at `date_order_str`.

           :param Model seller: used to fetch the delivery delay (if no seller
                                is provided, the delay is 0)
           :param Model po: purchase.order, necessary only if the PO line is 
                            not yet attached to a PO.
           :rtype: datetime
           :return: desired Schedule Date for the PO line
        """
        date_order = po.date_order if po else self.order_id.date_order
        if date_order:
            return datetime.strptime(date_order, DEFAULT_SERVER_DATETIME_FORMAT) + relativedelta(days=seller.delay if seller else 0)
        else:
            return datetime.today() + relativedelta(days=seller.delay if seller else 0)

    def _merge_in_existing_line(self, product_id, product_qty, product_uom, location_id, name, origin, values):
        """ This function purpose is to be override with the purpose to forbide _run_buy  method
        to merge a new po line in an existing one.
        """
        return True
    
    # @api.onchange('price_subtotal')
    # def onchange_price_subtotal(self):
    
    # @api.onchange('price_subtotal')
    # def onchange_price_subtotal(self):
    #     _logger.info('-------onchange of price subtotal=************ = ')
    #     if values.get('remaning_budget_price') < values.get('price_subtotal'):
    #         raise UserError('You cannot make RFQ for this purchase request.\n'
    #                                 'Make buget adjustment first.')
        
    @api.onchange('product_id')
    def onchange_product_id(self):
        result = {}
        if not self.product_id:
            return result

        # Reset date, price and quantity since _onchange_quantity will provide default values
        self.date_planned = datetime.today().strftime(DEFAULT_SERVER_DATETIME_FORMAT)
        self.price_unit = self.product_qty = 0.0
        self.product_uom = self.product_id.uom_po_id or self.product_id.uom_id
        result['domain'] = {'product_uom': [('category_id', '=', self.product_id.uom_id.category_id.id)]}

        product_lang = self.product_id.with_context(
            lang=self.partner_id.lang,
            partner_id=self.partner_id.id,
        )
        self.name = product_lang.display_name
        if product_lang.description_purchase:
            self.name += '\n' + product_lang.description_purchase

        fpos = self.order_id.fiscal_position_id
        if self.env.uid == SUPERUSER_ID:
            company_id = self.env.user.company_id.id
            self.taxes_id = fpos.map_tax(self.product_id.supplier_taxes_id.filtered(lambda r: r.company_id.id == company_id))
        else:
            self.taxes_id = fpos.map_tax(self.product_id.supplier_taxes_id)

        self._suggest_quantity()
        self._onchange_quantity()

        return result

    @api.onchange('product_id')
    def onchange_product_id_warning(self):
        if not self.product_id:
            return
        warning = {}
        title = False
        message = False

        product_info = self.product_id

        if product_info.purchase_line_warn != 'no-message':
            title = _("Warning for %s") % product_info.name
            message = product_info.purchase_line_warn_msg
            warning['title'] = title
            warning['message'] = message
            if product_info.purchase_line_warn == 'block':
                self.product_id = False
            return {'warning': warning}
        return {}

    @api.onchange('product_qty', 'product_uom')
    def _onchange_quantity(self):
        if not self.product_id:
            return

        seller = self.product_id._select_seller(
            partner_id=self.partner_id,
            quantity=self.product_qty,
            date=self.order_id.date_order and self.order_id.date_order[:10],
            uom_id=self.product_uom)

        if seller or not self.date_planned:
            self.date_planned = self._get_date_planned(seller).strftime(DEFAULT_SERVER_DATETIME_FORMAT)

        if not seller:
            return

        price_unit = self.env['account.tax']._fix_tax_included_price_company(seller.price, self.product_id.supplier_taxes_id, self.taxes_id, self.company_id) if seller else 0.0
        if price_unit and seller and self.order_id.currency_id and seller.currency_id != self.order_id.currency_id:
            price_unit = seller.currency_id.compute(price_unit, self.order_id.currency_id)

        if seller and self.product_uom and seller.product_uom != self.product_uom:
            price_unit = seller.product_uom._compute_price(price_unit, self.product_uom)

        self.price_unit = price_unit

    def _suggest_quantity(self):
        '''
        Suggest a minimal quantity based on the seller
        '''
        if not self.product_id:
            return

        seller_min_qty = self.product_id.seller_ids\
            .filtered(lambda r: r.name == self.order_id.partner_id)\
            .sorted(key=lambda r: r.min_qty)
        if seller_min_qty:
            self.product_qty = seller_min_qty[0].min_qty or 1.0
            self.product_uom = seller_min_qty[0].product_uom
        else:
            self.product_qty = 1.0


class ProcurementGroup(models.Model):
    _inherit = 'procurement.group'

    @api.model
    def _get_exceptions_domain(self):
        return super(ProcurementGroup, self)._get_exceptions_domain() + [('created_purchase_line_id', '=', False)]


class ProcurementRule(models.Model):
    _inherit = 'procurement.rule'
    action = fields.Selection(selection_add=[('buy', 'Buy')])

    @api.multi
    def _run_buy(self, product_id, product_qty, product_uom, location_id, name, origin, values):
        cache = {}
        suppliers = product_id.seller_ids\
            .filtered(lambda r: (not r.company_id or r.company_id == values['company_id']) and (not r.product_id or r.product_id == product_id))
        if not suppliers:
            msg = _('There is no vendor associated to the product %s. Please define a vendor for this product.') % (product_id.display_name,)
            raise UserError(msg)

        supplier = self._make_po_select_supplier(values, suppliers)
        partner = supplier.name

        domain = self._make_po_get_domain(values, partner)

        if domain in cache:
            po = cache[domain]
        else:
            po = self.env['purchase.order'].search([dom for dom in domain])
            po = po[0] if po else False
            cache[domain] = po
        if not po:
            vals = self._prepare_purchase_order(product_id, product_qty, product_uom, origin, values, partner)
            po = self.env['purchase.order'].create(vals)
            cache[domain] = po
        elif not po.origin or origin not in po.origin.split(', '):
            if po.origin:
                if origin:
                    po.write({'origin': po.origin + ', ' + origin})
                else:
                    po.write({'origin': po.origin})
            else:
                po.write({'origin': origin})

        # Create Line
        po_line = False
        for line in po.order_line:
            if line.product_id == product_id and line.product_uom == product_id.uom_po_id:
                if line._merge_in_existing_line(product_id, product_qty, product_uom, location_id, name, origin, values):
                    vals = self._update_purchase_order_line(product_id, product_qty, product_uom, values, line, partner)
                    po_line = line.write(vals)
                    break
        if not po_line:
            vals = self._prepare_purchase_order_line(product_id, product_qty, product_uom, values, po, supplier)
            self.env['purchase.order.line'].create(vals)

    def _get_purchase_schedule_date(self, values):
        """Return the datetime value to use as Schedule Date (``date_planned``) for the
           Purchase Order Lines created to satisfy the given procurement. """
        procurement_date_planned = fields.Datetime.from_string(values['date_planned'])
        schedule_date = (procurement_date_planned - relativedelta(days=values['company_id'].po_lead))
        return schedule_date

    def _get_purchase_order_date(self, product_id, product_qty, product_uom, values, partner, schedule_date):
        """Return the datetime value to use as Order Date (``date_order``) for the
           Purchase Order created to satisfy the given procurement. """
        seller = product_id._select_seller(
            partner_id=partner,
            quantity=product_qty,
            date=fields.Date.to_string(schedule_date),
            uom_id=product_uom)

        return schedule_date - relativedelta(days=int(seller.delay))

    def _update_purchase_order_line(self, product_id, product_qty, product_uom, values, line, partner):
        procurement_uom_po_qty = product_uom._compute_quantity(product_qty, product_id.uom_po_id)
        seller = product_id._select_seller(
            partner_id=partner,
            quantity=line.product_qty + procurement_uom_po_qty,
            date=line.order_id.date_order and line.order_id.date_order[:10],
            uom_id=product_id.uom_po_id)

        price_unit = self.env['account.tax']._fix_tax_included_price_company(seller.price, line.product_id.supplier_taxes_id, line.taxes_id, values['company_id']) if seller else 0.0
        if price_unit and seller and line.order_id.currency_id and seller.currency_id != line.order_id.currency_id:
            price_unit = seller.currency_id.compute(price_unit, line.order_id.currency_id)

        return {
            'product_qty': line.product_qty + procurement_uom_po_qty,
            'price_unit': price_unit,
            'move_dest_ids': [(4, x.id) for x in values.get('move_dest_ids', [])]
        }

    @api.multi
    def _prepare_purchase_order_line(self, product_id, product_qty, product_uom, values, po, supplier):
        procurement_uom_po_qty = product_uom._compute_quantity(product_qty, product_id.uom_po_id)
        seller = product_id._select_seller(
            partner_id=supplier.name,
            quantity=procurement_uom_po_qty,
            date=po.date_order and po.date_order[:10],
            uom_id=product_id.uom_po_id)

        taxes = product_id.supplier_taxes_id
        fpos = po.fiscal_position_id
        taxes_id = fpos.map_tax(taxes) if fpos else taxes
        if taxes_id:
            taxes_id = taxes_id.filtered(lambda x: x.company_id.id == values['company_id'].id)

        price_unit = self.env['account.tax']._fix_tax_included_price_company(seller.price, product_id.supplier_taxes_id, taxes_id, values['company_id']) if seller else 0.0
        if price_unit and seller and po.currency_id and seller.currency_id != po.currency_id:
            price_unit = seller.currency_id.compute(price_unit, po.currency_id)

        product_lang = product_id.with_context({
            'lang': supplier.name.lang,
            'partner_id': supplier.name.id,
        })
        name = product_lang.display_name
        if product_lang.description_purchase:
            name += '\n' + product_lang.description_purchase

        date_planned = self.env['purchase.order.line']._get_date_planned(seller, po=po).strftime(DEFAULT_SERVER_DATETIME_FORMAT)

        return {
            'name': name,
            'product_qty': procurement_uom_po_qty,
            'product_id': product_id.id,
            'product_uom': product_id.uom_po_id.id,
            'price_unit': price_unit,
            'date_planned': date_planned,
            'orderpoint_id': values.get('orderpoint_id', False) and values.get('orderpoint_id').id,
            'taxes_id': [(6, 0, taxes_id.ids)],
            'order_id': po.id,
            'move_dest_ids': [(4, x.id) for x in values.get('move_dest_ids', [])],
        }

    def _prepare_purchase_order(self, product_id, product_qty, product_uom, origin, values, partner):
        schedule_date = self._get_purchase_schedule_date(values)
        purchase_date = self._get_purchase_order_date(product_id, product_qty, product_uom, values, partner, schedule_date)
        fpos = self.env['account.fiscal.position'].with_context(company_id=values['company_id'].id).get_fiscal_position(partner.id)

        gpo = self.group_propagation_option
        group = (gpo == 'fixed' and self.group_id.id) or \
                (gpo == 'propagate' and values['group_id'].id) or False

        return {
            'partner_id': partner.id,
            'picking_type_id': self.picking_type_id.id,
            'company_id': values['company_id'].id,
            'currency_id': partner.property_purchase_currency_id.id or self.env.user.company_id.currency_id.id,
            'dest_address_id': values.get('partner_dest_id', False) and values['partner_dest_id'].id,
            'origin': origin,
            'payment_term_id': partner.property_supplier_payment_term_id.id,
            'date_order': purchase_date.strftime(DEFAULT_SERVER_DATETIME_FORMAT),
            'fiscal_position_id': fpos,
            'group_id': group
        }

    def _make_po_select_supplier(self, values, suppliers):
        """ Method intended to be overridden by customized modules to implement any logic in the
            selection of supplier.
        """
        return suppliers[0]

    def _make_po_get_domain(self, values, partner):
        domain = super(ProcurementRule, self)._make_po_get_domain(values, partner)
        gpo = self.group_propagation_option
        group = (gpo == 'fixed' and self.group_id) or \
                (gpo == 'propagate' and values['group_id']) or False

        domain += (
            ('partner_id', '=', partner.id),
            ('state', '=', 'draft'),
            ('picking_type_id', '=', self.picking_type_id.id),
            ('company_id', '=', values['company_id'].id),
            )
        if group:
            domain += (('group_id', '=', group.id),)
        return domain


class ProductTemplate(models.Model):
    _name = 'product.template'
    _inherit = 'product.template'

    @api.model
    def _get_buy_route(self):
        buy_route = self.env.ref('purchase.route_warehouse0_buy', raise_if_not_found=False)
        if buy_route:
            return buy_route.ids
        return []

    @api.multi
    def _purchase_count(self):
        for template in self:
            template.purchase_count = sum([p.purchase_count for p in template.product_variant_ids])
        return True

    property_account_creditor_price_difference = fields.Many2one(
        'account.account', string="Price Difference Account", company_dependent=True,
        help="This account will be used to value price difference between purchase price and cost price.")
    purchase_count = fields.Integer(compute='_purchase_count', string='# Purchases')
    purchase_method = fields.Selection([
        ('purchase', 'On ordered quantities'),
        ('receive', 'On received quantities'),
        ], string="Control Policy",
        help="On ordered quantities: control bills based on ordered quantities.\n"
        "On received quantities: control bills based on received quantity.", default="receive")
    route_ids = fields.Many2many(default=lambda self: self._get_buy_route())
    purchase_line_warn = fields.Selection(WARNING_MESSAGE, 'Purchase Order Line', help=WARNING_HELP, default="no-message")
    purchase_line_warn_msg = fields.Text('Message for Purchase Order Line')


class ProductProduct(models.Model):
    _name = 'product.product'
    _inherit = 'product.product'

    @api.multi
    def _purchase_count(self):
        domain = [
            ('state', 'in', ['purchase', 'done']),
            ('product_id', 'in', self.mapped('id')),
        ]
        PurchaseOrderLines = self.env['purchase.order.line'].search(domain)
        for product in self:
            product.purchase_count = len(PurchaseOrderLines.filtered(lambda r: r.product_id == product).mapped('order_id'))

    purchase_count = fields.Integer(compute='_purchase_count', string='# Purchases')


class ProductCategory(models.Model):
    _inherit = "product.category"

    property_account_creditor_price_difference_categ = fields.Many2one(
        'account.account', string="Price Difference Account",
        company_dependent=True,
        help="This account will be used to value price difference between purchase price and accounting cost.")



class ProductProduct(models.Model):
    _name = 'company.branch'

    name = fields.Text(string='Description', required=True)
class MailComposeMessage(models.TransientModel):
    _inherit = 'mail.compose.message'

    @api.multi
    def mail_purchase_order_on_send(self):
        if not self.filtered('subtype_id.internal'):
            order = self.env['purchase.order'].browse(self._context['default_res_id'])
            if order.state == 'draft':
                order.state = 'sent'

    @api.multi
    def send_mail(self, auto_commit=False):
        if self._context.get('default_model') == 'purchase.order' and self._context.get('default_res_id'):
            self.mail_purchase_order_on_send()
        return super(MailComposeMessage, self.with_context(mail_post_autofollow=True)).send_mail(auto_commit=auto_commit)

