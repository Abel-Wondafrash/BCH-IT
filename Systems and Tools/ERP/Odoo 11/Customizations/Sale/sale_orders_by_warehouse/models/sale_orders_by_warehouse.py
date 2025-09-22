from odoo import models, fields, api
from xml.dom import minidom
import os
import socket
from datetime import datetime

class SaleOrder(models.Model):
    _inherit = 'sale.order'

    loj_parcel_batch_id = fields.Many2one('loj.parcel.batch', string="LOJ Parcel Batch")
    loj_warehouse_id = fields.Many2one(
        'stock.warehouse',
        string='Warehouse (Mirror)',
        related='warehouse_id',
        store=True,
        readonly=True,
    )

    @api.depends('picking_ids.picking_type_id.warehouse_id')
    def _compute_warehouse(self):
        for order in self:
            if order.picking_ids:
                # Just take the warehouse of the first picking (usually there’s only one)
                order.warehouse_id = order.picking_ids[0].picking_type_id.warehouse_id.id
            else:
                order.warehouse_id = False

class LojParcelBatch(models.Model):
    _name = "loj.parcel.batch"
    _description = "LOJ Parcel Batch"
    _rec_name = 'name'

    name = fields.Char(
        string='Batch Reference',
        required=True,
        readonly=True,
        copy=False,
        default='New'
    )
    create_date = fields.Datetime(string="Created On", readonly=True)
    user_id = fields.Many2one("res.users", string="Processed By", default=lambda self: self.env.user)
    dispatcher_id = fields.Many2one("hr.employee", string="Dispatcher", required=True)
    order_ids = fields.One2many("sale.order", "loj_parcel_batch_id", string="Sales Orders")

    warehouse_id = fields.Many2one(
        'stock.warehouse',
        string='Warehouse',
        readonly=True
    )

    @api.model
    def create(self, vals):
        if vals.get('name', 'New') == 'New':
            vals['name'] = self.env['ir.sequence'].next_by_code('loj.parcel.batch') or 'New'
        return super(LojParcelBatch, self).create(vals)

    @api.multi
    def create_xml_for_batch(self, reprint=False):
        for batch in self:
            if not batch.order_ids:
                continue

            OUTPUT_DIR = r"C:\Users\Loj Parcel\XMLs\Slips"
            os.makedirs(OUTPUT_DIR, exist_ok=True)

            now = datetime.today().strftime('%d%m%y%H%M%S')
            safe_name = batch.name.replace(' ', '_')
            filename = f"{safe_name}-{now}.xml"
            path_file = os.path.join(OUTPUT_DIR, filename)

            root = minidom.Document()
            xml_root = root.createElement('VoucherXml')
            root.appendChild(xml_root)

            copy_type = 'reprint' if reprint else 'new'

            # Top-level elements
            for tag, value in [
                ('copy_type', copy_type),
                ('batch_ref', batch.name),
                ('stock', batch.warehouse_id.name if batch.warehouse_id else ''),
                ('dispatcher', batch.dispatcher_id.name or ''),
            ]:
                el = root.createElement(tag)
                el.appendChild(root.createTextNode(value))
                xml_root.appendChild(el)

            # Orders
            for order in batch.order_ids:
                voucher = root.createElement('Voucher')
                xml_root.appendChild(voucher)

                code_el = root.createElement('code')
                code_el.appendChild(root.createTextNode(order.name))
                voucher.appendChild(code_el)

                if order.client_order_ref:
                    ref_el = root.createElement('reference')
                    ref_el.appendChild(root.createTextNode(order.client_order_ref))
                    voucher.appendChild(ref_el)

                if order.partner_id:
                    customer_el = root.createElement('customer')
                    voucher.appendChild(customer_el)
                    name_el = root.createElement('name')
                    name_el.appendChild(root.createTextNode(order.partner_id.name))
                    customer_el.appendChild(name_el)

            # Single top-level activity
            activity_el = root.createElement('Activity')
            xml_root.appendChild(activity_el)

            device_el = root.createElement('deviceName')
            device_el.appendChild(root.createTextNode(socket.gethostname()))
            activity_el.appendChild(device_el)

            user_el = root.createElement('user')
            activity_el.appendChild(user_el)

            full_name_el = root.createElement('fullName')
            full_name_el.appendChild(root.createTextNode(self.env.user.name))
            user_el.appendChild(full_name_el)

            user_name_el = root.createElement('userName')
            user_name_el.appendChild(root.createTextNode(self.env.user.login))
            user_el.appendChild(user_name_el)

            # Write XML
            with open(path_file, 'w+', encoding='utf-8') as f:
                f.write(root.toprettyxml(indent="\t"))
