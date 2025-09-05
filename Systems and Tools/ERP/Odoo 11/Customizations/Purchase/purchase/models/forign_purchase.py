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
class ForignPurchaseRequest(models.Model):
    _name = "forign.purchase.request"
    _description = "Forign Purchase Request"
    READONLY_STATES = {
        'purchase': [('readonly', True)],
        'done': [('readonly', True)],
        'cancel': [('readonly', True)],
    }

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
    order_line = fields.One2many('forign.purchase.order.line1', 'request_id', string='Order Lines', states={'cancel': [('readonly', True)], 'done': [('readonly', True)]}, copy=True)
    partner_id = fields.Many2one('res.partner', string='Vendor',
      states=READONLY_STATES, change_default=True, track_visibility='always')
    category = fields.Many2one('purchase.request.category', string='Category')
    category_type = fields.Boolean("Is Production",related='category.is_production')
    
    approve_uid  = fields.Many2one('res.users', 'Approved By')
    
    @api.multi
    def submit_request(self):
        return {
                    'name':'Confirm',
                    'view_type':'form',
                    'view_mode':'form',
                    'res_model':'forign.purchase.reqest.confirm.submit',
                    'type':'ir.actions.act_window',
                    'target':'new',
                }
        # for order in self:
        #     if order.state  == 'draft':
        #         order.write({'state': 'PRsent'})
        # return True
    @api.multi
    def approve_request(self):
        for order in self:
            user_id=self.env['res.users'].search([('id', '=', self.env.uid)], limit=1).id
            if order.state  == 'PRsent':
                order.write({'state': 'PR Approved','approve_uid':user_id})
        return True
    @api.multi
    def cancel_request(self):
        for order in self:
            if order.state  == 'PRsent':
                order.write({'state': 'cancel'})
        return True
class purchase_request_confirm_submit(models.Model):
    _name = 'forign.purchase.reqest.confirm.submit'
    @api.multi
    def yes(self, context):
        terms=[]
        id=context.get('active_id')
        clause_final = ['&',('request_id', '=',id),('state','=','draft')]
        search_results= self.env['forign.purchase.order.line1'].search(clause_final).ids
        if search_results:
            _logger.info('-------search_results************ = %s',search_results)
            # _logger.info('-------term--------- = %s',terms)
            # terms=self.env['purchase.order.line'].browse(search_results)
            for search_result2 in self.env['forign.purchase.order.line1'].browse(search_results):
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
            search_results= self.env['forign.purchase.request'].search(clause_final).ids
            
            if search_results:
                for search_result in self.env['forign.purchase.request'].browse(search_results):
                    
                    _logger.error("!before update loop----------- vals=%s",search_result)     
                    search_result.write({'state': 'PRsent'})

            
            return {'type': 'ir.actions.act_window_close','tag': 'reload',}
    @api.multi
    def no(self):
        pass 
class ForignPurchaseOrderLine1(models.Model):
    _name = 'forign.purchase.order.line1'
    department = fields.Many2one('hr.department', string='Department', required=True)
    product_qty = fields.Float(string='Quantity', 
    digits=dp.get_precision('Product Unit of Measure'), required=True)
    
    remaning_budget_qty=fields.Float(string='Remaning Budget Quantity')
    name = fields.Text(string='Description', required=True)
    product_id = fields.Many2one('product.product', string='Product', 
    domain=[('purchase_ok', '=', True)], change_default=True, required=True)
    request_id = fields.Many2one('forign.purchase.request', string='Order Reference', 
    index=True, ondelete='cascade')
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
    @api.onchange('department')
    def onchange_department(self):
        self.onchange_product_id()
    
    @api.onchange('product_qty')
    def onchange_product_qty(self):
        _logger.error("!!!!!!!!----------- vals product_id id= =%s",self.product_id)
        _logger.error("!!!!!!!!----------- vals product_qty id= =%s",self.product_qty)
        # clause_final = [('product_id', '=', self.product_id.id)]
        # search_results= self.env['purchase.budget.items'].search(clause_final).ids
        
        # if search_results:
        #     for search_result in self.env['purchase.budget.items'].browse(search_results):
                
        #         _logger.error("!!!!!!!!----------- vals search_result.product_qty id= =%s",search_result.product_qty)
        #         if search_result.product_qty < self.product_qty:
        #             raise UserError(_("item quantity is exceed more than budget quantity."))
        if self.department and self.product_id:
            self.remaning_budget_qty=0
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
                    self.product_qty=0
                    raise UserError(_('Please make budget adjustment before request this product')) 
    @api.onchange('product_qty')
    def onchange_product_qty(self):
        if self.product_qty >1:
            if self.product_qty > self.remaning_budget_qty:
                raise UserError(_('!!Please make budget adjustment before request this product')) 
    
    @api.model
    def create(self, vals):
        _logger.error("!!!!!!!!----------- vals= =%s",vals)
        _logger.error("!!!!!!!!----------- vals product_qty= =%s",vals.get('product_qty'))
        _logger.error("!!!!!!!!----------- vals remaning_budget_qty = =%s",vals.get('remaning_budget_qty'))
            
        request_id_val=0
        if vals.get('remaning_budget_qty'):
            request_id_val=0
            if vals.get('product_qty') > vals.get('remaning_budget_qty'):
                raise UserError(_('Please make budget adjustment before request this product')) 
            else:
                val1=vals.get('request_id')
                _logger.error("!!!!!!!!----------- vals request id= =%s",vals.get('request_id'))
                for search_result3 in self.env['forign.purchase.request'].browse(val1):
                    request_id_val=search_result3.id
                        
                clause_final = [('id', '=', request_id_val)]
                search_results= self.env['forign.purchase.request'].search(clause_final).ids
                
                if search_results:
                    for search_result in self.env['forign.purchase.request'].browse(search_results):
                        
                        _logger.error("!before update loop----------- vals=%s",search_result)     
                        search_result.write({'state': 'item_filled'})
                return super(ForignPurchaseOrderLine1, self).create(vals)
        else:
            raise UserError(_('Please make budget adjustment before request this product')) 

    @api.onchange('product_id')
    def onchange_product_id(self):
        if self.department and self.product_id:
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
    @api.multi
    def write(self, vals):
        if vals.get('product_qty'):
            if vals.get('product_qty') > self.remaning_budget_qty:
                    raise UserError(_('Please make budget adjustment before request this product')) 
            else:
                return super(ForignPurchaseOrderLine1, self).write(vals)
        else:
            return super(ForignPurchaseOrderLine1, self).write(vals)

