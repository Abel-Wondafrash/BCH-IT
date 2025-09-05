# -*- coding: utf-8 -*-

import time
import math

from odoo.osv import expression
# from odoo.tools.float_utils import float_round as round
from odoo.tools import float_compare, float_round, float_repr
from odoo.tools import DEFAULT_SERVER_DATETIME_FORMAT
from odoo.exceptions import UserError, ValidationError
from odoo import api, fields, models, _
import logging
from datetime import datetime, timedelta
_logger = logging.getLogger(__name__)

from xml.dom import minidom
import os
import xml.etree.ElementTree as etree
import os.path
class AccountAccountType(models.Model):
    _name = "account.account.type"
    _description = "Account Type"

    name = fields.Char(string='Account Type', required=True, translate=True)
    include_initial_balance = fields.Boolean(string="Bring Accounts Balance Forward", help="Used in reports to know if we should consider journal items from the beginning of time instead of from the fiscal year only. Account types that should be reset to zero at each new fiscal year (like expenses, revenue..) should not have this option set.")
    type = fields.Selection([
        ('other', 'Regular'),
        ('receivable', 'Receivable'),
        ('payable', 'Payable'),
        ('liquidity', 'Liquidity'),
    ], required=True, default='other',
        help="The 'Internal Type' is used for features available on "\
        "different types of accounts: liquidity type is for cash or bank accounts"\
        ", payable/receivable is for vendor/customer accounts.")
    note = fields.Text(string='Description')


class AccountAccountTag(models.Model):
    _name = 'account.account.tag'
    _description = 'Account Tag'

    name = fields.Char(required=True)
    applicability = fields.Selection([('accounts', 'Accounts'), ('taxes', 'Taxes')], required=True, default='accounts')
    color = fields.Integer('Color Index', default=10)
    active = fields.Boolean(default=True, help="Set active to false to hide the Account Tag without removing it.")

#----------------------------------------------------------
# Accounts
#----------------------------------------------------------


class AccountAccount(models.Model):
    _name = "account.account"
    _description = "Account"
    _order = "code"

    @api.multi
    @api.constrains('internal_type', 'reconcile')
    def _check_reconcile(self):
        for account in self:
            if account.internal_type in ('receivable', 'payable') and account.reconcile == False:
                raise ValidationError(_('You cannot have a receivable/payable account that is not reconcilable. (account code: %s)') % account.code)

    name = fields.Char( index=True)
    currency_id = fields.Many2one('res.currency', string='Account Currency',
        help="Forces all moves for this account to have this account currency.")
    code = fields.Char(size=64, required=True, index=True)
    deprecated = fields.Boolean(index=True, default=False)
    # is_trade_debitor = fields.Boolean(index=True, default=False)
    # is_trade_creditor = fields.Boolean(index=True, default=False)
    user_type_id = fields.Many2one('account.account.type', string='Type', required=True, oldname="user_type",
        help="Account Type is used for information purpose, to generate country-specific legal reports, and set the rules to close a fiscal year and generate opening entries.")
    internal_type = fields.Selection(related='user_type_id.type', string="Internal Type", store=True, readonly=True)
    #has_unreconciled_entries = fields.Boolean(compute='_compute_has_unreconciled_entries',
    #    help="The account has at least one unreconciled debit and credit since last time the invoices & payments matching was performed.")
    last_time_entries_checked = fields.Datetime(string='Latest Invoices & Payments Matching Date', readonly=True, copy=False,
        help='Last time the invoices & payments matching was performed on this account. It is set either if there\'s not at least '\
        'an unreconciled debit and an unreconciled credit Or if you click the "Done" button.')
    reconcile = fields.Boolean(string='Allow Reconciliation', default=False,
        help="Check this box if this account allows invoices & payments matching of journal items.")
    tax_ids = fields.Many2many('account.tax', 'account_account_tax_default_rel',
        'account_id', 'tax_id', string='Default Taxes')
    note = fields.Text('Internal Notes')
    company_id = fields.Many2one('res.company', string='Company', required=True,
        default=lambda self: self.env['res.company']._company_default_get('account.account'))
    tag_ids = fields.Many2many('account.account.tag', 'account_account_account_tag', string='Tags', help="Optional tags you may want to assign for custom reporting")
    group_id = fields.Many2one('account.group')

    opening_debit = fields.Monetary(string="Opening debit", compute='_compute_opening_debit_credit', inverse='_set_opening_debit', help="Opening debit value for this account.")
    opening_credit = fields.Monetary(string="Opening credit", compute='_compute_opening_debit_credit', inverse='_set_opening_credit', help="Opening credit value for this account.")

    _sql_constraints = [
        ('code_company_uniq', 'unique (code,company_id)', 'The code of the account must be unique per company !')
    ]

    def _compute_opening_debit_credit(self):
        for record in self:
            opening_debit = opening_credit = 0.0
            if record.company_id.account_opening_move_id:
                for line in self.env['account.move.line'].search([('account_id', '=', record.id),
                                                                 ('move_id','=', record.company_id.account_opening_move_id.id)]):
                    #could be executed at most twice: once for credit, once for debit
                    if line.debit:
                        opening_debit = line.debit
                    elif line.credit:
                        opening_credit = line.credit
            record.opening_debit = opening_debit
            record.opening_credit = opening_credit

    def _set_opening_debit(self):
        self._set_opening_debit_credit(self.opening_debit, 'debit')

    def _set_opening_credit(self):
        self._set_opening_debit_credit(self.opening_credit, 'credit')

    def _set_opening_debit_credit(self, amount, field):
        """ Generic function called by both opening_debit and opening_credit's
        inverse function. 'Amount' parameter is the value to be set, and field
        either 'debit' or 'credit', depending on wich one of these two fields
        got assigned.
        """
        opening_move = self.company_id.account_opening_move_id

        if not opening_move:
            raise UserError(_("No opening move defined !"))

        if opening_move.state == 'draft':
            # check whether we should create a new move line or modify an existing one
            opening_move_line = self.env['account.move.line'].search([('account_id', '=', self.id),
                                                                      ('move_id','=', opening_move.id),
                                                                      (field,'!=', False),
                                                                      (field,'!=', 0.0)]) # 0.0 condition important for import

            counter_part_map = {'debit': opening_move_line.credit, 'credit': opening_move_line.debit}
            # No typo here! We want the credit value when treating debit and debit value when treating credit

            if opening_move_line:
                if amount:
                    # modify the line
                    setattr(opening_move_line.with_context({'check_move_validity': False}), field, amount)
                elif counter_part_map[field]:
                    # delete the line (no need to keep a line with value = 0)
                    opening_move_line.with_context({'check_move_validity': False}).unlink()
            elif amount:
                # create a new line, as none existed before
                self.env['account.move.line'].with_context({'check_move_validity': False}).create({
                        'name': _('Opening balance'),
                        field: amount,
                        'move_id': opening_move.id,
                        'account_id': self.id,
                })

            # Then, we automatically balance the opening move, to make sure it stays valid
            if not 'import_file' in self.env.context:
                # When importing a file, avoid recomputing the opening move for each account and do it at the end, for better performances
                self.company_id._auto_balance_opening_move()

    @api.model
    def default_get(self, default_fields):
        """If we're creating a new account through a many2one, there are chances that we typed the account code
        instead of its name. In that case, switch both fields values.
        """
        default_name = self._context.get('default_name')
        default_code = self._context.get('default_code')
        if default_name and not default_code:
            try:
                default_code = int(default_name)
            except ValueError:
                pass
            if default_code:
                default_name = False
        contextual_self = self.with_context(default_name=default_name, default_code=default_code)
        return super(AccountAccount, contextual_self).default_get(default_fields)

    @api.model
    def name_search(self, name, args=None, operator='ilike', limit=100):
        args = args or []
        domain = []
        if name:
            domain = ['|', ('code', '=ilike', name + '%'), ('name', operator, name)]
            if operator in expression.NEGATIVE_TERM_OPERATORS:
                domain = ['&', '!'] + domain[1:]
        accounts = self.search(domain + args, limit=limit)
        return accounts.name_get()

    @api.onchange('internal_type')
    def onchange_internal_type(self):
        if self.internal_type in ('receivable', 'payable'):
            self.reconcile = True

    @api.onchange('code')
    def onchange_code(self):
        AccountGroup = self.env['account.group']

        group = False
        code_prefix = self.code

        # find group with longest matching prefix
        while code_prefix:
            matching_group = AccountGroup.search([('code_prefix', '=', code_prefix)], limit=1)
            if matching_group:
                group = matching_group
                break
            code_prefix = code_prefix[:-1]
        self.group_id = group

    @api.multi
    @api.depends('name', 'code')
    def name_get(self):
        result = []
        for account in self:
            name = account.code + ' ' + account.name
            result.append((account.id, name))
        return result

    @api.one
    @api.returns('self', lambda value: value.id)
    def copy(self, default=None):
        default = dict(default or {})
        default.setdefault('code', _("%s (copy)") % (self.code or ''))
        return super(AccountAccount, self).copy(default)

    @api.model
    def load(self, fields, data):
        """ Overridden for better performances when importing a list of account
        with opening debit/credit. In that case, the auto-balance is postpone
        untill the whole file has been imported.
        """
        rslt = super(AccountAccount, self).load(fields, data)

        if 'import_file' in self.env.context:
            companies = self.search([('id', 'in', rslt['ids'])]).mapped('company_id')
            for company in companies:
                company._auto_balance_opening_move()
        return rslt

    @api.multi
    def write(self, vals):
        # Dont allow changing the company_id when account_move_line already exist
        if vals.get('company_id', False):
            move_lines = self.env['account.move.line'].search([('account_id', 'in', self.ids)], limit=1)
            for account in self:
                if (account.company_id.id != vals['company_id']) and move_lines:
                    raise UserError(_('You cannot change the owner company of an account that already contains journal items.'))
        # If user change the reconcile flag, all aml should be recomputed for that account and this is very costly.
        # So to prevent some bugs we add a constraint saying that you cannot change the reconcile field if there is any aml existing
        # for that account.
        if vals.get('reconcile'):
            move_lines = self.env['account.move.line'].search([('account_id', 'in', self.ids)], limit=1)
            if len(move_lines):
                raise UserError(_('You cannot change the value of the reconciliation on this account as it already has some moves'))
        return super(AccountAccount, self).write(vals)

    @api.multi
    def unlink(self):
        if self.env['account.move.line'].search([('account_id', 'in', self.ids)], limit=1):
            raise UserError(_('You cannot do that on an account that contains journal items.'))
        #Checking whether the account is set as a property to any Partner or not
        values = ['account.account,%s' % (account_id,) for account_id in self.ids]
        partner_prop_acc = self.env['ir.property'].search([('value_reference', 'in', values)], limit=1)
        if partner_prop_acc:
            raise UserError(_('You cannot remove/deactivate an account which is set on a customer or vendor.'))
        return super(AccountAccount, self).unlink()

    @api.multi
    def mark_as_reconciled(self):
        return self.write({'last_time_entries_checked': time.strftime(DEFAULT_SERVER_DATETIME_FORMAT)})

    @api.multi
    def action_open_reconcile(self):
        self.ensure_one()
        # Open reconciliation view for this account
        if self.internal_type == 'payable':
            action_context = {'show_mode_selector': False, 'mode': 'suppliers'}
        elif self.internal_type == 'receivable':
            action_context = {'show_mode_selector': False, 'mode': 'customers'}
        else:
            action_context = {'show_mode_selector': False, 'mode': 'accounts', 'account_ids': [self.id,]}
        return {
            'type': 'ir.actions.client',
            'tag': 'manual_reconciliation_view',
            'context': action_context,
        }


