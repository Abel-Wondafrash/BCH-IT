{
    'name': 'Sale Orders by Warehouse',
    'version': '11.0.1.0.0',
    'summary': 'View and process Sales Orders by Warehouse with LOJ Parcel XML generation',
    'category': 'Sales',
    'author': 'Admin',
    'depends': ['sale', 'sale_stock'],
    'data': [
        'security/ir.model.access.csv',
        'security/parcel_security.xml',
        'views/sale_orders_by_warehouse_views.xml',
        'views/parcel_dispatcher_wizard_views.xml',
        'views/hr_employee_inherit.xml',
        'data/sequence.xml',
        'data/server_actions.xml',
    ],
    'installable': True,
    'application': False,
}