class ForignPurchaseOrder(models.Model):
    _name = "forign.purchase.order"
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
        # type_obj = self.env['stock.picking.type']
        # company_id = self.env.context.get('company_id') or self.env.user.company_id.id
        # types = type_obj.search([('code', '=', 'incoming'), ('warehouse_id.company_id', '=', company_id)])
        # if not types:
        #     types = type_obj.search([('code', '=', 'incoming'), ('warehouse_id', '=', False)])
        # return types[:1]
        type_obj = self.env['stock.picking.type']
        company_id = self.env.context.get('company_id') or self.env.user.company_id.id
        types = type_obj.search([('is_foreign', '=', True), ('warehouse_id.company_id', '=', company_id)])
        if not types:
            types = type_obj.search([('is_foreign', '=', True), ('warehouse_id', '=', False)])
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
        
        search_result_request= self.env['forign.purchase.request'].search([]).ids
        if search_result_request:
            _logger.info('-------search_results************ = %s',search_result_request)
            # _logger.info('-------term--------- = %s',terms)
            # terms=self.env['purchase.order.line'].browse(search_results)
            for search_result_request_detail in self.env['forign.purchase.request'].browse(search_result_request):
                _logger.info('-------search_result_request_detail************ = %s',search_result_request_detail)
                terms = []
                request_id=''
                request_id=search_result_request_detail.id
                clause_final1 = ['&',('request_id', '=',search_result_request_detail.id),('state','=','draft')]
                search_results= self.env['forign.purchase.order.line1'].search(clause_final1).ids
                if search_results:
                    _logger.info('-------search_results************ = %s',search_results)
                    # _logger.info('-------term--------- = %s',terms)
                    # terms=self.env['purchase.order.line'].browse(search_results)
                    for search_result2 in self.env['forign.purchase.order.line1'].browse(search_results):
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
                    search_results= self.env['forign.purchase.request'].search(clause_final).ids
                    if search_results:
                        _logger.info('-------search_results************ = %s',search_results)
                        # _logger.info('-------term--------- = %s',terms)
                        # terms=self.env['purchase.order.line'].browse(search_results)
                        for search_result2 in self.env['forign.purchase.request'].browse(search_results):
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
    @api.onchange('purchase_request')
    def onchange_purchase_request(self):
        _logger.info("++++++++++++++++++++++++++");
        _logger.info(self.purchase_request)
        terms_obj = self.purchase_request
        terms = []
        request_id=''
        if terms_obj:
            for search_result in terms_obj:
                _logger.info('!!!------------------ search_result = %s',search_result)
                _logger.info('!!!------------------ search_result = %s',search_result.id)
                request_id=search_result.id
                clause_final = ['&',('request_id', '=',search_result.id),('state','=','draft')]
                _logger.info('!!!------------------ clause_final = %s',clause_final)
                search_results= self.env['forign.purchase.order.line1'].search(clause_final).ids
                if search_results:
                    _logger.info('-------search_results************ = %s',search_results)
                    # _logger.info('-------term--------- = %s',terms)
                    # terms=self.env['purchase.order.line'].browse(search_results)
                    for search_result2 in self.env['forign.purchase.order.line1'].browse(search_results):
                        _logger.info('-------search_result2************ = %s',search_result2)
                        product_templet_id=search_result2.product_id.product_tmpl_id.id
                    # _logger.info('-------terms************ = %s',terms)
                        # search_result2.write({'state': 'RFQ')
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
                            values['product_qty'] = rec.product_qty
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
    purchase_request = fields.Many2one('forign.purchase.request',required=True,
    string='Purchase request')
    name = fields.Char('Order Reference', required=True, index=True, copy=False, default='New')
    # id = fields.Char('Order Reference')
    origin = fields.Char('Source Document', copy=False,\
        help="Reference of the document that generated this purchase order "
             "request (e.g. a sales order)")
    partner_ref = fields.Char('Vendor Reference (PI)',required=True, copy=False,\
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
    order_line = fields.One2many('forign.purchase.order.line', 'order_id', 
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

    picking_type_id = fields.Many2one('stock.picking.type', 'Deliver To', 
    states=READONLY_STATES, default=_default_picking_type,\
        help="This will determine operation type of incoming shipment")
    default_location_dest_id_usage = fields.Selection(related='picking_type_id.default_location_dest_id.usage', string='Destination Location Type',\
        help="Technical field used to display the Drop Ship Address", readonly=True)
    group_id = fields.Many2one('procurement.group', string="Procurement Group", copy=False)
    is_shipped = fields.Boolean(compute="_compute_is_shipped")

    website_url = fields.Char(
        'Website URL', compute='_website_url',
        help='The full URL to access the document through the website.')

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
            vals['name'] = self.env['ir.sequence'].next_by_code('forign.purchase.order') or '/'
        return super(ForignPurchaseOrder, self).create(vals)

    @api.multi
    def unlink(self):
        for order in self:
            if not order.state == 'cancel':
                raise UserError(_('In order to delete a purchase order, you must cancel it first.'))
        return super(ForignPurchaseOrder, self).unlink()

    @api.multi
    def copy(self, default=None):
        new_po = super(ForignPurchaseOrder, self).copy(default=default)
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
        return super(ForignPurchaseOrder, self)._track_subtype(init_values)

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
        return self.env.ref('purchase.forign_report_purchase_quotation').report_action(self)

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
                    'res_model':'forign.purchase.order.confirm.approve',
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
        if not self.group_id:
            self.group_id = self.group_id.create({
                'name': self.name,
                'partner_id': self.partner_id.id
            })
        if not self.partner_id.property_stock_supplier.id:
            raise UserError(_("You must set a Vendor Location for this partner %s") % self.partner_id.name)
        return {
            'picking_type_id': self.picking_type_id.id,
            'partner_id': self.partner_id.id,
            'date': self.date_order,
            'origin': self.name,
            'state': 'assigned',
            'location_dest_id': self._get_destination_location(),
            'location_id': self.partner_id.property_stock_supplier.id,
            'company_id': self.company_id.id,
        }

    @api.multi
    def _create_picking(self):
        _logger.info("#######++++++ create picking")
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
        _logger.info("#######++++++  end creating pick")
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
class forign_purchase_order_confirm_approve(models.Model):
    _name = 'forign.purchase.order.confirm.approve'
    @api.multi
    def yes(self, context):
        id=context.get('active_id')
        clause_final = [('id', '=', id)]
        search_results= self.env['forign.purchase.order'].search(clause_final).ids
        
        if search_results:
            for search_result in self.env['forign.purchase.order'].browse(search_results):
                _logger.info("++-------------------update state ")
                _logger.info(search_result)
                _logger.info("++-------------------update state ")
                _logger.info(search_result.state)
                user_id=self.env['res.users'].search([('id', '=', self.env.uid)], limit=1).id
    
                search_result.write({'state': 'purchase','approve_uid':user_id})
                
                _logger.info("-------------------update state ")
                # search_result._create_picking()
            return {'type': 'ir.actions.act_window_close','tag': 'reload',}
    @api.multi
    def no(self):
        pass 
   
class ForignPurchaseOrderLine(models.Model):
    _name = 'forign.purchase.order.line'
    _description = 'Forign Purchase Order Line'
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
        _logger.info(self.product_id)
        _logger.info("#######++++++")
        line = super(ForignPurchaseOrderLine, self).create(values)

        _logger.info("#######++++++ product id")
        _logger.info(line.product_id.id)
        _logger.info("#######++++++ request")
        _logger.info(line.purchase_request.id)
        clause_final = ['&',('product_id', '=',line.product_id.id),('request_id','=',line.purchase_request.id)]
        search_results= self.env['forign.purchase.order.line1'].search(clause_final).ids
        if search_results:
            _logger.info('-------search_results************ = %s',search_results)
            # _logger.info('-------term--------- = %s',terms)
            # terms=self.env['purchase.order.line'].browse(search_results)
            for search_result2 in self.env['forign.purchase.order.line1'].browse(search_results):
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
        result = super(ForignPurchaseOrderLine, self).write(values)
        # Update expected date of corresponding moves
        if 'date_planned' in values:
            self.env['stock.move'].search([
                ('purchase_line_id', 'in', self.ids), ('state', '!=', 'done')
            ]).write({'date_expected': values['date_planned']})
        if 'product_qty' in values:
            self.filtered(lambda l: l.order_id.state == 'purchase')._create_or_update_picking()
        return result

    name = fields.Text(string='Description', required=True)
    sequence = fields.Integer(string='Sequence', default=10)
    product_qty = fields.Float(string='Quantity', 
    digits=dp.get_precision('Product Unit of Measure'))
    date_planned = fields.Datetime(string='Scheduled Date', index=True)
    taxes_id = fields.Many2many('account.tax', string='Taxes', domain=['|', ('active', '=', False), ('active', '=', True)])
    product_uom = fields.Many2one('product.uom', string='Product Unit of Measure')
    product_id = fields.Many2one('product.product', string='Product', 
    domain=[('purchase_ok', '=', True)], change_default=True, required=True)
    product_image = fields.Binary(
        'Product Image', related="product_id.image",
        help="Non-stored related field to allow portal user to see the image of the product he has ordered")
    move_ids = fields.One2many('stock.move', 'purchase_line_id', string='Reservation', readonly=True, ondelete='set null', copy=False)
    price_unit = fields.Float(string='Unit Price',required=True,  digits=dp.get_precision('Product Price'))

    price_subtotal = fields.Monetary(compute='_compute_amount', string='Subtotal', store=True)
    price_total = fields.Monetary(compute='_compute_amount', string='Total', store=True)
    price_tax = fields.Float(compute='_compute_amount', string='Tax', store=True)
    # request_id = fields.Many2one('purchase.request', string='Order Reference', 
    # index=True, ondelete='cascade')
    order_id = fields.Many2one('forign.purchase.order', string='Order Reference', 
    index=True, ondelete='cascade')
    account_analytic_id = fields.Many2one('account.analytic.account', string='Analytic Account')
    analytic_tag_ids = fields.Many2many('account.analytic.tag', string='Analytic Tags')
    company_id = fields.Many2one('res.company', 
    related='order_id.company_id', string='Company', store=True, readonly=True)
    state = fields.Selection(related='order_id.state', store=True)
    purchase_request = fields.Many2one(related='order_id.purchase_request', store=True)
    
    invoice_lines = fields.One2many('account.invoice.line', 'purchase_line_id', string="Bill Lines", readonly=True, copy=False)

    # Replace by invoiced Qty
    # qty_invoiced = fields.Float(compute='_compute_qty_invoiced', string="Billed Qty", digits=dp.get_precision('Product Unit of Measure'), store=True)
    # qty_received = fields.Float(compute='_compute_qty_received', string="Received Qty", digits=dp.get_precision('Product Unit of Measure'), store=True)

    qty_invoiced = fields.Float( string="Billed Qty", digits=dp.get_precision('Product Unit of Measure'), store=True)
    qty_received = fields.Float( string="Received Qty", digits=dp.get_precision('Product Unit of Measure'), store=True)

    partner_id = fields.Many2one('res.partner', related='order_id.partner_id', 
    string='Partner', readonly=True, store=True)
    currency_id = fields.Many2one(related='order_id.currency_id',
     store=True, string='Currency', readonly=True)
    date_order = fields.Datetime(related='order_id.date_order', string='Order Date', readonly=True)

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
        res = []
        if self.product_id.type not in ['product', 'consu']:
            return res
        qty = 0.0
        price_unit = self._get_stock_move_price_unit()
        for move in self.move_ids.filtered(lambda x: x.state != 'cancel' and not x.location_dest_id.usage == "supplier"):
            qty += move.product_uom._compute_quantity(move.product_uom_qty, self.product_uom, rounding_method='HALF-UP')
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
        if float_compare(diff_quantity, 0.0,  precision_rounding=self.product_uom.rounding) > 0:
            quant_uom = self.product_id.uom_id
            get_param = self.env['ir.config_parameter'].sudo().get_param
            if self.product_uom.id != quant_uom.id and get_param('stock.propagate_uom') != '1':
                product_qty = self.product_uom._compute_quantity(diff_quantity, quant_uom, rounding_method='HALF-UP')
                template['product_uom'] = quant_uom.id
                template['product_uom_qty'] = product_qty
            else:
                template['product_uom_qty'] = diff_quantity
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
        return super(ForignPurchaseOrderLine, self).unlink()

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

class ShipmentDetail(models.Model):
    _name = "shipment.detail"

    shipment_no=fields.Char(string='Shipment Number', required=True)
    date=fields.Datetime(string='Scheduled Date', required=True)
    note=fields.Text(string='Note', required=True)
    # pi_no=fields.Char(string='PI Number', required=True)
    pi_no=fields.Many2one('forign.purchase.order', string='Purchase Order',
     required=True)
    state=fields.Char(string='State', default='shipment')
    lc_id = fields.Many2one('forign.purchase.lc', string='purchase reference',index=True, ondelete='cascade')
    order_line = fields.One2many('forign.purchase.lc.items', 'request_id', string='Order Lines', copy=True)
    partner_id = fields.Many2one('res.partner', string='Vendor', change_default=True, track_visibility='always')
    
    @api.onchange('pi_no')
    def onchange_pi_no(self):
        terms3=[]
        terms=[]
        terms2=[]
        terms4=[]
        terms5=[]
        _logger.info("self id===%s",self.pi_no)
        terms_obj = self.pi_no
        clause_final = [('order_id', '=',self.pi_no.id)]
        _logger.info('!!!------------------ clause_final = %s',clause_final)
        search_results= self.env['forign.purchase.order.line'].search(clause_final).ids
        if search_results:
            _logger.info('-------search_results************ = %s',search_results)
            # _logger.info('-------term--------- = %s',terms)
            # terms=self.env['purchase.order.line'].browse(search_results)
            for search_result2 in self.env['forign.purchase.order.line'].browse(search_results):
                _logger.info('!!!!!!!!!!!-------order.line************ = %s',search_result2)
                new_quantity=0
                found=False
                for rec in search_result2:
                    
                    values1 = {}

                    values1['name'] = rec.name
                    values1['product_id'] = rec.product_id
                    values1['price_unit'] =rec.price_unit 
                    values1['currency_id'] =rec.currency_id
                    values1['product_uom'] =rec.product_uom
                    values1['price_subtotal'] =rec.price_unit  * rec.product_qty
                    values1['product_qty'] =rec.product_qty
                    terms4.append((0, 0, values1))
                
        if terms_obj:
            for search_result in terms_obj:

                clause_final_ship = [('pi_no', '=',self.pi_no.id)]
                _logger.info('!!!------------------ clause_final = %s',clause_final_ship)
                search_results_ship= self.env['shipment.detail'].search(clause_final_ship)
                _logger.info('-------search_results_ship************ = %s',search_results_ship)
                if search_results_ship:
                    for search_result_ship in self.env['shipment.detail'].browse(search_results_ship):
                        
                        current_id=search_result_ship.id
                        _logger.info("++++++++++++++++++++++++++ current_id %s",current_id)
                        request_id=search_result.id
                        clause_final = [('order_id', '=',search_result.id)]
                        _logger.info('!!!------------------ clause_final = %s',clause_final)
                        search_results= self.env['forign.purchase.order.line'].search(clause_final).ids
                        if search_results:
                            _logger.info('-------search_results************ = %s',search_results)
                            # _logger.info('-------term--------- = %s',terms)
                            # terms=self.env['purchase.order.line'].browse(search_results)
                            for search_result2 in self.env['forign.purchase.order.line'].browse(search_results):
                                _logger.info('!!!!!!!!!!!-------order.line************ = %s',search_result2)
                                new_quantity=0
                                found=False
                                for rec in search_result2:
                                    
                                    clause_final = ['&',('request_id', '=', current_id.id),('product_id','=',rec.product_id.id)]
                                    _logger.info('!!!------------------ clause_final = %s',clause_final)
                                    search_results3= self.env['forign.purchase.lc.items'].search(clause_final).ids
                                    if search_results3:
                                        _logger.info('-------##  if search_results************ = %s',search_results3)
                                        # _logger.info('-------term--------- = %s',terms)
                                        # terms=self.env['purchase.order.line'].browse(search_results)
                                        # new_quantity=0
                                        for search_result3 in self.env['forign.purchase.lc.items'].browse(search_results3):
                                            _logger.info('-------search_result2************ = %s',search_result3.id)
                                            
                                            # exist_quntity=rec.product_qty - new_quantity
                                            # if exist_quntity !=0:
                                            values = {}

                                            values['name'] = rec.name
                                            values['product_id'] = rec.product_id
                                            values['product_id'] = rec.product_uom
                                            values['price_unit'] =rec.price_unit 
                                            values['currency_id'] =rec.currency_id
                                            values['product_uom'] =rec.product_uom
                                            values['price_subtotal'] =rec.price_unit  * search_result3.product_qty
                                            values['product_qty'] =search_result3.product_qty
                                            terms.append((0, 0, values))
                                            _logger.info('-------terms************ = %s',terms)
                else:
                    clause_final = [('order_id', '=',self.pi_no.id)]
                    _logger.info('!!!------------------ clause_final = %s',clause_final)
                    search_results= self.env['forign.purchase.order.line'].search(clause_final).ids
                    if search_results:
                        _logger.info('-------search_results************ = %s',search_results)
                        # _logger.info('-------term--------- = %s',terms)
                        # terms=self.env['purchase.order.line'].browse(search_results)
                        for search_result2 in self.env['forign.purchase.order.line'].browse(search_results):
                            _logger.info('!!!!!!!!!!!-------order.line************ = %s',search_result2)
                            new_quantity=0
                            found=False
                            for rec in search_result2:
                                
                                values = {}

                                values['name'] = rec.name
                                values['product_id'] = rec.product_id
                                values['price_unit'] =rec.price_unit 
                                values['currency_id'] =rec.currency_id
                                values['product_uom'] =rec.product_uom
                                values['price_subtotal'] =rec.price_unit  * rec.product_qty
                                values['product_qty'] =rec.product_qty
                                terms5.append((0, 0, values))
        if not terms5:
            _logger.info('-------terms************ = %s',terms)
            for rec in terms:
                _logger.info('$$$$-------rec************ = %s',rec)
                if terms2:
                    found=False
                    for rec2 in terms2:
                        _logger.info('-------rec2************ = %s',rec2)
                        _logger.info('-------rec2[2].product_id.id************ = %s',rec2[2]['product_id'])
                        _logger.info('-------rec[2].product_id.id************ = %s',rec[2]['product_id'].id)
                        _logger.info('-------rec2[2].product_id.id************ = %s',rec2[2]['product_id'].id)
                        # _logger.info('-------rec[2].product_id.id************ = %s',rec[2]['product_id.id'])
                        if rec2[2]['product_id'].id == rec[2]['product_id'].id:
                            found=True
                            new_QTY=rec[2]['product_qty'] + rec2[2]['product_qty']
                            rec2[2]['product_qty']= new_QTY 
                            _logger.info('-------new_QTY************ = %s',new_QTY)
                            # values = {}
                            # values['name'] = rec[2].name
                            # values['product_id'] = rec[2].product_id.id
                            # values['price_unit'] =rec[2].price_unit 
                            # values['currency_id'] =rec[2].currency_id
                            # values['product_qty'] = new_QTY
                            # values['price_subtotal'] =rec[2].price_unit  * new_QTY
                            # terms2.append((0, 0, values))
                    if found== False:
                        values = {}
                        _logger.info('-------rec[2]************ = %s',rec[2])
                        values['name'] = rec[2]['name']
                        _logger.info('-------rec[2] product_id************ = %s',rec[2]['product_id'])
                        values['product_id'] = rec[2]['product_id']
                        values['price_unit'] =rec[2]['price_unit']
                        values['currency_id'] =rec[2]['currency_id']
                        values['product_uom'] =rec[2]['product_uom']
                        values['product_qty'] = rec[2]['product_qty']
                        values['price_subtotal'] =rec[2]['price_unit']  * rec[2]['product_qty']
                        terms2.append((0, 0, values))
                else:
                    values = {}
                    _logger.info('-------rec[2]************ = %s',rec[2])
                    values['name'] = rec[2]['name']
                    _logger.info('-------rec[2] product_id************ = %s',rec[2]['product_id'])
                    values['product_id'] = rec[2]['product_id']
                    values['price_unit'] =rec[2]['price_unit']
                    values['product_uom'] =rec[2]['product_uom']
                    values['currency_id'] =rec[2]['currency_id']
                    values['product_qty'] = rec[2]['product_qty']
                    values['price_subtotal'] =rec[2]['price_unit']  * rec[2]['product_qty']
                    terms2.append((0, 0, values))
                _logger.info('@@@@-------terms2************ = %s',terms2)
            _logger.info('!!!!!!!!!!!-------terms2************ = %s',terms2)
            _logger.info('-------terms4************ = %s',terms4)

            for rec1 in terms4:
                # _logger.info('$$$$-------rec************ = %s',rec)
                found=False
                if terms4:
                    for rec2 in terms2:
                        if rec2[2]['product_id'].id == rec1[2]['product_id'].id:
                            found=True
                            # _logger.info('-------rec2************ = %s',rec2)
                            _logger.info('@@-------rec2[2].product_id.id************ = %s',rec2[2]['product_id'])
                            _logger.info('@@-------re1c[2].product_qty.id************ = %s',rec1[2]['product_qty'])
                            _logger.info('@@-------rec2[2].product_qty.id************ = %s',rec2[2]['product_qty'])
                            # _logger.info('-------rec2[2].product_qty.id************ = %s',rec2[2]['product_qty'])
                            # _logger.info('-------rec[2].product_id.id************ = %s',rec[2]['product_id.id'])

                            new_qunity= rec1[2]['product_qty'] - rec2[2]['product_qty']
                            # rec2[2]['product_qty']= new_qunity 
                            _logger.info('!!!!1-------new_qunity************ = %s',new_qunity)
                            if new_qunity >0:
                                values = {}
                                values['name'] = rec2[2]['name']
                                # _logger.info('-------rec[2] product_id************ = %s',rec[2]['product_id'])
                                values['product_id'] = rec2[2]['product_id']
                                values['price_unit'] =rec2[2]['price_unit']
                                values['currency_id'] =rec2[2]['currency_id']
                                values['product_uom'] =rec2[2]['product_uom']
                                values['product_qty'] =new_qunity
                                values['price_subtotal'] =rec2[2]['price_unit'] * new_qunity
                                terms5.append((0, 0, values))
                        _logger.info('-------found************ = %s',found)
                    _logger.info('-------found************ = %s',found)
                    if found ==False:
                        values = {}
                        values['name'] = rec1[2]['name']
                        # _logger.info('-------rec[2] product_id************ = %s',rec[2]['product_id'])
                        values['product_id'] = rec1[2]['product_id']
                        values['price_unit'] =rec1[2]['price_unit']
                        values['currency_id'] =rec1[2]['currency_id']
                        values['product_qty'] =rec1[2]['product_qty']
                        values['product_uom'] =rec1[2]['product_uom']
                        values['price_subtotal'] =rec1[2]['price_unit'] * rec1[2]['product_qty']
                        terms5.append((0, 0, values))
        _logger.info('!!!!1-------terms5************ = %s',terms5)
        # terms3=terms
        self.order_line=terms5
        return
        
class ForignPurchaseLC(models.Model):
    _name = "forign.purchase.lc"


    purchase_order = fields.Many2one('forign.purchase.order', string='Purchase Order',
     required=True)
    # bank_name = fields.Many2one('bank.detail', string='Bank Name', required=True)
    bank_name = fields.Many2one('account.journal', string='Bank Name') 
    pi = fields.Char(string='PI')
    lc_number = fields.Char(string='LC Number', required=True)
    lc_date = fields.Datetime('LC Date', index=True,required=True, default=fields.Datetime.now,)
   
    #  = fields.Char(string='Bank Name', required=True)
    lc_amount = fields.Char(string='LC Amount')
    state = fields.Char(string='State')
    shipment = fields.One2many('shipment.detail', 'lc_id', string='Shipment Detail',copy=True)
    
    @api.onchange('purchase_order')
    def onchange_purchase_order(self):
        
        self.pi=self.purchase_order.partner_ref
        self.lc_amount=self.purchase_order.amount_total
        
        return
        
    @api.model
    def create(self, vals):
        #_logger.info('-------self.pi************ = %s',self.purchase_order.partner_ref)
        _logger.info('-------self value************ = %s',self.purchase_order.id)
        _logger.info('-------pi value************ = %s',vals.get('purchase_order'))
        # vals['pi'] = self.purchase_order.partner_ref
        # vals['lc_amount'] = self.purchase_order.amount_total
        purchase_order_id=0
        if vals.get('purchase_order'):
            purchase_order_id=vals.get('purchase_order')
        else:
            purchase_order_id=self.purchase_order.id
         
        _logger.info('-------purchase_order_id************ = %s',purchase_order_id)
        clause_final = [('id', '=',purchase_order_id)]
        search_results= self.env['forign.purchase.order'].search(clause_final).ids
            
        if search_results:
            for search_result in self.env['forign.purchase.order'].browse(search_results):
                
                _logger.error("!before update loop----------- vals=%s",search_result)     
                search_result.write({'state': 'done'})
            vals['state'] ='done'
        res = super(ForignPurchaseLC, self).create(vals)
        return res

class ForignPurchaseLcItems1(models.Model):
    _name = 'forign.purchase.lc.items1'
    product_qty = fields.Float(string='Quantity', 
    digits=dp.get_precision('Product Unit of Measure'), required=True)
    product_id = fields.Many2one('product.product', string='Product', 
    domain=[('purchase_ok', '=', True)], change_default=True, required=True)
    price_unit = fields.Float(string='Unit Price')
    price_subtotal = fields.Monetary(string='Sub Total')
    product_uom = fields.Many2one('product.uom', string='Product Unit of Measure')
    currency_id = fields.Many2one('res.currency', 'Currency')
    name = fields.Text(string='Description', required=True)
    # amount = fields.Float(string='Amount')
    request_id = fields.Many2one('actual.costing', string='Order Reference', 
    index=True, ondelete='cascade')
    # state = fields.Selection([ 
        
    #     ('draft', 'Draft'),
    #     ('PR Approved', 'PR Approved'),
    #      ('RFQ', 'RFQ'),
    #     ('sent', 'RFQ Sent'),
    #     ('approved', 'RFQ Approved'),
    #     ('to approve', 'To Approve'),
    #     ('purchase', 'Purchase Order'),


    #     ('done', 'Locked'),
    #     ('cancel', 'Cancelled')], default='draft' ,store=True)
    partner_id = fields.Many2one('res.partner', related='request_id.partner_id',string='Partner', readonly=True, store=True)
    
    # @api.model
    # def create(self, vals):
    #     request_id_val=0
    #     val1=vals.get('request_id')
    #     _logger.error("!!!!!!!!----------- vals request id= =%s",vals.get('request_id'))
    #     for search_result3 in self.env['forign.purchase.request'].browse(val1):
    #         request_id_val=search_result3.id
                  
    #     clause_final = [('id', '=', request_id_val)]
    #     search_results= self.env['forign.purchase.request'].search(clause_final).ids
        
    #     if search_results:
    #         for search_result in self.env['forign.purchase.request'].browse(search_results):
                
    #             _logger.error("!before update loop----------- vals=%s",search_result)     
    #             search_result.write({'state': 'item_filled'})
    #     return super(ForignPurchaseLcItems, self).create(vals)
    @api.onchange('product_qty')
    def onchange_product_qty(self):
        self.price_subtotal = self.price_unit * self.product_qty
    @api.onchange('product_id')
    def onchange_product_id(self):
        product_lang = self.product_id.with_context(
            lang=self.partner_id.lang,
            partner_id=self.partner_id.id,
        )
        self.name = product_lang.display_name
        self._suggest_quantity()
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
class ForignPurchaseLcItems(models.Model):
    _name = 'forign.purchase.lc.items'
    product_qty = fields.Float(string='Quantity', 
    digits=dp.get_precision('Product Unit of Measure'), required=True)
    product_id = fields.Many2one('product.product', string='Product', 
    domain=[('purchase_ok', '=', True)], change_default=True, required=True)
    product_uom = fields.Many2one('product.uom', string='Product Unit of Measure')
    price_unit = fields.Float(string='Unit Price')
    price_subtotal = fields.Monetary(string='Sub Total')
    
    currency_id = fields.Many2one('res.currency', 'Currency')
    name = fields.Text(string='Description', required=True)
    # amount = fields.Float(string='Amount')
    request_id = fields.Many2one('shipment.detail', string='Order Reference', 
    index=True, ondelete='cascade')
    # state = fields.Selection([ 
        
    #     ('draft', 'Draft'),
    #     ('PR Approved', 'PR Approved'),
    #      ('RFQ', 'RFQ'),
    #     ('sent', 'RFQ Sent'),
    #     ('approved', 'RFQ Approved'),
    #     ('to approve', 'To Approve'),
    #     ('purchase', 'Purchase Order'),
    #     ('done', 'Locked'),
    #     ('cancel', 'Cancelled')], default='draft' ,store=True)
    partner_id = fields.Many2one('res.partner', related='request_id.partner_id',string='Partner', readonly=True, store=True)
    
    # @api.model
    # def create(self, vals):
    #     request_id_val=0
    #     val1=vals.get('request_id')
    #     _logger.error("!!!!!!!!----------- vals request id= =%s",vals.get('request_id'))
    #     for search_result3 in self.env['forign.purchase.request'].browse(val1):
    #         request_id_val=search_result3.id
                  
    #     clause_final = [('id', '=', request_id_val)]
    #     search_results= self.env['forign.purchase.request'].search(clause_final).ids
        
    #     if search_results:
    #         for search_result in self.env['forign.purchase.request'].browse(search_results):
                
    #             _logger.error("!before update loop----------- vals=%s",search_result)     
    #             search_result.write({'state': 'item_filled'})
    #     return super(ForignPurchaseLcItems, self).create(vals)
    @api.onchange('product_qty')
    def onchange_product_qty(self):
        self.price_subtotal = self.price_unit * self.product_qty
    @api.onchange('product_id')
    def onchange_product_id(self):
        product_lang = self.product_id.with_context(
            lang=self.partner_id.lang,
            partner_id=self.partner_id.id,
        )
        self.name = product_lang.display_name
        self._suggest_quantity()
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
      

class CostBuilUp1(models.Model):
    _name = 'cost.build.up1'
    
    source_document = fields.Char('Source Document' )
    reference = fields.Char('Reference')
    cost_category = fields.Many2one('cost.category',  string="Cost Category")
    amount = fields.Float('Amount')
    cost_id = fields.Char('cost Id')

    @api.model
    def create(self, vals):
        
        _logger.info('-------self.id----************ = %s',self.id)
        _logger.info('-------vals----************ = %s',vals)
        if vals.get('cost_id'):
            id=vals.get('cost_id')
        else:
            id=self.cost_id
        total_payment=0.0
        cost_search=[('cost_id', '=',id)]
        _logger.info('-------cost_search----************ = %s',cost_search)
        payments = self.env['cost.build.up1'].search(cost_search).ids
        for payment in self.env['cost.build.up1'].browse(payments):
            total_payment=total_payment + payment.amount 
            _logger.info('-------total_payment----************ = %s',total_payment)
        cost_search=[('id', '=',id)]
        payments = self.env['actual.costing'].search(cost_search).ids
        amount=0.0
        if vals.get('amount'):
            amount=vals.get('amount')
        total_payment=total_payment +  amount
        for actual_cost in self.env['actual.costing'].browse(payments):
            
            actual_cost.write({"total_cost":total_payment})  
      
        return super(CostBuilUp1, self).create(vals)
        
class LastYearPayment(models.Model):
    _name = 'last.year.payment'
    
    source_document = fields.Char('Source Document' )
    reference = fields.Char('Reference')
    amount = fields.Float('Amount')
    cost_id = fields.Many2one('actual.costing',index=True, ondelete='cascade')

    @api.model
    def create(self, vals):
         
        _logger.info('-------self.id----************ = %s',self.id)
        _logger.info('-------vals----************ = %s',vals)
        if vals.get('cost_id'):
            id=vals.get('cost_id')
        else:
            id=self.cost_id
        total_payment=0.0
        cost_search=[('cost_id', '=',id)]
        _logger.info('-------cost_search----************ = %s',cost_search)
        payments = self.env['cost.build.up1'].search(cost_search).ids
        for payment in self.env['cost.build.up1'].browse(payments):
            total_payment=total_payment + payment.amount 
            _logger.info('-------total_payment----************ = %s',total_payment)
        cost_search=[('id', '=',id)]
        payments = self.env['actual.costing'].search(cost_search).ids
        amount=0.0
        if vals.get('amount'):
            amount=vals.get('amount')
        total_payment=total_payment +  amount
        for actual_cost in self.env['actual.costing'].browse(payments):
            
            actual_cost.write({"total_cost":total_payment})  
      
        return super(LastYearPayment, self).create(vals)

    @api.model
    def unlink(self):
         
        _logger.info('-------unlink self.id----************ = %s',self.id)
        id=self.cost_id
        total_payment=0.0
        cost_search=[('id', '=',id.id)]
        payments = self.env['actual.costing'].search(cost_search).ids
        for payment in self.env['actual.costing'].browse(payments):
            _logger.info('-------payment---************ = %s',payment)
            total_payment=payment.total_cost -  self.amount
            _logger.info('-------total_payment----************ = %s',total_payment)
            payment.write({"total_cost":total_payment})  
      
        return super(LastYearPayment, self).unlink()
class ActualCosting(models.Model):
    _name = "actual.costing"

    # pi_no=fields.Char(string='PI Number', required=True)
    shipment_id=fields.Many2one('shipment.detail', string='Shipment',
     required=True)
    order_line = fields.One2many('forign.purchase.lc.items1', 'request_id', string='Order Lines', copy=True)
    cost_build_up = fields.One2many('cost.build.up1', 'cost_id', string='Cost', copy=True)
    total_cost=fields.Float('Total Cost')
    item_total=fields.Float(string='Item Total' )
    item_cost = fields.One2many('forign.item.cost', 'cost_id', string='Cost', copy=True)
    last_year_payment = fields.One2many('last.year.payment', 'cost_id', string='Cost', copy=True)
    
    partner_id = fields.Many2one('res.partner', string='Vendor', change_default=True, track_visibility='always')
    
    pi_amount=fields.Float(string='PI amount' )
    cost_total=fields.Float(string='Cost Total' )
    shipment_cost=fields.Float(string='Shipment Cost' )
    # shipment_total=fields.Float(string='Shipment total' )
    status=fields.Char(string='Status' )
    
    # purchase_order = fields.Many2one('forign.purchase.order',index=True,  string='Purchase Order')
    lc_number = fields.Char(string='LC Number',index=True)
    lc_date = fields.Datetime('LC Date', index=True)
   
    @api.model
    def create(self, vals):
        
        return super(ActualCosting, self).create(vals)
    # @api.onchange('last_year_payment')
    # def onchange_last_year_payment(self):
    #     # _logger.info('-------total_payment----************ = %s',total_payment)
    #     _logger.info('-!!------self.id----************ = %s',self.id)
    #     total_payment=0.0
    #     cost_search=[('cost_id', '=',self.id)]
    #     payments = self.env['last.year.payment'].search(cost_search).ids
    #     for payment in self.env['last.year.payment'].browse(payments):
    #         total_payment=total_payment +  payment.amount
    #         _logger.info('-------total_payment----************ = %s',total_payment)
          
    #     cost_total=self.cost_total
    #     _logger.info('-------cost_total----************ = %s',cost_total)
    #     self.total_cost=total_payment +cost_total
    #     _logger.info('-------self.total_cost----************ = %s',self.total_cost)
    @api.onchange('shipment_id')
    def onchange_pishipment_id(self):

        purchase_order=0
        purchase_orderr=0
        lc_numberr=''
        shipment_cost=0.0
        item_total=0.0
        cost_total=0.0
        pi_amount=0.0
        _logger.info('-------*******************')
        # _logger.info('!!!------------------ context id = %s',context.get('active_id'))
         
        # _logger.info('!!!------------------ self.context id = %s',self.env.context.get('id'))
        _logger.info('!!!------------------ self.pi = %s',self.shipment_id)
        _logger.info("++++++++++++++++++++++++++ on change")
        current_id=0
        cost_value={}
        _logger.info(self.shipment_id)
        terms_obj = self.shipment_id
        terms = []
        request_id=''
        terms1=[]
        terms2=[]
        terms3=[]
        pi=''
        shipment_id_val=''
        lc=''
        if terms_obj:
            for search_result in terms_obj:
                clause_final_ship = [('id', '=',self.shipment_id.id)]

                _logger.info('!!!------------------ clause_final = %s',clause_final_ship)
                search_results_ship= self.env['shipment.detail'].search(clause_final_ship).ids
                if search_results_ship:
                    _logger.info('-------search_results************ = %s',search_results_ship)
                    for search_result_ship in self.env['shipment.detail'].browse(search_results_ship):
                        current_id=search_result_ship.id
                        _logger.info("++++++++++++++++++++++++++ current_id %s",current_id)
                        _logger.info('!!!------------------ search_result = %s',search_result)
                        _logger.info('!!!------------------ search_result order_line------- = %s',search_result.order_line)
                        request_id=search_result.id
                        purchase_order=search_result_ship.pi_no.id
                        _logger.info('!!!------------------ search_result_ship.pi_no.id------- = %s',search_result_ship.pi_no.id)
                        
                        purchase_orderr=search_result_ship.pi_no.id
                        self.purchase_order=search_result_ship.pi_no.id
                        lc_numberr=search_result_ship.lc_id.lc_number
                        self.lc_number=lc_numberr
                        _logger.info('!!!-------------lcno------- = %s',search_result_ship.lc_id.lc_number)
                        lc_date=search_result_ship.lc_id.lc_date
                        self.lc_date=lc_date
                        _logger.info('!!!------------lcdate------ = %s',search_result_ship.lc_id.lc_date)
                        shipment_detail = self.env['forign.purchase.order'].search([('id', '=', search_result_ship.pi_no.id)])
                        
                        _logger.info('-------forign purchase************ = %s',shipment_detail)
                        pi=shipment_detail.partner_ref
                        shipment_id_val=self.shipment_id.shipment_no
                        _logger.info('-------PI************ = %s',shipment_detail.partner_ref)
                        lc_detail = self.env['forign.purchase.lc'].search([('pi', '=', shipment_detail.partner_ref)])
                        _logger.info('-------lc_detail************ = %s',lc_detail)
                        _logger.info('-------PI************ = %s',lc_detail.id)
                        lc=lc_detail.lc_number
                        pi_amount=lc_detail.lc_amount
                        
                        _logger.info('!!-------terms2----************ = %s',terms2)
                        _logger.info('!!-------search_result_ship.order_line----************ = %s',search_result_ship.order_line)
                        item_ids=search_result_ship.order_line
                        for item_id in item_ids:
                            _logger.info('!!-------item_id----************ = %s',item_id)

                            clause_final = [('id', '=',item_id.id)]
                            _logger.info('!!!------------------ clause_final = %s',clause_final)
                            search_results= self.env['forign.purchase.lc.items'].search(clause_final).ids
                            if search_results:
                                _logger.info('-------search_results************ = %s',search_results)
                                # _logger.info('-------term--------- = %s',terms)
                                # terms=self.env['purchase.order.line'].browse(search_results)
                                for search_result2 in self.env['forign.purchase.lc.items'].browse(search_results):
                                    _logger.info('-------search_result2************ = %s',search_result2)
                                    
                                    # _logger.info('-------self id************ = %s',self.id)
                                # _logger.info('-------terms************ = %s',terms)
                                    # search_result2.write({'state': 'RFQ')
                                    values = {}
                                    values['name'] = search_result2.name
                                    values['product_id'] = search_result2.product_id
                                    values['product_qty'] =search_result2.product_qty
                                    values['price_unit'] =search_result2.price_unit 
                                    values['product_uom'] =search_result2.product_uom 
                                    
                                    values['currency_id'] =search_result2.currency_id
                                    values['price_subtotal'] =search_result2.price_subtotal 
                                    item_total=item_total + search_result2.price_subtotal
                                    item_cost_value={}
                                    item_cost_value["product_id"]=search_result2.product_id.id
                                    item_cost_value["product_qty"]=search_result2.product_qty
                                    item_cost_value["price_subtotal"]=search_result2.price_subtotal 
                                    item_cost_value["shipment_id"]= self.shipment_id.id 
                                    _logger.info('-------item_cost_value************ = %s',item_cost_value)
                                    terms3.append((0, 0, values))
                                    # self.env['forign.item.cost'].create(item_cost_value)
                                    terms.append((0, 0, values))
                _logger.info('-------self.id************ = %s',self.id)
                _logger.info('-------terms3************ = %s',terms)
                _logger.info('-------item_total************ = %s',item_total)
                                              
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
            cost_search=['|','|',('reference', '=',pi),('reference', '=',shipment_id_val),('reference', '=',lc)]
            cost_search1=['|','|',('ref', '=',pi),('ref', '=',shipment_id_val),('ref', '=',lc)]
                        

            account_moves = self.env['account.move'].search(cost_search1).ids
            _logger.info('-------cost_detail************ = %s',cost_search1)
            if account_moves:
                # for search_result2 in cost_detail
                for account_move in self.env['account.move'].browse(account_moves):
                    _logger.info('-------account_move----************ = %s',account_move)
                    account_move.write({"case":"forign_purchase","main_id":purchase_order})
                    
            _logger.info('-------@@@@cost_search************ = %s',cost_search)
            cost_detail = self.env['cost.build.up'].search(cost_search).ids
            _logger.info('-------cost_detail************ = %s',cost_detail)
            if cost_detail:
                # for search_result2 in cost_detail
                for cost_detail1 in self.env['cost.build.up'].browse(cost_detail):
                    if cost_detail1.reference == shipment_id_val:
                        shipment_cost=shipment_cost +  cost_detail1.amount
                    _logger.info('-------cost_detail1----************ = %s',cost_detail1)
                    cost_value={}
                    cost_value["source_document"]=cost_detail1.source_document
                    cost_value["reference"]=cost_detail1.reference
                    cost_value["cost_category"]=cost_detail1.cost_category
                    cost_value["amount"]=cost_detail1.amount
                    
                    cost_total= cost_total + cost_detail1.amount
                    terms2.append((0, 0, cost_value))
                    _logger.info('-------terms2----************ = %s',terms2)
            
            clause_final_ship = [('id', '=',self.shipment_id.id)]

            _logger.info('!!!------------------ clause_final = %s',clause_final_ship)
            search_results_ship= self.env['shipment.detail'].search(clause_final_ship).ids
            if search_results_ship:
                _logger.info('-------search_results************ = %s',search_results_ship)
                for search_result_ship in self.env['shipment.detail'].browse(search_results_ship):
                    current_id=search_result_ship.id
                
            
            _logger.info('-------purchase_orderr************ = %s',purchase_orderr)
            _logger.info('-------lc_numberr************ = %s',lc_numberr)
            # self.purchase_order=purchase_orderr
            # self.lc_number=lc_numberr
            # self.lc_date=lc_date
            self.item_total=item_total
            self.cost_total=cost_total
            self.cost_build_up=terms2
            self.item_cost=terms3
            self.shipment_cost=shipment_cost
            self.pi_amount=pi_amount
            self.order_line=terms
            return
    
    
    @api.multi
    def compute_actual_cost(self):
        _logger.info('-------self.id************ = %s',self.id)
        _logger.info('-------self.shipment_id************ = %s',self.shipment_id)
        _logger.info('-------self.shipment_cost************ = %s',self.shipment_cost)
        if self.shipment_cost == 0:
            raise UserError(_("Can not compute is shipment cost is Zero."))
        else:
            shipment_no=''
            values={}
            order_line=0
            # get forign opration type id
            stock_type_id=0
            location_id=0
            location_dest_id=0
            stock_type_results = self.env['stock.picking.type'].search([('is_foreign', '=',True)]).ids
            if stock_type_results:
                for stock_type_result in self.env['stock.picking.type'].browse(stock_type_results):
                    stock_type_id=stock_type_result.id
                    _logger.info('!!-------stock_type_id************ = %s',stock_type_id) 
                    values['picking_type_id'] = stock_type_id
                
            shipment_results = self.env['shipment.detail'].search([('id', '=', self.shipment_id.id)]).ids
            _logger.info('-------state************ = %s',shipment_results)
            for shipment_result in self.env['shipment.detail'].browse(shipment_results):
                purchase_order=shipment_result.pi_no.id
                # order_line =shipment_result.id
                order_line =purchase_order
                _logger.info('-------purchase_order************ = %s',purchase_order) 
                _logger.info('-------order_line************ = %s',order_line) 
                scheduled_date=shipment_result.date
                shipment_no=shipment_result.shipment_no
                shipment_no=shipment_result.shipment_no
                vendor=shipment_result.pi_no.partner_id.id
                location_id= shipment_result.pi_no.partner_id.property_stock_supplier.id
                location_dest_id= shipment_result.pi_no._get_destination_location()
                values['origin'] = shipment_no
                values['partner_id'] = vendor
                values['location_id'] = location_id
                values['location_dest_id'] = location_dest_id
                values['scheduled_date'] = scheduled_date
                values['purchase_order'] = purchase_order
                values['state'] = 'assigned'
                shipment_result.write({"state":"done"})
            #     move_line_ids={}
            #     lc_item_lists = self.env['forign.purchase.lc.items'].search([('request_id', '=', self.shipment_id.id)]).ids
            #     _logger.info('-------state************ = %s',lc_item_lists)
            #     for lc_item_list in self.env['forign.purchase.lc.items'].browse(lc_item_lists):
            
            #         move_line_ids['product_id']=lc_item_list.product_id
            #         move_line_ids['product_qty']=lc_item_list.product_qty
            # values['move_line_ids'] = move_line_ids
            values['state'] = 'assigned'

                

            actual_cost_results = self.env['actual.costing'].search([('id', '=', self.id)]).ids
            _logger.info('-------move_det************ = %s',actual_cost_results)
            for actual_cost_result in self.env['actual.costing'].browse(actual_cost_results):

                actual_cost_result.write({"status":"done"})
            move_det = self.env['forign.item.cost'].search([('cost_id', '=', self.id)]).ids
            _logger.info('-------move_det************ = %s',move_det)
            for search_result in self.env['forign.item.cost'].browse(move_det):
                
                _logger.info('-------search_result************ = %s',search_result)
                item_sub_total=search_result.price_subtotal
                product_qty=search_result.product_qty
                over_all_item_total=self.item_total
                pi_amount=self.pi_amount
                shipment_cost=self.shipment_cost
                over_all_cost_total=self.total_cost
                # over_all_cost_total=self.cost_total
                other_cost=over_all_cost_total - shipment_cost
                # cost=(item_sub_total/over_all_item_total * over_all_cost_total)/product_qty

                cost=((item_sub_total/pi_amount * other_cost) + (item_sub_total/over_all_item_total * shipment_cost))/product_qty
                total=cost * product_qty
                _logger.info('-------cost************ = %s',cost)
                search_result.write({"cost":cost,"total":total})
            _logger.info('-------stock.picking values************ = %s',values)
            # _logger.info('-------values************ = %s',str(nextval('stock_picking_id_seq')))
            stock_picking=self.env['stock.picking'].create(values)
            stock_picking_id=stock_picking.id
            lc_item_lists = self.env['forign.purchase.lc.items'].search([('request_id', '=', self.shipment_id.id)]).ids
            _logger.info('-------state************ = %s',lc_item_lists)
            for lc_item_list in self.env['forign.purchase.lc.items'].browse(lc_item_lists):
                product_uom=1
                product_id= lc_item_list.product_id.id
                _logger.info('-------lc_item_list************ = %s',lc_item_list)
                _logger.info('-------product_id************ = %s',product_id)
                _logger.info('-------order_line************ = %s',order_line)
                order_line_details = self.env['forign.purchase.order.line'].search(['&',('order_id', '=', order_line),('product_id', '=',product_id)]).ids
                _logger.info('-------order_line_details************ = %s',order_line_details)
                for order_line_detail in self.env['forign.purchase.order.line'].browse(order_line_details):
                    
                    _logger.info('-------order_line_detail.product_uom.id************ = %s',order_line_detail.product_uom.id) 
                    product_uom=order_line_detail.product_uom.id
                unit_price=0
                forign_item_costs = self.env['forign.item.cost'].search([('cost_id', '=', self.id)]).ids
                _logger.info('-------forign_item_costs************ = %s',forign_item_costs)
                for forign_item_cost in self.env['forign.item.cost'].browse(forign_item_costs):
                    
                    _logger.info('-------forign_item_cost*********** = %s',forign_item_cost) 
                    unit_price=forign_item_cost.cost

                # item_list_value={}
                _logger.info('-------product_uom************ = %s',product_uom)
            
                item_list_value = {
                'name': lc_item_list.product_id.name,
                'product_id': lc_item_list.product_id.id,
                'product_uom': product_uom,
                # 'date': self.order_id.date_order,
                # # 'date_expected': self.date_planned,
                # 'location_id': self.order_id.partner_id.property_stock_supplier.id,
                # 'location_dest_id': self.order_id._get_destination_location(),
                # 'picking_id': picking.id,
                # 'partner_id': self.order_id.dest_address_id.id,
                # 'move_dest_ids': [(4, x) for x in self.move_dest_ids.ids],
                'state': 'draft',
                # 'purchase_line_id': self.id,
                # 'company_id': self.order_id.company_id.id,
                # 'price_unit': lc_item_list.price_unit,
                'price_unit': unit_price,
                # 'picking_type_id': self.order_id.picking_type_id.id,
                # 'group_id': self.order_id.group_id.id,
                # 'origin': self.order_id.name,
                # 'route_ids': self.order_id.picking_type_id.warehouse_id and [(6, 0, [x.id for x in self.order_id.picking_type_id.warehouse_id.route_ids])] or [],
                # 'warehouse_id': self.order_id.picking_type_id.warehouse_id.id,
                }
                item_list_value["picking_id"]=stock_picking_id
                
                item_list_value['location_id'] = location_id
                item_list_value['location_dest_id'] = location_dest_id
                # item_list_value["price_unit"]=lc_item_list.price_unit
                
                # item_list_value["product_qty"]=lc_item_list.product_qty
                item_list_value["product_uom_qty"]=lc_item_list.product_qty
                _logger.info('-------item_list_value************ = %s',item_list_value)
                self.env['stock.move'].create(item_list_value)\
                            ._action_confirm()\
                            ._action_assign()\
                            # ._action_done()
                # _logger.info('-------a************ = %s',a)
            
        



     
class ForignItemCost(models.Model):
    _name = 'forign.item.cost'
    product_qty = fields.Float(string='Quantity', digits=dp.get_precision('Product Unit of Measure'))
    cost = fields.Float(string='Unit Cost',digits=(16,6) )
    product_id = fields.Many2one('product.product', string='Product')
    price_subtotal = fields.Float(string='Sub Total')
    cost_id = fields.Many2one('actual.costing',index=True, ondelete='cascade')
    shipment_id=fields.Many2one('shipment.detail', string='Shipment',
    )
    total=fields.Float(string='Total' )
    @api.onchange('cost')
    def onchange_cost(self):
        self.total=self.product_qty * self.cost
    @api.model
    def create(self, vals):
        return super(ForignItemCost, self).create(vals)
    # @api.multi
    # def write(self, vals):
    #     vals['pi'] = self.purchase_order.partner_ref
    #     vals['lc_amount'] = self.purchase_order.amount_total
    #     res = super(ForignPurchaseLC, self).create(vals)
    #     return res
class PurchaseBudget(models.Model):
    _name = "purchase.budget"

    budget_period = fields.Many2one('accounting.period', string='Budget Period', required=True)
    department_id = fields.Many2one('hr.department', string='Department', required=True)
    state = fields.Selection([
        ('draft', 'Draft'),
        ('plan_sent', 'Sent'),
        ('approved', 'Approved')
        ], string='Status', readonly=True, index=True, copy=False, default='draft', track_visibility='onchange')
    
    order_line = fields.One2many('purchase.budget.items', 'budget_id', string='Order Lines', copy=True)
    
    @api.multi
    def set_to_draft(self):
        self.write({'state': 'draft' })
    @api.multi
    def submit_plannig(self):
        clause_final = [('id', '=', self.id)]
        search_results= self.env['purchase.budget'].search(clause_final).ids
        
        if search_results:
            for search_result in self.env['purchase.budget'].browse(search_results):
                search_result.write({"state": "draft"})
    @api.multi
    def submit_plannig(self):
        
        return {
                    'name':'Confirm',
                    'view_type':'form',
                    'view_mode':'form',
                    'res_model':'plannig.submit',
                    'type':'ir.actions.act_window',
                    'target':'new',
                }

    @api.multi
    def approve_plannig(self):
        return {
                    'name':'Confirm',
                    'view_type':'form',
                    'view_mode':'form',
                    'res_model':'plannig.approve',
                    'type':'ir.actions.act_window',
                    'target':'new',
                }
    @api.multi
    def make_adjustment(self):
        return {
                    'name':'Purchase Budget Adjustment',
                    'view_type':'form',
                    'view_mode':'form',
                    'res_model':'purchase.budget.items',
                     'context':{'default_budget_id': self.id,
                     'default_state': 'Adjustment'},
                     'type':'ir.actions.act_window',
                    'target':'new',
                }
    
class PlaningSubmit(models.Model):
    _name = 'plannig.submit'
    @api.multi
    def yes(self, context):
        id=context.get('active_id')
        clause_final = [('id', '=', id)]
        search_results= self.env['purchase.budget'].search(clause_final).ids
        
        if search_results:
            for search_result in self.env['purchase.budget'].browse(search_results):
                search_result.write({"state": "plan_sent"})
                # search_result._create_picking()
            return {'type': 'ir.actions.act_window_close','tag': 'reload',}
    @api.multi
    def no(self):
        pass 

class PlaningApprove(models.Model):
    _name = 'plannig.approve'
    @api.multi
    def yes(self, context):
        id=context.get('active_id')
        clause_final = [('id', '=', id)]
        search_results= self.env['purchase.budget'].search(clause_final).ids
        
        if search_results:
            for search_result in self.env['purchase.budget'].browse(search_results):
                search_result.write({"state": "approved"})
                # search_result._create_picking()
            return {'type': 'ir.actions.act_window_close','tag': 'reload',}
    @api.multi
    def no(self):
        pass 
class PurchaseBudgetItems(models.Model):
    _name = 'purchase.budget.items'
    date = fields.Datetime('Date',default=fields.Datetime.now)
    product_qty = fields.Float(string='Quantity', 
    digits=dp.get_precision('Product Unit of Measure'), required=True)
    product_id = fields.Many2one('product.product', string='Product', 
    domain=[('purchase_ok', '=', True)], change_default=True, required=True)
    price_unit = fields.Float(string='Unit Price', required=True)
    actual_total_price = fields.Float(string='Remaining Total Price')
    remaining_issue_quantity = fields.Float(string='Remaining issue quantity')
    actual_qty = fields.Float(string='Remaining Total Quntity')
    price_subtotal = fields.Monetary(string='Sub Total')
    currency_id = fields.Many2one('res.currency', 'Currency')
    name = fields.Text(string='Description')
    # amount = fields.Float(string='Amount')
    budget_id = fields.Many2one('purchase.budget', string='Order Reference', 
    index=True, ondelete='cascade')
    state=fields.Char(default="")
    
     
    @api.onchange('product_qty')
    def onchange_product_qty(self):
        self.price_subtotal = self.price_unit * self.product_qty
    @api.onchange('price_unit')
    def onchange_price_unit(self):
        self.price_subtotal = self.price_unit * self.product_qty
    @api.model
    def create(self, vals):

        product_id=vals.get('product_id')
        budget_id=vals.get('budget_id')
        
        _logger.info('-------product_id************ = %s',product_id)
        
        _logger.info('-------budget_id************ = %s',budget_id)
        clause_final = ['&',('product_id', '=', product_id),('budget_id', '=', budget_id)]
        _logger.info('-------clause_final************ = %s',clause_final)
        search_results= self.env['purchase.budget.items'].search(clause_final).ids
        
        if search_results:  
            for search_result in self.env['purchase.budget.items'].browse(search_results):
                prev_qty=search_result.actual_qty
                prev_price=search_result.actual_total_price
                prev_issued=search_result.remaining_issue_quantity
                vals['actual_total_price']=prev_price + vals.get('price_subtotal')
                vals['remaining_issue_quantity']=prev_issued + vals.get('product_qty')
                vals['actual_qty']=prev_qty + vals.get('product_qty')
                vals['state']='Adjustment'
                
        else:
            vals['actual_total_price']= vals.get('price_subtotal')
            vals['actual_qty']= vals.get('product_qty')
            vals['remaining_issue_quantity']= vals.get('product_qty')
            
        return super(PurchaseBudgetItems, self).create(vals)