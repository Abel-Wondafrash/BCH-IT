# -*- coding: utf-8 -*-

from odoo import api, fields, models
import logging
_logger = logging.getLogger(__name__)
#----------------------------------------

class AccountCommonJournalReport(models.TransientModel):
    _name = 'account.common.journal.report'
    _description = 'Account Common Journal Report'
    _inherit = "account.common.report"

    amount_currency = fields.Boolean('With Currency', help="Print Report with the currency column if the currency differs from the company currency.")

    @api.multi
    def pre_print_report(self, data):
        data['form'].update({'amount_currency': self.amount_currency})
        return data


class CustomerBalance(models.TransientModel):
    _name = 'account.customer.balance'
    

    partner = fields.Many2one('res.partner', string='Partner')
    from_date = fields.Datetime(string='From Date')
    to_date = fields.Datetime(string='To Date')

    # current_balance = fields.Float(string='Amount')
    def getcustomerBalance(self):
        total_sale = []
        fromDate=self.from_date
        thruDate=self.to_date


        _logger.info("@@@@@@@@@@@@@@@@@@@@@@fromDate@@ %s", fromDate)
        _logger.info("@@@@@@@@@@@@@@@@@@@@@thruDate@@@ %s",thruDate)
        report_detail=[]   

        total_diposit=0
        total_invoice=0

        clause=['&','&',('date','<',fromDate),('partner','=',self.partner.id),('ref','like','BKDP%')]
         
        account_move= self.env['account.move'].search(clause).ids
      
        if account_move:

            
            for move in self.env['account.move'].browse(account_move):
                _logger.info("@@@@@@@@@@@@@@@@@@@@@@move@@ %s", move)
                search_results= self.env['account.move.line'].search(['&',('move_id','=',move.id),('debit','>',0)]).ids

                for search_result in self.env['account.move.line'].browse(search_results):
                    total_diposit=total_diposit + search_result.debit


        clause_final=['&','&',('date','<',fromDate),('partner','=',self.partner.id),('name','like','INV%')]
         
        account_invoice= self.env['account.move'].search(clause_final).ids

    
        if account_invoice:
            for inv in self.env['account.move'].browse(account_invoice):


                _logger.info("@@@@@@@@@@@@@@@@@@@@@@account_invoice@@ %s", inv)
                search_results= self.env['account.move.line'].search(['&',('move_id','=',inv.id),('debit','>',0)]).ids

                for search_result in self.env['account.move.line'].browse(search_results):
                    total_diposit=total_invoice + search_result.debit
        
        _logger.info("@@@@@@@@@@@@@@@@@@@@@@total_diposit@@ %s", total_diposit)
        _logger.info("@@@@@@@@@@@@@@@@@@@@@@total_invoice@@ %s", total_invoice)  
        current_balance= total_diposit- total_invoice
        _logger.info("@@@@@@@@@@@@@@@@@@@@@@current_balance@@ %s", current_balance) 
        clause=['&','&',('date','>',fromDate),('date','<',thruDate),('partner','=',self.partner.id)]
        _logger.info("@@@@@@@@@@@@@@@@@@@@@@clause@@ %s", clause) 
        account_move= self.env['account.move'].search(clause, order='date asc').ids
        
        _logger.info("@@@@@@@@@@@@@@@@@@@@@@account_move@@ %s", account_move) 
        
        current_balance_temp=current_balance
        if account_move:
            for move in self.env['account.move'].browse(account_move):
                account_move_name=move.name
                ref=move.ref
                _logger.info("@@@@@@@@@@@@@@@@@@@@@@account_move_name@@ %s", account_move_name) 
                _logger.info("@@@@@@@@@@@@@@@@@@@@@@move@@ %s", move)
                search_results= self.env['account.move.line'].search(['&',('move_id','=',move.id),('debit','>',0)]).ids

                deposit=0
                sale=0
                
                for search_result in self.env['account.move.line'].browse(search_results):
                    total_diposit=total_diposit + search_result.debit
                    
                    res={}
                    res['current_balance'] = current_balance
                    res['customer'] = move.partner.name
                    res['date'] = search_result.date
                    if ref:
                        _logger.info("@@@@@@@@@@@@@@@@@@@@@@ref@@ %s", ref)
                        if ref.startswith( 'BKDP' ):
                            current_balance_temp=current_balance_temp + search_result.debit
                            res['deposit'] = search_result.debit
                            res['sale'] = 0
                            deposit=1
                    elif   account_move_name.startswith( 'INV' ):
                        current_balance_temp=current_balance_temp - search_result.debit
                        
                        res['sale'] = search_result.debit
                        res['deposit'] = 0
                        sale=1
                    _logger.info("@@@@@@@@@@@@@@@@@@@@@@current_balance_temp@@ %s", current_balance_temp) 
                    _logger.info("@@@@@@@@@@@@@@@@@@@@@@current_balance_temp@@ %s", current_balance_temp) 
                    _logger.info("@@@@@@@@@@@@@@@@@@@@@@sale@@ %s", sale) 
                    _logger.info("@@@@@@@@@@@@@@@@@@@@@@deposit@@ %s", deposit) 
                    res['new_balance'] = current_balance_temp
                    if sale != 0 or deposit !=0:
                        report_detail.append(res)

                    _logger.info("@@@@@@@@@@@@@@@@@@@@@@report_detail@@ %s", report_detail) 

        return report_detail

    def print_customer_balance(self):
        
        # return self.env.ref('sale.action_report_creditsales').report_action(self)
        return {
                'type': 'ir.actions.report',
                'report_name': 'account.report_account_balance',
                'model': 'account.customer.balance',
                'report_type': "qweb-html",
            }

