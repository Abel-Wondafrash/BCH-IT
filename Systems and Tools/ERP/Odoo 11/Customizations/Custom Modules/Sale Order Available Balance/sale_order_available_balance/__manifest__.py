{
    'name': 'Sale Order Available Balance',
    'version': '16.0.1.0.0',
    'summary': 'Checks available balance before creating or confirming sale orders',
    'depends': ['sale', 'account'],
    'data': [
        'views/sale_order_view.xml',
    ],
    'installable': True,
    'application': False,
    'license': 'LGPL-3',
}