class AccountGroup(models.Model):
    _name = "account.group"

    _parent_store = True
    _order = 'code_prefix'

    parent_id = fields.Many2one('account.group', index=True, ondelete='cascade')
    parent_left = fields.Integer('Left Parent', index=True)
    parent_right = fields.Integer('Right Parent', index=True)
    name = fields.Char(required=True)
    code_prefix = fields.Char()

    def name_get(self):
        result = []
        for group in self:
            name = group.name
            if group.code_prefix:
                name = group.code_prefix + ' ' + name
            result.append((group.id, name))
        return result

    @api.model
    def name_search(self, name='', args=None, operator='ilike', limit=100):
        if not args:
            args = []
        criteria_operator = ['|'] if operator not in expression.NEGATIVE_TERM_OPERATORS else ['&', '!']
        domain = criteria_operator + [('code_prefix', '=ilike', name + '%'), ('name', operator, name)]
        return self.search(domain + args, limit=limit).name_get()

class AccountJournal(models.Model):
    _name = "account.journal"
    _description = "Journal"
    _order = 'sequence, type, code'

    def _default_inbound_payment_methods(self):
        return self.env.ref('account.account_payment_method_manual_in')

    def _default_outbound_payment_methods(self):
        return self.env.ref('account.account_payment_method_manual_out')

    name = fields.Char(string='Journal Name', required=True)
    code = fields.Char(string='Short Code', size=5, required=True, help="The journal entries of this journal will be named using this prefix.")
    active = fields.Boolean(default=True, help="Set active to false to hide the Journal without removing it.")
    type = fields.Selection([
            ('sale', 'Sale'),
            ('purchase', 'Purchase'),
            ('cash', 'Cash'),
            ('bank', 'Bank'),
            ('general', 'Miscellaneous'),
        ], required=True,
        help="Select 'Sale' for customer invoices journals.\n"\
        "Select 'Purchase' for vendor bills journals.\n"\
        "Select 'Cash' or 'Bank' for journals that are used in customer or vendor payments.\n"\
        "Select 'General' for miscellaneous operations journals.")
    type_control_ids = fields.Many2many('account.account.type', 'account_journal_type_rel', 'journal_id', 'type_id', string='Account Types Allowed')
    account_control_ids = fields.Many2many('account.account', 'account_account_type_rel', 'journal_id', 'account_id', string='Accounts Allowed',
        domain=[('deprecated', '=', False)])
    default_credit_account_id = fields.Many2one('account.account', string='Default Credit Account',
        domain=[('deprecated', '=', False)], help="It acts as a default account for credit amount")
    default_debit_account_id = fields.Many2one('account.account', string='Default Debit Account',
        domain=[('deprecated', '=', False)], help="It acts as a default account for debit amount")
    update_posted = fields.Boolean(string='Allow Cancelling Entries',
        help="Check this box if you want to allow the cancellation the entries related to this journal or of the invoice related to this journal")
    group_invoice_lines = fields.Boolean(string='Group Invoice Lines',
        help="If this box is checked, the system will try to group the accounting lines when generating them from invoices.")
    sequence_id = fields.Many2one('ir.sequence', string='Entry Sequence',
        help="This field contains the information related to the numbering of the journal entries of this journal.", required=True, copy=False)
    refund_sequence_id = fields.Many2one('ir.sequence', string='Credit Note Entry Sequence',
        help="This field contains the information related to the numbering of the credit note entries of this journal.", copy=False)
    sequence = fields.Integer(help='Used to order Journals in the dashboard view', default=10)
    sequence_number_next = fields.Integer(string='Next Number',
        help='The next sequence number will be used for the next invoice.',
        compute='_compute_seq_number_next',
        inverse='_inverse_seq_number_next')
    refund_sequence_number_next = fields.Integer(string='Credit Notes: Next Number',
        help='The next sequence number will be used for the next credit note.',
        compute='_compute_refund_seq_number_next',
        inverse='_inverse_refund_seq_number_next')

    #groups_id = fields.Many2many('res.groups', 'account_journal_group_rel', 'journal_id', 'group_id', string='Groups')
    currency_id = fields.Many2one('res.currency', help='The currency used to enter statement', string="Currency", oldname='currency')
    company_id = fields.Many2one('res.company', string='Company', required=True, index=True, default=lambda self: self.env.user.company_id,
        help="Company related to this journal")

    refund_sequence = fields.Boolean(string='Dedicated Credit Note Sequence', help="Check this box if you don't want to share the same sequence for invoices and credit notes made from this journal", default=False)

    inbound_payment_method_ids = fields.Many2many('account.payment.method', 'account_journal_inbound_payment_method_rel', 'journal_id', 'inbound_payment_method',
        domain=[('payment_type', '=', 'inbound')], string='Debit Methods', default=lambda self: self._default_inbound_payment_methods(),
        help="Manual: Get paid by cash, check or any other method outside of Odoo.\n"\
             "Electronic: Get paid automatically through a payment acquirer by requesting a transaction on a card saved by the customer when buying or subscribing online (payment token).\n"\
             "Batch Deposit: Encase several customer checks at once by generating a batch deposit to submit to your bank. When encoding the bank statement in Odoo,you are suggested to reconcile the transaction with the batch deposit. Enable this option from the settings.")
    outbound_payment_method_ids = fields.Many2many('account.payment.method', 'account_journal_outbound_payment_method_rel', 'journal_id', 'outbound_payment_method',
        domain=[('payment_type', '=', 'outbound')], string='Payment Methods', default=lambda self: self._default_outbound_payment_methods(),
        help="Manual:Pay bill by cash or any other method outside of Odoo.\n"\
             "Check:Pay bill by check and print it from Odoo.\n"\
             "SEPA Credit Transfer: Pay bill from a SEPA Credit Transfer file you submit to your bank. Enable this option from the settings.")
    at_least_one_inbound = fields.Boolean(compute='_methods_compute', store=True)
    at_least_one_outbound = fields.Boolean(compute='_methods_compute', store=True)
    profit_account_id = fields.Many2one('account.account', string='Profit Account', domain=[('deprecated', '=', False)], help="Used to register a profit when the ending balance of a cash register differs from what the system computes")
    loss_account_id = fields.Many2one('account.account', string='Loss Account', domain=[('deprecated', '=', False)], help="Used to register a loss when the ending balance of a cash register differs from what the system computes")

    belongs_to_company = fields.Boolean('Belong to the user\'s current company', compute="_belong_to_company", search="_search_company_journals",)

    # Bank journals fields
    bank_account_id = fields.Many2one('res.partner.bank', string="Bank Account", ondelete='restrict', copy=False, domain="[('partner_id','=', company_id)]")
    bank_statements_source = fields.Selection([('undefined', 'Undefined Yet'),('manual', 'Record Manually')], string='Bank Feeds', default='undefined')
    bank_acc_number = fields.Char(related='bank_account_id.acc_number')
    bank_id = fields.Many2one('res.bank', related='bank_account_id.bank_id')

    _sql_constraints = [
        ('code_company_uniq', 'unique (code, name, company_id)', 'The code and name of the journal must be unique per company !'),
    ]

    @api.multi
    # do not depend on 'sequence_id.date_range_ids', because
    # sequence_id._get_current_sequence() may invalidate it!
    @api.depends('sequence_id.use_date_range', 'sequence_id.number_next_actual')
    def _compute_seq_number_next(self):
        '''Compute 'sequence_number_next' according to the current sequence in use,
        an ir.sequence or an ir.sequence.date_range.
        '''
        for journal in self:
            if journal.sequence_id:
                sequence = journal.sequence_id._get_current_sequence()
                journal.sequence_number_next = sequence.number_next_actual
            else:
                journal.sequence_number_next = 1

    @api.multi
    def _inverse_seq_number_next(self):
        '''Inverse 'sequence_number_next' to edit the current sequence next number.
        '''
        for journal in self:
            if journal.sequence_id and journal.sequence_number_next:
                sequence = journal.sequence_id._get_current_sequence()
                sequence.sudo().number_next = journal.sequence_number_next

    @api.multi
    # do not depend on 'refund_sequence_id.date_range_ids', because
    # refund_sequence_id._get_current_sequence() may invalidate it!
    @api.depends('refund_sequence_id.use_date_range', 'refund_sequence_id.number_next_actual')
    def _compute_refund_seq_number_next(self):
        '''Compute 'sequence_number_next' according to the current sequence in use,
        an ir.sequence or an ir.sequence.date_range.
        '''
        for journal in self:
            if journal.refund_sequence_id and journal.refund_sequence:
                sequence = journal.refund_sequence_id._get_current_sequence()
                journal.refund_sequence_number_next = sequence.number_next_actual
            else:
                journal.refund_sequence_number_next = 1

    @api.multi
    def _inverse_refund_seq_number_next(self):
        '''Inverse 'refund_sequence_number_next' to edit the current sequence next number.
        '''
        for journal in self:
            if journal.refund_sequence_id and journal.refund_sequence and journal.refund_sequence_number_next:
                sequence = journal.refund_sequence_id._get_current_sequence()
                sequence.number_next = journal.refund_sequence_number_next

    @api.one
    @api.constrains('currency_id', 'default_credit_account_id', 'default_debit_account_id')
    def _check_currency(self):
        if self.currency_id:
            if self.default_credit_account_id and not self.default_credit_account_id.currency_id.id == self.currency_id.id:
                raise ValidationError(_('Configuration error!\nThe currency of the journal should be the same than the default credit account.'))
            if self.default_debit_account_id and not self.default_debit_account_id.currency_id.id == self.currency_id.id:
                raise ValidationError(_('Configuration error!\nThe currency of the journal should be the same than the default debit account.'))

    @api.one
    @api.constrains('type', 'bank_account_id')
    def _check_bank_account(self):
        if self.type == 'bank' and self.bank_account_id:
            if self.bank_account_id.company_id != self.company_id:
                raise ValidationError(_('The bank account of a bank journal must belong to the same company (%s).') % self.company_id.name)
            # A bank account can belong to a customer/supplier, in which case their partner_id is the customer/supplier.
            # Or they are part of a bank journal and their partner_id must be the company's partner_id.
            if self.bank_account_id.partner_id != self.company_id.partner_id:
                raise ValidationError(_('The holder of a journal\'s bank account must be the company (%s).') % self.company_id.name)

    @api.onchange('default_debit_account_id')
    def onchange_debit_account_id(self):
        if not self.default_credit_account_id:
            self.default_credit_account_id = self.default_debit_account_id

    @api.onchange('default_credit_account_id')
    def onchange_credit_account_id(self):
        if not self.default_debit_account_id:
            self.default_debit_account_id = self.default_credit_account_id

    @api.multi
    def unlink(self):
        bank_accounts = self.env['res.partner.bank'].browse()
        for bank_account in self.mapped('bank_account_id'):
            accounts = self.search([('bank_account_id', '=', bank_account.id)])
            if accounts <= self:
                bank_accounts += bank_account
        ret = super(AccountJournal, self).unlink()
        bank_accounts.unlink()
        return ret

    @api.one
    @api.returns('self', lambda value: value.id)
    def copy(self, default=None):
        default = dict(default or {})
        default.update(
            code=_("%s (copy)") % (self.code or ''),
            name=_("%s (copy)") % (self.name or ''))
        return super(AccountJournal, self).copy(default)

    @api.multi
    def write(self, vals):
        for journal in self:
            if ('company_id' in vals and journal.company_id.id != vals['company_id']):
                if self.env['account.move'].search([('journal_id', 'in', self.ids)], limit=1):
                    raise UserError(_('This journal already contains items, therefore you cannot modify its company.'))
                if self.bank_account_id:
                    self.bank_account_id.company_id = vals['company_id']
            if ('code' in vals and journal.code != vals['code']):
                if self.env['account.move'].search([('journal_id', 'in', self.ids)], limit=1):
                    raise UserError(_('This journal already contains items, therefore you cannot modify its short name.'))
                new_prefix = self._get_sequence_prefix(vals['code'], refund=False)
                journal.sequence_id.write({'prefix': new_prefix})
                if journal.refund_sequence_id:
                    new_prefix = self._get_sequence_prefix(vals['code'], refund=True)
                    journal.refund_sequence_id.write({'prefix': new_prefix})
            if 'currency_id' in vals:
                if not 'default_debit_account_id' in vals and self.default_debit_account_id:
                    self.default_debit_account_id.currency_id = vals['currency_id']
                if not 'default_credit_account_id' in vals and self.default_credit_account_id:
                    self.default_credit_account_id.currency_id = vals['currency_id']
                if self.bank_account_id:
                    self.bank_account_id.currency_id = vals['currency_id']
            if 'bank_account_id' in vals and not vals.get('bank_account_id'):
                raise UserError(_('You cannot empty the bank account once set.'))
        result = super(AccountJournal, self).write(vals)

        # Create the bank_account_id if necessary
        if 'bank_acc_number' in vals:
            for journal in self.filtered(lambda r: r.type == 'bank' and not r.bank_account_id):
                journal.set_bank_account(vals.get('bank_acc_number'), vals.get('bank_id'))
        # create the relevant refund sequence
        if vals.get('refund_sequence'):
            for journal in self.filtered(lambda j: j.type in ('sale', 'purchase') and not j.refund_sequence_id):
                journal_vals = {
                    'name': journal.name,
                    'company_id': journal.company_id.id,
                    'code': journal.code,
                    'refund_sequence_number_next': vals.get('refund_sequence_number_next', journal.refund_sequence_number_next),
                }
                journal.refund_sequence_id = self.sudo()._create_sequence(journal_vals, refund=True).id
        return result

    @api.model
    def _get_sequence_prefix(self, code, refund=False):
        prefix = code.upper()
        if refund:
            prefix = 'R' + prefix
        return prefix + '/%(range_year)s/'

    @api.model
    def _create_sequence(self, vals, refund=False):
        """ Create new no_gap entry sequence for every new Journal"""
        prefix = self._get_sequence_prefix(vals['code'], refund)
        seq = {
            'name': refund and vals['name'] + _(': Refund') or vals['name'],
            'implementation': 'no_gap',
            'prefix': prefix,
            'padding': 4,
            'number_increment': 1,
            'use_date_range': True,
        }
        if 'company_id' in vals:
            seq['company_id'] = vals['company_id']
        seq = self.env['ir.sequence'].create(seq)
        seq_date_range = seq._get_current_sequence()
        seq_date_range.number_next = refund and vals.get('refund_sequence_number_next', 1) or vals.get('sequence_number_next', 1)
        return seq

    @api.model
    def _prepare_liquidity_account(self, name, company, currency_id, type):
        '''
        This function prepares the value to use for the creation of the default debit and credit accounts of a
        liquidity journal (created through the wizard of generating COA from templates for example).

        :param name: name of the bank account
        :param company: company for which the wizard is running
        :param currency_id: ID of the currency in wich is the bank account
        :param type: either 'cash' or 'bank'
        :return: mapping of field names and values
        :rtype: dict
        '''

        # Seek the next available number for the account code
        code_digits = company.accounts_code_digits or 0
        if type == 'bank':
            account_code_prefix = company.bank_account_code_prefix or ''
        else:
            account_code_prefix = company.cash_account_code_prefix or company.bank_account_code_prefix or ''
        for num in range(1, 100):
            new_code = str(account_code_prefix.ljust(code_digits - 1, '0')) + str(num)
            rec = self.env['account.account'].search([('code', '=', new_code), ('company_id', '=', company.id)], limit=1)
            if not rec:
                break
        else:
            raise UserError(_('Cannot generate an unused account code.'))

        liquidity_type = self.env.ref('account.data_account_type_liquidity')
        return {
                'name': name,
                'currency_id': currency_id or False,
                'code': new_code,
                'user_type_id': liquidity_type and liquidity_type.id or False,
                'company_id': company.id,
        }

    @api.model
    def create(self, vals):
        company_id = vals.get('company_id', self.env.user.company_id.id)
        if vals.get('type') in ('bank', 'cash'):
            # For convenience, the name can be inferred from account number
            if not vals.get('name') and 'bank_acc_number' in vals:
                vals['name'] = vals['bank_acc_number']

            # If no code provided, loop to find next available journal code
            if not vals.get('code'):
                journal_code_base = (vals['type'] == 'cash' and 'CSH' or 'BNK')
                journals = self.env['account.journal'].search([('code', 'like', journal_code_base + '%'), ('company_id', '=', company_id)])
                for num in range(1, 100):
                    # journal_code has a maximal size of 5, hence we can enforce the boundary num < 100
                    journal_code = journal_code_base + str(num)
                    if journal_code not in journals.mapped('code'):
                        vals['code'] = journal_code
                        break
                else:
                    raise UserError(_("Cannot generate an unused journal code. Please fill the 'Shortcode' field."))

            # Create a default debit/credit account if not given
            default_account = vals.get('default_debit_account_id') or vals.get('default_credit_account_id')
            if not default_account:
                company = self.env['res.company'].browse(company_id)
                account_vals = self._prepare_liquidity_account(vals.get('name'), company, vals.get('currency_id'), vals.get('type'))
                default_account = self.env['account.account'].create(account_vals)
                vals['default_debit_account_id'] = default_account.id
                vals['default_credit_account_id'] = default_account.id

        # We just need to create the relevant sequences according to the chosen options
        if not vals.get('sequence_id'):
            vals.update({'sequence_id': self.sudo()._create_sequence(vals).id})
        if vals.get('type') in ('sale', 'purchase') and vals.get('refund_sequence') and not vals.get('refund_sequence_id'):
            vals.update({'refund_sequence_id': self.sudo()._create_sequence(vals, refund=True).id})

        journal = super(AccountJournal, self).create(vals)

        # Create the bank_account_id if necessary
        if journal.type == 'bank' and not journal.bank_account_id and vals.get('bank_acc_number'):
            journal.set_bank_account(vals.get('bank_acc_number'), vals.get('bank_id'))

        return journal

    def set_bank_account(self, acc_number, bank_id=None):
        """ Create a res.partner.bank and set it as value of the  field bank_account_id """
        self.ensure_one()
        self.bank_account_id = self.env['res.partner.bank'].create({
            'acc_number': acc_number,
            'bank_id': bank_id,
            'company_id': self.company_id.id,
            'currency_id': self.currency_id.id,
            'partner_id': self.company_id.partner_id.id,
        }).id

    @api.multi
    @api.depends('name', 'currency_id', 'company_id', 'company_id.currency_id')
    def name_get(self):
        res = []
        for journal in self:
            currency = journal.currency_id or journal.company_id.currency_id
            name = "%s (%s)" % (journal.name, currency.name)
            res += [(journal.id, name)]
        return res

    @api.model
    def name_search(self, name='', args=None, operator='ilike', limit=100):
        args = args or []
        connector = '|'
        if operator in expression.NEGATIVE_TERM_OPERATORS:
            connector = '&'
        recs = self.search([connector, ('code', operator, name), ('name', operator, name)] + args, limit=limit)
        return recs.name_get()

    @api.multi
    @api.depends('company_id')
    def _belong_to_company(self):
        for journal in self:
            journal.belong_to_company = (journal.company_id.id == self.env.user.company_id.id)

    @api.multi
    def _search_company_journals(self, operator, value):
        if value:
            recs = self.search([('company_id', operator, self.env.user.company_id.id)])
        elif operator == '=':
            recs = self.search([('company_id', '!=', self.env.user.company_id.id)])
        else:
            recs = self.search([('company_id', operator, self.env.user.company_id.id)])
        return [('id', 'in', [x.id for x in recs])]

    @api.multi
    @api.depends('inbound_payment_method_ids', 'outbound_payment_method_ids')
    def _methods_compute(self):
        for journal in self:
            journal.at_least_one_inbound = bool(len(journal.inbound_payment_method_ids))
            journal.at_least_one_outbound = bool(len(journal.outbound_payment_method_ids))

    def setup_save_journal_and_create_more(self):
        """ This function is triggered by the button allowing to create more
        bank accounts, displayed in the "Bank Accounts" wizard of the setup bar.

        Button execution is done in Python, so that the model is validated and saved
        before executing the action.
        """
        return self.env.ref('account.action_account_bank_journal_form').read()[0]


