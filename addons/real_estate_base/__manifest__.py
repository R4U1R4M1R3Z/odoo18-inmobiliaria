# -*- coding: utf-8 -*-
{
    'name': '00 - Real Estate Base',
    'version': '18.0.1.0.0',
    'category': 'Real Estate/Management',
    'sequence': 10,
    'summary': 'Gestión Inmobiliaria - Propiedades, Ventas y Alquileres',
    'description': """
Real Estate Base - Gestión Inmobiliaria
========================================

Módulo base para la gestión completa de una inmobiliaria.

Características principales:
-----------------------------
* Gestión de propiedades (pisos, casas, locales, terrenos, etc.)
* Control de tipos de propiedad
* Estados y workflow de propiedades
* Gestión de propietarios e inquilinos
* Precios de venta y alquiler
* Características detalladas (habitaciones, baños, m², extras)
* Ubicación y geolocalización
* Certificado energético
* Galería de imágenes
* Seguimiento de actividades
* Sistema de mensajería integrado

Funcionalidades:
----------------
* Vista Kanban visual de propiedades
* Filtros avanzados por estado, tipo, ciudad, precio
* Agrupaciones por múltiples criterios
* Asignación de agentes comerciales
* Datos de demostración incluidos
* Multi-moneda
* Interfaz intuitiva y responsive

Perfecto para:
--------------
* Agencias inmobiliarias
* Gestión de carteras de propiedades
* Administración de alquileres
* Venta de inmuebles
    """,
    'author': 'Raul Ramirez',
    'website': 'www.linkedin.com/in/raúl-ramírez-5005a91b1',
    'license': 'LGPL-3',
    
    # Dependencias
    'depends': [
        'base',
        'web',
        'mail',
        'contacts',
    ],
    
    # Datos que siempre se cargan
    'data': [
        
        # Datos maestros
        'data/property_type_data.xml',
        
        # Seguridad (siempre primero)
        'security/real_estate_security.xml',
        'security/ir.model.access.csv',
        
        
        # Vistas
        'views/property_views.xml',
        'views/property_type_views.xml',
        'views/menus.xml',
    ],
    
    # Datos de demostración (solo si se instala con demo=True)
    'demo': [
        # 'demo/property_demo.xml',
    ],
    
    # Assets Web (CSS, JS) - por ahora vacío
    'assets': {
        'web.assets_backend': [
            # 'real_estate_base/static/src/css/real_estate.css',
            # 'real_estate_base/static/src/js/real_estate.js',
        ],
    },
    
    # Imágenes para la tienda de apps
    'images': [
        'static/description/banner.png',
        'static/description/icon.png',
    ],
    
    # Configuración del módulo
    'installable': True,
    'application': True,  # Aparece como aplicación principal en el menú de Apps
    'auto_install': False,  # No se instala automáticamente
    
    # Precio (si lo publicas en Odoo Apps Store)
    'price': 0.00,
    'currency': 'EUR',
    
    # Post-instalación
    # 'post_init_hook': 'post_init_hook',
    # 'uninstall_hook': 'uninstall_hook',
}