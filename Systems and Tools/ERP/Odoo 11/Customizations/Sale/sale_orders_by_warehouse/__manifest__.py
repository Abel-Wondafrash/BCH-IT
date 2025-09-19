# -*- coding: utf-8 -*-
{
    'name': 'Orders by Warehouse (shortcut)',
    'version': '11.0.1.0.0',
    'summary': 'Shortcut: Sales Orders grouped by Warehouse with default Today filter',
    'category': 'Sales',
    'author': 'Admin',
    'website': '',
    'depends': ['sale', 'stock'],
    'data': [
        'views/sale_orders_by_warehouse_views.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
}