class ResPartnerBank(models.Model):
    _inherit = "res.partner.bank"

    journal_id = fields.One2many('account.journal', 'bank_account_id', domain=[('type', '=', 'bank')], string='Account Journal', readonly=True,
        help="The accounting journal corresponding to this bank account.")

    @api.one
    @api.constrains('journal_id')
    def _check_journal_id(self):
        if len(self.journal_id) > 1:
            raise ValidationError(_('A bank account can only belong to one journal.'))


#----------------------------------------------------------
# Tax
#----------------------------------------------------------

class AccountTaxGroup(models.Model):
    _name = 'account.tax.group'
    _order = 'sequence asc'

    name = fields.Char(required=True, translate=True)
    sequence = fields.Integer(default=10)

class AccountTax(models.Model):
    _name = 'account.tax'
    _description = 'Tax'
    _order = 'sequence,id'

    @api.model
    def _default_tax_group(self):
        return self.env['account.tax.group'].search([], limit=1)

    name = fields.Char(string='Tax Name', required=True, translate=True)
    type_tax_use = fields.Selection([('sale', 'Sales'), ('purchase', 'Purchases'), ('none', 'None')], string='Tax Scope', required=True, default="sale",
        help="Determines where the tax is selectable. Note : 'None' means a tax can't be used by itself, however it can still be used in a group.")
    tax_adjustment = fields.Boolean(help='Set this field to true if this tax can be used in the tax adjustment wizard, used to manually fill some data in the tax declaration')
    amount_type = fields.Selection(default='percent', string="Tax Computation", required=True, oldname='type',
        selection=[('group', 'Group of Taxes'), ('fixed', 'Fixed'), ('percent', 'Percentage of Price'), ('division', 'Percentage of Price Tax Included')])
    active = fields.Boolean(default=True, help="Set active to false to hide the tax without removing it.")
    company_id = fields.Many2one('res.company', string='Company', required=True, default=lambda self: self.env.user.company_id)
    children_tax_ids = fields.Many2many('account.tax', 'account_tax_filiation_rel', 'parent_tax', 'child_tax', string='Children Taxes')
    sequence = fields.Integer(required=True, default=1,
        help="The sequence field is used to define order in which the tax lines are applied.")
    amount = fields.Float(required=True, digits=(16, 4))
    account_id = fields.Many2one('account.account', domain=[('deprecated', '=', False)], string='Tax Account', ondelete='restrict',
        help="Account that will be set on invoice tax lines for invoices. Leave empty to use the expense account.", oldname='account_collected_id')
    refund_account_id = fields.Many2one('account.account', domain=[('deprecated', '=', False)], string='Tax Account on Credit Notes', ondelete='restrict',
        help="Account that will be set on invoice tax lines for credit notes. Leave empty to use the expense account.", oldname='account_paid_id')
    description = fields.Char(string='Label on Invoices', translate=True)
    price_include = fields.Boolean(string='Included in Price', default=False,
        help="Check this if the price you use on the product and invoices includes this tax.")
    include_base_amount = fields.Boolean(string='Affect Base of Subsequent Taxes', default=False,
        help="If set, taxes which are computed after this one will be computed based on the price tax included.")
    analytic = fields.Boolean(string="Include in Analytic Cost", help="If set, the amount computed by this tax will be assigned to the same analytic account as the invoice line (if any)")
    tag_ids = fields.Many2many('account.account.tag', 'account_tax_account_tag', string='Tags', help="Optional tags you may want to assign for custom reporting")
    tax_group_id = fields.Many2one('account.tax.group', string="Tax Group", default=_default_tax_group, required=True)
    # Technical field to make the 'tax_exigibility' field invisible if the same named field is set to false in 'res.company' model
    hide_tax_exigibility = fields.Boolean(string='Hide Use Cash Basis Option', related='company_id.tax_exigibility')
    tax_exigibility = fields.Selection(
        [('on_invoice', 'Based on Invoice'),
         ('on_payment', 'Based on Payment'),
        ], string='Tax Due', default='on_invoice',
        oldname='use_cash_basis',
        help="Based on Invoice: the tax is due as soon as the invoice is validated.\n"
        "Based on Payment: the tax is due as soon as the payment of the invoice is received.")
    tax_type = fields.Selection(
        [('1', 'VAT'),
         ('2', 'TOT1'),
         ('3', 'TOT2'),
         ('4', 'Not Taxable'),
         ('5', 'Income Tax'),
         ('6', 'Withholding'),
         ('7', 'Dividend Tax '),
         ('8', 'Profit Tax'),
         ('9', 'Sur Tax'),
         ('10', 'Excise Tax ')
        ], string='Tax Type')
    cash_basis_account = fields.Many2one(
        'account.account',
        string='Tax Received Account',
        domain=[('deprecated', '=', False)],
        help='Account used as counterpart for the journal entry, for taxes eligible based on payments.')

    _sql_constraints = [
        ('name_company_uniq', 'unique(name, company_id, type_tax_use)', 'Tax names must be unique !'),
    ]

    @api.multi
    def unlink(self):
        company_id = self.env.user.company_id.id
        IrDefault = self.env['ir.default']
        taxes = self.browse(IrDefault.get('product.template', 'taxes_id', company_id=company_id) or [])
        if self & taxes:
            IrDefault.sudo().set('product.template', 'taxes_id', (taxes - self).ids, company_id=company_id)
        taxes = self.browse(IrDefault.get('product.template', 'supplier_taxes_id', company_id=company_id) or [])
        if self & taxes:
            IrDefault.sudo().set('product.template', 'supplier_taxes_id', (taxes - self).ids, company_id=company_id)
        return super(AccountTax, self).unlink()

    @api.one
    @api.constrains('children_tax_ids', 'type_tax_use')
    def _check_children_scope(self):
        if not all(child.type_tax_use in ('none', self.type_tax_use) for child in self.children_tax_ids):
            raise ValidationError(_('The application scope of taxes in a group must be either the same as the group or "None".'))

    @api.one
    @api.returns('self', lambda value: value.id)
    def copy(self, default=None):
        default = dict(default or {}, name=_("%s (Copy)") % self.name)
        return super(AccountTax, self).copy(default=default)

    @api.model
    def name_search(self, name, args=None, operator='ilike', limit=80):
        """ Returns a list of tupples containing id, name, as internally it is called {def name_get}
            result format: {[(id, name), (id, name), ...]}
        """
        args = args or []
        if operator in expression.NEGATIVE_TERM_OPERATORS:
            domain = [('description', operator, name), ('name', operator, name)]
        else:
            domain = ['|', ('description', operator, name), ('name', operator, name)]
        taxes = self.search(expression.AND([domain, args]), limit=limit)
        return taxes.name_get()

    @api.model
    def search(self, args, offset=0, limit=None, order=None, count=False):
        context = self._context or {}

        if context.get('type'):
            if context.get('type') in ('out_invoice', 'out_refund'):
                args += [('type_tax_use', '=', 'sale')]
            elif context.get('type') in ('in_invoice', 'in_refund'):
                args += [('type_tax_use', '=', 'purchase')]

        if context.get('journal_id'):
            journal = self.env['account.journal'].browse(context.get('journal_id'))
            if journal.type in ('sale', 'purchase'):
                args += [('type_tax_use', '=', journal.type)]

        return super(AccountTax, self).search(args, offset, limit, order, count=count)

    @api.onchange('amount')
    def onchange_amount(self):
        if self.amount_type in ('percent', 'division') and self.amount != 0.0 and not self.description:
            self.description = "{0:.4g}%".format(self.amount)

    @api.onchange('account_id')
    def onchange_account_id(self):
        self.refund_account_id = self.account_id

    @api.onchange('price_include')
    def onchange_price_include(self):
        if self.price_include:
            self.include_base_amount = True

    def get_grouping_key(self, invoice_tax_val):
        """ Returns a string that will be used to group account.invoice.tax sharing the same properties"""
        self.ensure_one()
        return str(invoice_tax_val['tax_id']) + '-' + str(invoice_tax_val['account_id']) + '-' + str(invoice_tax_val['account_analytic_id'])

    def _compute_amount(self, base_amount, price_unit, quantity=1.0, product=None, partner=None):
        """ Returns the amount of a single tax. base_amount is the actual amount on which the tax is applied, which is
            price_unit * quantity eventually affected by previous taxes (if tax is include_base_amount XOR price_include)
        """
        self.ensure_one()
        if self.amount_type == 'fixed':
            # Use copysign to take into account the sign of the base amount which includes the sign
            # of the quantity and the sign of the price_unit
            # Amount is the fixed price for the tax, it can be negative
            # Base amount included the sign of the quantity and the sign of the unit price and when
            # a product is returned, it can be done either by changing the sign of quantity or by changing the
            # sign of the price unit.
            # When the price unit is equal to 0, the sign of the quantity is absorbed in base_amount then
            # a "else" case is needed.
            if base_amount:
                return math.copysign(quantity, base_amount) * self.amount
            else:
                return quantity * self.amount
        if (self.amount_type == 'percent' and not self.price_include) or (self.amount_type == 'division' and self.price_include):
            return base_amount * self.amount / 100
        if self.amount_type == 'percent' and self.price_include:
            return base_amount - (base_amount / (1 + self.amount / 100))
        if self.amount_type == 'division' and not self.price_include:
            return base_amount / (1 - self.amount / 100) - base_amount

    @api.multi
    def json_friendly_compute_all(self, price_unit, currency_id=None, quantity=1.0, product_id=None, partner_id=None):
        """ Just converts parameters in browse records and calls for compute_all, because js widgets can't serialize browse records """
        if currency_id:
            currency_id = self.env['res.currency'].browse(currency_id)
        if product_id:
            product_id = self.env['product.product'].browse(product_id)
        if partner_id:
            partner_id = self.env['res.partner'].browse(partner_id)
        return self.compute_all(price_unit, currency=currency_id, quantity=quantity, product=product_id, partner=partner_id)

    @api.multi
    def compute_all(self, price_unit, currency=None, quantity=1.0, product=None, partner=None):
        """ Returns all information required to apply taxes (in self + their children in case of a tax goup).
            We consider the sequence of the parent for group of taxes.
                Eg. considering letters as taxes and alphabetic order as sequence :
                [G, B([A, D, F]), E, C] will be computed as [A, D, F, C, E, G]

        RETURN: {
            'total_excluded': 0.0,    # Total without taxes
            'total_included': 0.0,    # Total with taxes
            'taxes': [{               # One dict for each tax in self and their children
                'id': int,
                'name': str,
                'amount': float,
                'sequence': int,
                'account_id': int,
                'refund_account_id': int,
                'analytic': boolean,
            }]
        } """
        if len(self) == 0:
            company_id = self.env.user.company_id
        else:
            company_id = self[0].company_id 
        if not currency:
            currency = company_id.currency_id
        taxes = []
        # By default, for each tax, tax amount will first be computed
        # and rounded at the 'Account' decimal precision for each
        # PO/SO/invoice line and then these rounded amounts will be
        # summed, leading to the total amount for that tax. But, if the
        # company has tax_calculation_rounding_method = round_globally,
        # we still follow the same method, but we use a much larger
        # precision when we round the tax amount for each line (we use
        # the 'Account' decimal precision + 5), and that way it's like
        # rounding after the sum of the tax amounts of each line
        prec = currency.decimal_places

        # In some cases, it is necessary to force/prevent the rounding of the tax and the total
        # amounts. For example, in SO/PO line, we don't want to round the price unit at the
        # precision of the currency.
        # The context key 'round' allows to force the standard behavior.
        round_tax = False if company_id.tax_calculation_rounding_method == 'round_globally' else True
        round_total = True
        if 'round' in self.env.context:
            round_tax = bool(self.env.context['round'])
            round_total = bool(self.env.context['round'])

        if not round_tax:
            prec += 5

        base_values = self.env.context.get('base_values')
        if not base_values:
            total_excluded = total_included = base = round(price_unit * quantity, prec)
        else:
            total_excluded, total_included, base = base_values

        # Sorting key is mandatory in this case. When no key is provided, sorted() will perform a
        # search. However, the search method is overridden in account.tax in order to add a domain
        # depending on the context. This domain might filter out some taxes from self, e.g. in the
        # case of group taxes.
        for tax in self.sorted(key=lambda r: r.sequence):
            if tax.amount_type == 'group':
                children = tax.children_tax_ids.with_context(base_values=(total_excluded, total_included, base))
                ret = children.compute_all(price_unit, currency, quantity, product, partner)
                total_excluded = ret['total_excluded']
                base = ret['base'] if tax.include_base_amount else base
                total_included = ret['total_included']
                tax_amount = total_included - total_excluded
                taxes += ret['taxes']
                continue

            tax_amount = tax._compute_amount(base, price_unit, quantity, product, partner)
            if not round_tax:
                tax_amount = round(tax_amount, prec)
            else:
                tax_amount = currency.round(tax_amount)

            if tax.price_include:
                total_excluded -= tax_amount
                base -= tax_amount
            else:
                total_included += tax_amount

            # Keep base amount used for the current tax
            tax_base = base

            if tax.include_base_amount:
                base += tax_amount

            taxes.append({
                'id': tax.id,
                'name': tax.with_context(**{'lang': partner.lang} if partner else {}).name,
                'amount': tax_amount,
                'base': tax_base,
                'sequence': tax.sequence,
                'account_id': tax.account_id.id,
                'refund_account_id': tax.refund_account_id.id,
                'analytic': tax.analytic,
                'price_include': tax.price_include,
            })

        return {
            'taxes': sorted(taxes, key=lambda k: k['sequence']),
            'total_excluded': currency.round(total_excluded) if round_total else total_excluded,
            'total_included': currency.round(total_included) if round_total else total_included,
            'base': base,
        }

    @api.model
    def _fix_tax_included_price(self, price, prod_taxes, line_taxes):
        """Subtract tax amount from price when corresponding "price included" taxes do not apply"""
        # FIXME get currency in param?
        incl_tax = prod_taxes.filtered(lambda tax: tax not in line_taxes and tax.price_include)
        if incl_tax:
            return incl_tax.compute_all(price)['total_excluded']
        return price

    @api.model
    def _fix_tax_included_price_company(self, price, prod_taxes, line_taxes, company_id):
        if company_id:
            #To keep the same behavior as in _compute_tax_id
            prod_taxes = prod_taxes.filtered(lambda tax: tax.company_id == company_id)
            line_taxes = line_taxes.filtered(lambda tax: tax.company_id == company_id)
        return self._fix_tax_included_price(price, prod_taxes, line_taxes)


