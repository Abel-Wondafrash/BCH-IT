# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

{
    'name': 'Sales Location',
    'summary': """Sales location Management""",
    'version': '1.0',
    'category': "Sales/Sales",
    'depends': ['base', 'sale', 'sale_management','mrp','purchase','stock', 'decimal_precision', 'mail'],
    'description': """
This is the base module for approving products
========================================================================

Products are first put in the draft state then in order for them to be accessible they need 
to be approved by the product manager



Pricelists preferences by product and/or partners.

Print product labels with barcode.
    """,
    'data': [
        'views/sale_views.xml',
        'views/sale_locations_view.xml',

    ],
    'installable': True,
    'auto_install': False,
}
