{
    'name': 'Partner Bank Details',
    'version': '11.0.1.0.0',
    'summary': 'Adds a Bank Details tab to Contacts',
    'category': 'Contacts',
    'author': 'Admin',
    'depends': ['base', 'account'],
    'data': [
        'security/ir.model.access.csv',
        'views/res_partner_view.xml',
    ],
    'installable': True,
    'application': False,
}