class AccountReconcileModel(models.Model):
    _name = "account.reconcile.model"
    _description = "Preset to create journal entries during a invoices and payments matching"

    name = fields.Char(string='Button Label', required=True)
    sequence = fields.Integer(required=True, default=10)
    has_second_line = fields.Boolean(string='Add a second line', default=False)
    company_id = fields.Many2one('res.company', string='Company', required=True, default=lambda self: self.env.user.company_id)

    account_id = fields.Many2one('account.account', string='Account', ondelete='cascade', domain=[('deprecated', '=', False)])
    journal_id = fields.Many2one('account.journal', string='Journal', ondelete='cascade', help="This field is ignored in a bank statement reconciliation.")
    label = fields.Char(string='Journal Item Label')
    amount_type = fields.Selection([
        ('fixed', 'Fixed'),
        ('percentage', 'Percentage of balance')
        ], required=True, default='percentage')
    amount = fields.Float(digits=0, required=True, default=100.0, help="Fixed amount will count as a debit if it is negative, as a credit if it is positive.")
    tax_id = fields.Many2one('account.tax', string='Tax', ondelete='restrict')
    analytic_account_id = fields.Many2one('account.analytic.account', string='Analytic Account', ondelete='set null')

    second_account_id = fields.Many2one('account.account', string='Second Account', ondelete='cascade', domain=[('deprecated', '=', False)])
    second_journal_id = fields.Many2one('account.journal', string='Second Journal', ondelete='cascade', help="This field is ignored in a bank statement reconciliation.")
    second_label = fields.Char(string='Second Journal Item Label')
    second_amount_type = fields.Selection([
        ('fixed', 'Fixed'),
        ('percentage', 'Percentage of amount')
        ], string="Second Amount type",required=True, default='percentage')
    second_amount = fields.Float(string='Second Amount', digits=0, required=True, default=100.0, help="Fixed amount will count as a debit if it is negative, as a credit if it is positive.")
    second_tax_id = fields.Many2one('account.tax', string='Second Tax', ondelete='restrict', domain=[('type_tax_use', '=', 'purchase')])
    second_analytic_account_id = fields.Many2one('account.analytic.account', string='Second Analytic Account', ondelete='set null')

    @api.onchange('name')
    def onchange_name(self):
        self.label = self.name

class CostCategory(models.Model):
    _name = 'cost.category'
    
    name = fields.Char('Name', required=True)
    description = fields.Text('Description')

class AccountPeriod(models.Model):
    _name = 'accounting.period'
    
    name = fields.Char('Budget Year', required=True)
    start_date = fields.Date('From')
    end_date = fields.Date('To')
    period = fields.Integer('Period',default=12)
    period_line = fields.One2many('accounting.period.list', 'period_id', string='Periods', copy=True)
    leave_state= fields.Char(default="draft")
    @api.onchange('period')
    def onchange_period(self):
        period = self.period
        terms = []
        for x in range(1, period):  
            values = {}
            values['period_no'] = x
            terms.append((0, 0, values))
        self.period_line=terms
        return 
    
class AccountPeriodList(models.Model):
    _name = 'accounting.period.list'
    
    period_no = fields.Integer('Period', required=True) 
    start_date = fields.Date('From')
    end_date = fields.Date('To')
    period_id = fields.Many2one('accounting.period', string='Period Reference',index=True, ondelete='cascade')
class BankDeposit(models.Model):
    _name = 'bank.deposit'

    _inherit = ['mail.thread', 'resource.mixin']
    _mail_post_access = 'read'
    employee = fields.Many2one('hr.employee', string='Employee' )
    # bank = fields.Many2one('bank.detail', string='Bank Name', required=True) 
    bank = fields.Many2one('account.journal', string='Bank Name', required=True) 
    name = fields.Text('Name',required=True)
    reason = fields.Text('Reason')
    amount = fields.Float('Amount', required=True) 
    date = fields.Date('Date')
    partner = fields.Many2one('res.partner', string='Partner')
    # journal = fields.Selection([('bank', 'Bank'), ('cash', 'Cash')],string='Journal')

    state = fields.Selection([('draft', 'Draft'), ('approved', 'Approved'), ('posted', 'Posted')],
     string='Status', required=True, readonly=True, copy=False, default='draft')
    
    @api.multi
    def action_follow(self):
        """ Wrapper because message_subscribe_users take a user_ids=None
            that receive the context without the wrapper.
        """
        return self.message_subscribe_users()

    @api.multi
    def action_unfollow(self):
        """ Wrapper because message_unsubscribe_users take a user_ids=None
            that receive the context without the wrapper.
        """
        return self.message_unsubscribe_users()

    @api.model
    def _message_get_auto_subscribe_fields(self, updated_fields, auto_follow_fields=None):
        """ Overwrite of the original method to always follow user_id field,
            even when not track_visibility so that a user will follow it's employee
        """
        if auto_follow_fields is None:
            auto_follow_fields = ['user_id']
        user_field_lst = []
        for name, field in self._fields.items():
            if name in auto_follow_fields and name in updated_fields and field.comodel_name == 'res.users':
                user_field_lst.append(name)
        return user_field_lst

    @api.multi
    def _message_auto_subscribe_notify(self, partner_ids):
        # Do not notify user it has been marked as follower of its employee.
        return

    @api.multi
    def approve_deposit(self):
        _logger.info('-------!!!!!!!!click on approve')
        return {
                    'name':'Approve',
                    'view_type':'form',
                    'view_mode':'form',
                    'res_model':'bank.deposit.approve',
                    'type':'ir.actions.act_window',
                    'target':'new',
                }
    @api.multi
    def create_jornal(self):
        _logger.info('-------!!!!!!!!click on approve')
        return {
                    'name':'Approve',
                    'view_type':'form',
                    'view_mode':'form',
                    'res_model':'bank.deposit.create.journal',
                    'type':'ir.actions.act_window',
                    'target':'new',
                }
class ApproveBankDeposit(models.Model):
    _name = 'bank.deposit.approve'
    @api.multi
    def yes(self, context):
        id=context.get('active_id')
        clause_final = [('id', '=', id)]
        search_results= self.env['bank.deposit'].search(clause_final).ids
        vals={}
        if search_results:
            for search_result in self.env['bank.deposit'].browse(search_results):
                # user_id=self.env['res.users'].search([('id', '=', self.env.uid)], limit=1).id
                search_result.message_post( body='<p><b> Bank deposit Approved</p>')
                
                search_result.write({'state': 'approved'})
               
            return {'type': 'ir.actions.act_window_close','tag': 'reload',}
    @api.multi
    def no(self):
        pass 
class CreatejournalBankDeposit(models.Model):
    _name = 'bank.deposit.create.journal'

    @api.multi
    def yes(self, context):
        res=[]
        
        id=context.get('active_id')
        clause_final = [('id', '=', id)]
        search_results= self.env['bank.deposit'].search(clause_final).ids
        vals={}
        date=None
        partner=""
        amount=0
        bank=""
        date=""
        if search_results:
            for search_result in self.env['bank.deposit'].browse(search_results):
                # user_id=self.env['res.users'].search([('id', '=', self.env.uid)], limit=1).id
                
                search_result.message_post( body='<p><b> Journal created for Bank deposit </p>')
                date=search_result.date
                partner=search_result.partner
                amount=search_result.amount
                date=search_result.date
                bank=search_result.bank
                search_result.write({'state': 'posted'})
               
            # account_search_results= self.env['account.journal'].search([('type', '=', search_result.journal)]).id
            _logger.info('-------!!!!!!!!DATE=%s',date)
            _logger.info('-------!!!!!!!!click on account_search_results=%s',search_result.bank)
            ref="BKDP/"
            refid=str(search_result.id)
            refVal=ref+refid
            _logger.info('-------!!!!!!!!refVal=%s',refVal)
            _logger.info('-------!!!!!!!!refVal=%s',refVal)
            if search_result.employee:
                
                account_recievable_account_id=0
                if search_results:
                    resource_id= self.env['hr.employee'].search( [('id', '=', search_result.employee.id)]).resource_id
                    # res_resource_id= self.env['resource.resource'].search( [('id', '=', resource_id.id)]).user_id
                    # partner= self.env['res.users'].search( [('id', '=', res_resource_id.id)]).partner_id
                    # account_id= self.env['res.partner'].search( [('id', '=', partner.id)]).property_account_receivable_id
                    res_configs = self.env['res.config.settings'].search([]).ids
                    
                    _logger.info('-------!!!!!!!!click on res_config=%s',res_configs)
                    if res_configs:
                        for res_config in self.env['res.config.settings'].browse(res_configs):
                            _logger.info('-------!!!!!!!!click on res_config=%s',res_config)
                            account_recievable_account_id=res_config.account_recievable_account_id.id
                            _logger.info('-------!!!!!!!!click on account_recievable_account_id=%s',account_recievable_account_id)
                    first_line_dict = self._prepare_writeoff_first_line_values_id(search_result.amount,account_recievable_account_id,refVal)
                    # first_line_dict = self._prepare_writeoff_first_line_values(search_result.amount,account_id)
                    _logger.info('-------!!!!!!!first_line_dict=%s',first_line_dict)
                    res.append((0, 0, first_line_dict))
            elif search_result.partner:
                # account_id= self.env['res.partner'].search( [('id', '=', search_result.partner.id)]).property_account_receivable_id
                account_id= self.env['res.partner'].search( [('id', '=', search_result.partner.id)]).pre_payment_account_id
                    
                first_line_dict = self._prepare_writeoff_first_line_values(search_result.amount,account_id,refVal)
                _logger.info('-------!!!!!!!first_line_dict=%s',first_line_dict)
                res.append((0, 0, first_line_dict))
            # Writeoff line in specified writeoff account
            _logger.info('-------!!!!!!!$$$$$$$$search_result.bank=%s',search_result.bank)
            _logger.info('-------!!!!!!!$$$$$$$$search_result.bank=%s',search_result.bank.default_debit_account_id)
            second_line_dict = self._prepare_writeoff_second_line_values(search_result.amount,search_result.bank,refVal)
            res.append((0, 0, second_line_dict))
            vals={
                
                'name':ref+refid,
                'ref':ref+refid,
                'amount_val':search_result.amount,
                'date':date,
                'journal_id':search_result.bank.id,
                'employee_id':search_result.employee.id,
                'partner':search_result.partner.id,
                'case':'deposit',
                'main_id':refid,
                'line_ids':res
                }

            req=self.env['account.move'].create(vals)

            
            # sales_configs= self.env['res.config.settings'].search([], order='id desc',limit=1).ids
            # OUTPUT_DIR=""
            # if sales_configs:
            #     for sales_config in self.env['res.config.settings'].browse(sales_configs):
            #         xml_file_location=sales_config.xml_drop_location_customer_sms
            #         if xml_file_location:
            #             _logger.info('-------!!!!!!!!Start creating xml=%s',xml_file_location)
                        
            #             # OUTPUT_DIR = "C:\\Users\\Queen\\Documents\\odoo-backup\\sampleXML\\test1.xml"
            #             OUTPUT_DIR =xml_file_location
            #         else:
            #             raise UserError(_('Please insert xml file path on sales configuration.'))
            # _logger.info('-------!!!!!!!!Start partner- =%s',str(partner))
            # name='BKDP-'+ str(partner.name)
            # now = datetime.today().strftime('%y%m%d%H%M%S')
            # _logger.info('-------!!!!!!!!Start date =%s',now)
            # OUTPUT_DIR =os.path.join(OUTPUT_DIR,str(name)+str(now)+str(".xml"))
            # # OUTPUT_DIR =os.path.join(OUTPUT_DIR,str("2019-01-23-14-48-48.xml"))
            # # OUTPUT_DIR=str(OUTPUT_DIR)+ str("\\\\")+str(now)+str(".xml")
            # _logger.info('-------!!!!!!!!Start OUTPUT_DIR- =%s',OUTPUT_DIR)
            
            # root = minidom.Document()
            # # root2 = minidom.Document()

            # xml = root.createElement('BankDeposit')
            # root.appendChild(xml)

            # second_root=root.createElement('item')

            # xml.appendChild(second_root)
            
            # childOfproduct = root.createElement('partner_id')
            # childOfproduct.appendChild(root.createTextNode(str(partner.id)))
            # second_root.appendChild(childOfproduct)

            # childOfproduct = root.createElement('partner_name')
            # childOfproduct.appendChild(root.createTextNode(partner.name))
            # second_root.appendChild(childOfproduct)


            # childOfproduct = root.createElement('bank')
            # childOfproduct.appendChild(root.createTextNode(bank.name))
            # second_root.appendChild(childOfproduct)
            # childOfproduct = root.createElement('amount')
            # childOfproduct.appendChild(root.createTextNode(str(amount)))
            # second_root.appendChild(childOfproduct)
            # childOfproduct = root.createElement('date')
            # childOfproduct.appendChild(root.createTextNode(str(date)))
            # second_root.appendChild(childOfproduct)

            # childOfproduct = root.createElement('current_balance')
            # childOfproduct.appendChild(root.createTextNode(self.partner_id.current_balance))
            # second_root.appendChild(childOfproduct)
           
            # xml_str = root.toprettyxml(indent="\t")

            # # save_path_file = "test2.xml"
            # # OUTPUT_DIR.replace("/", "\\")
            # _logger.info('-------!!!!!!!!Start xml_str******* =%s',xml_str)
            # with open(OUTPUT_DIR, "w+") as f:
            #     f.write(xml_str)
            # _logger.info('-------!!!!!!!!Start OUTPUT_DIR******* =%s',OUTPUT_DIR)
        
            return {'type': 'ir.actions.act_window_close','tag': 'reload',}
    @api.multi
    def _prepare_writeoff_first_line_values(self, amount,account_id,refVal):
        line_values={}
        line_values['credit'] = amount
        line_values['account_id'] = account_id.id
        line_values['ref'] = refVal
        
        return line_values
    @api.multi
    def _prepare_writeoff_first_line_values_id(self, amount,account_id,refVal):
        line_values={}
        line_values['credit'] = amount
        line_values['account_id'] = account_id
        line_values['ref'] = refVal
        
        return line_values
    

    @api.multi
    def _prepare_writeoff_second_line_values(self,  amount,account_id,refVal):
        line_values={}
        line_values['debit'] = amount
        line_values['account_id'] = account_id.default_debit_account_id.id
        line_values['ref'] = refVal
        return line_values

    @api.multi
    def no(self):
        pass 
# class accountAutoReconcilationMoveLine(models.Model):
#     _name = 'reconciled.account.move.list'
#     # def _set_sum(self):
#     #     for result in self:
#     #         if result.selected_option==True:
#     #             if result.debit>0:
#     #                 result.sum  = result.sum  + debit
#     #             elif result.credit>0:
#     #                 result.sum  = result.sum  + credit
#     check = fields.Boolean(string='Check',default=False)
    
#     debit = fields.Float( currency_field='company_currency_id' )
#     credit = fields.Float( currency_field='company_currency_id')
#     reconcile_line = fields.Many2one('account.bank.statement.line.reconcile', string='Bank Statment',index=True, ondelete='cascade', readonly=True )
    
#     name = fields.Char(string="Label")
#     ref = fields.Char(string='Reference', store=True, copy=False, index=True)
#     move_line_id = fields.Many2one('account.move.line', string='Journal Entry')
#     account_id = fields.Many2one('account.account', string='Account', required=True, index=True)
#     selected_option = fields.Boolean(compute='check_value', string='Selected')
#     sum = fields.Float(string="summary", store=True)
class accountAutoReconcilationMoveLine(models.Model):
    _name = 'reconcile.account.move.line'
    # def _set_sum(self):
    #     for result in self:
    #         if result.selected_option==True:
    #             if result.debit>0:
    #                 result.sum  = result.sum  + debit
    #             elif result.credit>0:
    #                 result.sum  = result.sum  + credit
    check = fields.Boolean(string='Check',default=False)
    
    
    amount = fields.Float( currency_field='company_currency_id' )
    debit = fields.Float( currency_field='company_currency_id' )
    credit = fields.Float( currency_field='company_currency_id')
    reconcile_line = fields.Many2one('account.bank.statement.line.reconcile', string='Bank Statment',index=True, ondelete='cascade', readonly=True )
    
    name = fields.Char(string="Label")
    ref = fields.Char(string='Reference', store=True, copy=False, index=True)
    move_line_id = fields.Many2one('account.move.line', string='Journal Entry')
    account_id = fields.Many2one('account.account', string='Account', required=True, index=True)
    selected_option = fields.Boolean(compute='check_value', string='Selected')
    sum = fields.Float(string="summary", store=True)
    payment_document = fields.Char(string='Payment Document', copy=False)
    date = fields.Date(string="date")

    @api.multi 
    def check_value(self):
        for result in self:
            if result.check == True:
                result.selected_option = True
            result.selected_option = False
    # @api.model
    # def write(self, vals):
        # _logger.info('-------!!!!!!!$update function%s',vals)
        # selected_option=vals.get('check')
        # if selected_option==True:
        #     debit=vals.get('debit')
        #     credit=vals.get('credit')
        #     if not debit:
        #         debit=self.debit
        #     if not credit:
        #         credit=self.credit
        #     sumval=vals.get('sum')
        #     if not sumval:
        #         sumval=self.sum
        #     if debit>0:
        #         vals['sum'] =sumval  + debit
        #     elif credit>0:
        #        vals['sum']  =sumval  + credit
        #     _logger.info('-------!!!!!!!$update function%s',vals)
        #     return super(accountAutoReconcilationMoveLine, self).write(vals)

        # selected_option=self.selected_option
        # _logger.info('-------!!!!!!---------------------selected_option=%s',selected_option)
        # _logger.info('-------!!!!!!---------------------selected_option=%s',self.check)
        # if selected_option==True:
        #     debit=self.debit
        #     credit=self.credit
        #     _logger.info('-------!!!!!!---------------------debit=%s',debit)
        #     _logger.info('-------!!!!!!---------------------credit=%s',credit)
        
        #     sum=self.sum
        #     if debit>0:
        #         vals['sum'] =sum  + debit
        #     elif credit>0:
        #        vals['sum']  =sum  + credit
        # _logger.info('-------!!!!!!---------------------vvals=%s',vals)
            
    # @api.model
    # def create(self, vals):
    #     _logger.info('-------!!!!!!!$vals===%s',vals)
    #     # if vals.get('check'):
    #     if vals.get('sum')==vals.get('amount'):
            
    #         _logger.info('-------!!!!!!!$canReconcile===%s',self.canReconcile)
    #     selected_option=vals.get('selected_option')

    #     if selected_option == True:
    #         move= super(accountAutoReconcilationMoveLine, self).create(vals)
    #         return move
#       
    #     _logger.info('reconcile.account.move.line')
    #     _logger.info('reconcile.account.move.line=======vals=%s',vals)
    #     if 'selected_option' in vals:
    #         selected_option=vals.get('selected_option')
    #         if selected_option == True:
    #             move= super(accountAutoReconcilationLine, self).create(result)
    #             return move

    @api.onchange('check')
    def onchangecheck(self):
        if self.check:
            _logger.info('-------!!!!!!!$onChange OF amount%s',self.amount)
            _logger.info('-------!!!!!!!$onChange OF CHEKED%s',self.sum)
            _logger.info('-------!!!!!!!$onChange OF CHEKED%s',self.debit)
            _logger.info('-------!!!!!!!$onChange OF CHEKED%s',self.credit)
            if self.debit >0:
                self.sum=self.sum +self.debit
            if self.credit >0:
                self.sum=self.sum +self.credit
            # if self.sum== self.amount:
            #     self.canReconcile=True
            #     _logger.info('-------!!!!!!!$canReconcile===%s',self.canReconcile)
        if not self.check:
            if self.debit >0:
                self.sum=self.sum - self.debit
            if self.credit >0:
                self.sum=self.sum - self.credit
class accountAutoReconcilationLine(models.Model):
    _name = 'account.bank.statement.line.reconcile'
    auto_reconcile_id = fields.Many2one('account.auto.reconcile', string='Bank Statment',index=True, ondelete='cascade', readonly=True )
    # bank_statment_line = fields.One2many('account.bank.statement.line.reconcile', 'auto_reconcile_id', string='Periods', copy=True)
    name = fields.Char(string='Label')
    date = fields.Date(string='Date')
    account_id = fields.Many2one('account.account', string='Counterpart Account')
    journal = fields.Many2one('account.journal', string=' Account Journal',index=True)
    ref = fields.Char(string='Reference')
    statment_line_id = fields.Many2one('account.bank.statement.line', string='Statment line',index=True)
    Reconcile = fields.Boolean(string='reconcile',default=False)
    listed = fields.Boolean(string='listed',default=False)
    status = fields.Char(string='Status')
    # account_move_line = fields.One2many('account.move.line', 'move_id',string='Bank Statment' )
    account_move_line = fields.One2many('reconcile.account.move.line','reconcile_line',string='Bank Statment')
    amount = fields.Float(string='Amount')
    
    # reconciled_line_id = fields.One2many('reconciled.account.move.list','reconcile_line',string='Reconciled')
    
    @api.onchange('amount')
    def reconcile(self):
        _logger.info('-------Reconcile Here')
        _logger.info('-------Reconcile Here---------%s',self.id)
        _logger.info('-------bank_statment Here---------%s',self.auto_reconcile_id.bank_statment)
        _logger.info('-------bank_statment bank_statment_line---------%s',self.statment_line_id)
        
        clause_final = ['&',('check', '=', True),('reconcile_line','=',self.id)]
        search_results= self.env['reconcile.account.move.line'].search(clause_final).ids
        _logger.info('-------bank_statment search_results---------%s',search_results)
        
        if search_results:
            for search_result in self.env['reconcile.account.move.line'].browse(search_results):
                _logger.info('-------bank_statment search_result---------%s',search_result)
                move_line_id=search_result.move_line_id
                sum=search_result.sum
                amount=search_result.amount
                _logger.info('-------bank_statment sum---------%s',sum)
                _logger.info('-------bank_statment amount---------%s',amount)
                if amount == sum:
                    bank_statment=self.auto_reconcile_id.bank_statment.id
                    _logger.info('-------bank_statment bank_statment---------%s',bank_statment)
                    if bank_statment:
                        bank_statment_line=self.statment_line_id
                        # move_line_id=self.auto_reconcile_id.bank_statment_line.account_move_line.move_line_id
                        _logger.info('-------Reconcile move_line_id---------%s',move_line_id)
                        # clause_final_move_line = [('statement_id', '=', move_line_id.id)]
                        # search_results_move_line= self.env['account.move.line'].search(clause_final_move_line).ids
                    
                        _logger.info('-------Reconcile bank_statment---------%s',bank_statment)
                        _logger.info('-------Reconcile bank_statment_line---------%s',bank_statment_line)
                        clause_final_move_line = [('id', '=', move_line_id.id)]
                        search_results_move_line= self.env['account.move.line'].search(clause_final_move_line).ids
                    
                        if search_results_move_line:
                            for search_result_move_line in self.env['account.move.line'].browse(search_results_move_line):
                                search_result_move_line.write({"reconciled":True,"statement_line_id":bank_statment_line.id,"statement_id":bank_statment})
                                self.Reconcile=True
                                self.status="Reconciled"
                
                else:
                    raise ValidationError(_('You cannot reconcile unbalanced amount.') )
        else:
            raise ValidationError(_('Please Check matched transaction first.') )



                  

    def clear(self):
        clause_final = [('reconcile_line','=',self.id)]
        search_results= self.env['reconcile.account.move.line'].search(clause_final).ids
        _logger.info('-------bank_statment search_results---------%s',search_results)
        
        if search_results:
            for search_result in self.env['reconcile.account.move.line'].browse(search_results):
                search_result.unlink()
            self.listed=False
    def listJournals(self,currency=None):
        journal_id=self.journal
        _logger.info('-------!!!!!!!$journal_id=%s',journal_id)
        _logger.info('-------!!!!!!!$self.amount=%s',self.amount)
        _logger.info('-------!!!!!!!$self.statment_line_id=%s',self.statment_line_id)
        default_debit_account_id= self.env['account.journal'].search([('id', '=',journal_id.id)]).default_debit_account_id
        default_credit_account_id= self.env['account.journal'].search([('id', '=',journal_id.id)]).default_credit_account_id
        
        _logger.info('-------!!!!!!!$default_credit_account_id=%s',default_credit_account_id)
        _logger.info('-------!!!!!!!$default_credit_account_id=%s',default_credit_account_id)
        terms2 = []
        statement_id= self.env['account.bank.statement.line'].search([('id', '=',self.statment_line_id.id)]).statement_id
        _logger.info('@@@@@@@@@@@@@ ---------- statement_id= = %s',statement_id)
        statment_last_date=statement_id.last_date
        current_date1 = statment_last_date
        _logger.info('@@@@@@@@@@@@@ ---------- current_date1= = %s',current_date1)
        current_date=datetime.strptime(current_date1, '%Y-%m-%d')
        _logger.info(' ---------- current_date= = %s',current_date)
        first_date=current_date
        last_date=current_date
        # current_quarter = round((current_date.month - 1) / 3 + 1,prec)
        current_quarter =round((current_date.month - 1) / 3 + 1)
        _logger.info(' ---------- current_quarter= = %s',current_quarter)
        year=current_date.year
        if(current_date.month==1):
            _logger.info(' ---------- month one')
            year=current_date.year -1
            first_date = datetime(year, 12 , 20)
            _logger.info(' ---------- first_date= = %s',first_date)
        if(current_date.month==1):
            _logger.info(' ---------- month 44one')
            last_date = datetime(current_date.year, 3 * current_quarter - 1, 1) + timedelta(days=-1)
            _logger.info(' ---------- last_date= = %s',last_date)
        else:
            _logger.info(' ---------- month two')
            first_date = datetime(current_date.year, 3 * current_quarter - 3, 20)
            _logger.info(' ---------- first_date= = %s',first_date)
            last_date = datetime(current_date.year, 3 * current_quarter - 1, 1) + timedelta(days=-1)
            _logger.info(' ---------- last_date= = %s',last_date)
        if self.amount >0:
            account_moves= self.env['account.move'].search(['&',('date','>=',first_date),('date','<=',last_date)]).ids
        
            clause_final_statment = ['&','&','&',('debit', '<=', self.amount),("reconciled","=",False),('account_id', '=', default_debit_account_id.id),('date','>=',first_date),('date','<=',last_date)]
        elif  self.amount < 0:
            clause_final_statment = ['&','&','&',('credit', '<=', abs(self.amount)),("reconciled","=",False),('account_id', '=', default_credit_account_id.id),('date','>=',first_date),('date','<=',last_date)]
        _logger.info('-------!!!!!!!$clause_final_statment=%s',clause_final_statment)
        is_exist=False
        if self.amount:
            search_results_statment= self.env['account.move.line'].search(clause_final_statment).ids
            _logger.info('-------!!!!!!!$search_results_statment=%s',search_results_statment)
            if search_results_statment:
                for search_result_statment in self.env['account.move.line'].browse(search_results_statment):
                    _logger.info('-------!!!!!!!$search_result_statment=%s',search_result_statment)
                    _logger.info('-------!!!!!!!$move_id=%s',search_result_statment.move_id)
                    _logger.info('-------!!!!!!!$state=%s',search_result_statment.move_id.state)
            
                    if search_result_statment.move_id.state =="posted":
                        
                        payment_document= self.env['account.move'].search([('id', '=',search_result_statment.move_id.id)]).payment_document
        
                        values2 = {}
                        values2['date'] = search_result_statment.date
                        values2['account_id'] = search_result_statment.account_id.id
                        values2['ref'] = search_result_statment.ref
                        values2['name'] = search_result_statment.name
                        values2['move_line_id'] = search_result_statment.id
                        values2['date'] = search_result_statment.date
                        values2['payment_document'] = payment_document
                        values2['amount'] =abs(self.amount)
                        
                        if self.amount >0:
                            is_exist=True
                            values2['debit'] = search_result_statment.debit
                            if search_result_statment.debit >0:
                                terms2.append((0, 0, values2))
                        elif  self.amount <0:
                            is_exist=True
                            values2['credit'] = search_result_statment.credit
                            if search_result_statment.credit>0:
                                terms2.append((0, 0, values2))
                    # values2['account_move_line'] = terms2
                _logger.info('-------!!!!!!!$terms2=%s',terms2)
                _logger.info('-------!!!!!!!$is_exist=%s',is_exist)
                self.account_move_line=terms2
                if is_exist:
                    self.listed=True
class accountAutoReconcilation(models.Model):
    _name = 'account.auto.reconcile'
    bank_statment = fields.Many2one('account.bank.statement', string='Bank Statment' )
    bank_statment_line = fields.One2many('account.bank.statement.line.reconcile', 'auto_reconcile_id', string='Periods')
    validate = fields.Boolean(string='validate',default=False)
    @api.onchange('bank_statment')
    def onchange_bank_statment(self):
        if self.bank_statment:
            bank_statment = self.bank_statment
            _logger.info('-------!!!!!!!!bank_statment=%s',bank_statment)
            terms = []
            clause_final = [('statement_id', '=', bank_statment.id)]
            search_results= self.env['account.bank.statement.line'].search(clause_final).ids
        
            if search_results:
                for search_result in self.env['account.bank.statement.line'].browse(search_results):
                
                    values = {}
                    values['date'] = search_result.date
                    values['account_id'] = search_result.account_id
                    values['ref'] = search_result.ref
                    values['name'] = search_result.name
                    values['amount'] = search_result.amount
                    values['statment_line_id'] = search_result.id
                    values['status'] ='Draft' 
                    
                    
                    journal_id=search_result.journal_id
                    values['journal'] = search_result.journal_id.id
                    
                    


                    # # journal_id=self.journal
                    _logger.info('************-------!!!!!!!$journal_id=%s',journal_id)
                    # # _logger.info('-------!!!!!!!$self.amount=%s',self.amount)
                    # default_debit_account_id= self.env['account.journal'].search([('id', '=',journal_id.id)]).default_debit_account_id
                    # default_credit_account_id= self.env['account.journal'].search([('id', '=',journal_id.id)]).default_credit_account_id
                    
                    # _logger.info('-------!!!!!!!$default_credit_account_id=%s',default_credit_account_id)
                    # _logger.info('-------!!!!!!!$default_credit_account_id=%s',default_credit_account_id)
                    # terms2 = []
                    # if search_result.amount >0:
                    #     clause_final_statment = ['&',('debit', '<=', search_result.amount),('account_id', '=', default_debit_account_id.id)]
                    # elif  search_result.amount < 0:
                    #     clause_final_statment = ['&',('credit', '<=', search_result.amount),('account_id', '=', default_credit_account_id.id)]
                    
                    # if search_result.amount>0:
                    #     search_results_statment= self.env['account.move.line'].search(clause_final_statment).ids
                    #     _logger.info('!!!-------!!!!!!!$search_results_statment=%s',search_results_statment)
                    #     if search_results_statment:
                    #         for search_result_statment in self.env['account.move.line'].browse(search_results_statment):
                    
                        

                    #             values2 = {}
                    #             values2['date'] = search_result_statment.date
                    #             values2['account_id'] = search_result_statment.account_id.id
                    #             values2['ref'] = search_result_statment.ref
                    #             values2['name'] = search_result_statment.name
                    #             values2['move_line_id'] = search_result_statment.id
                    #             if search_result.amount >0:
                    #                 values2['debit'] = search_result_statment.debit
                    #             elif  search_result.amount <0:
                    #                 values2['credit'] = search_result_statment.credit
                    #             terms2.append((0, 0, values2))
                    #             values['account_move_line'] = terms2
                    _logger.info('-------!!!!!!!$values=%s',values)
                    terms.append((0, 0, values))
                    # self.account_move_line=terms2
            self.bank_statment_line=terms
        return 
    
    @api.multi
    def reconcile(self):
        _logger.info('-------!!!!!!Button Clicked')
        return {
            #'name': self.order_id,
            'res_model': 'account.bank.statement.line.reconcile',
            'type': 'ir.actions.act_window',
            'context': {},
            'view_mode': 'form',
            'view_type': 'form',
            'view_id': self.env.ref("reconcile_form").id,
            'target': 'new'
        }
    @api.multi
    def validate_statment(self):
        clause_final = [('id', '=', self.bank_statment.id)]
        search_results= self.env['account.bank.statement'].search(clause_final).ids
    
        if search_results:
            for search_result in self.env['account.bank.statement'].browse(search_results):
                search_result.write({"state":"confirm"})
            self.validate=True
class accountAutoDetailReconcilation(models.Model):
    _name = 'account.auto.reconcile.detail'
    account_move_line = fields.Many2one('account.move.line', string='Bank Statment' )
    