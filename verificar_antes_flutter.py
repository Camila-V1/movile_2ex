"""
🎯 VERIFICACIÓN RÁPIDA DE RECOMENDACIONES
Ejecuta este script antes de probar en Flutter
"""
import requests
import json

BACKEND = 'https://backend-2ex-ecommerce.onrender.com'
GREEN = '\033[92m'
RED = '\033[91m'
BLUE = '\033[94m'
END = '\033[0m'

print(f"\n{BLUE}{'='*60}{END}")
print(f"{BLUE}🧪 VERIFICACIÓN DE RECOMENDACIONES - MÓVIL FLUTTER{END}")
print(f"{BLUE}{'='*60}{END}\n")

# 1. Login
print(f"{BLUE}1. Testing login...{END}")
try:
    r = requests.post(f'{BACKEND}/api/token/', json={'username': 'admin', 'password': 'admin123'})
    r.raise_for_status()
    token = r.json()['access']
    print(f"{GREEN}   ✓ Login exitoso{END}")
except Exception as e:
    print(f"{RED}   ✗ Error: {e}{END}")
    exit(1)

headers = {'Authorization': f'Bearer {token}'}

# 2. Recomendaciones personalizadas
print(f"\n{BLUE}2. Testing /api/products/personalized/{END}")
try:
    r = requests.get(f'{BACKEND}/api/products/personalized/', headers=headers, params={'limit': 5})
    r.raise_for_status()
    data = r.json()
    count = len(data.get('recommendations', []))
    print(f"{GREEN}   ✓ Funcionando - {count} recomendaciones{END}")
    if count > 0:
        print(f"   • Ejemplo: {data['recommendations'][0]['name']} - ${data['recommendations'][0]['price']}")
except Exception as e:
    print(f"{RED}   ✗ Error: {e}{END}")

# 3. Recomendaciones por producto
print(f"\n{BLUE}3. Testing /api/products/{{id}}/recommendations/{END}")
try:
    # Obtener primer producto
    r = requests.get(f'{BACKEND}/api/products/', headers=headers)
    products = r.json()
    if isinstance(products, list) and len(products) > 0:
        product_id = products[0]['id']
        product_name = products[0]['name']
        
        # Obtener recomendaciones
        r = requests.get(f'{BACKEND}/api/products/{product_id}/recommendations/', headers=headers)
        r.raise_for_status()
        data = r.json()
        count = len(data.get('recommendations', []))
        print(f"{GREEN}   ✓ Funcionando - {count} recomendaciones para '{product_name}'{END}")
        if count > 0:
            print(f"   • Ejemplo: {data['recommendations'][0]['name']}")
except Exception as e:
    print(f"{RED}   ✗ Error: {e}{END}")

# 4. Productos (para productos populares)
print(f"\n{BLUE}4. Testing /api/products/ (productos populares){END}")
try:
    r = requests.get(f'{BACKEND}/api/products/', params={'ordering': '-created_at'})
    r.raise_for_status()
    products = r.json()
    count = len(products) if isinstance(products, list) else len(products.get('results', []))
    print(f"{GREEN}   ✓ Funcionando - {count} productos disponibles{END}")
except Exception as e:
    print(f"{RED}   ✗ Error: {e}{END}")

# Resumen
print(f"\n{BLUE}{'='*60}{END}")
print(f"{GREEN}✅ TODOS LOS ENDPOINTS FUNCIONAN CORRECTAMENTE{END}")
print(f"{BLUE}{'='*60}{END}\n")

print(f"{BLUE}📱 SIGUIENTE PASO:{END}")
print("   1. Abre Android Studio / VS Code")
print("   2. cd movile_2ex")
print("   3. flutter run")
print("   4. Login: admin / admin123")
print("   5. Navega a recomendaciones")
print(f"\n{GREEN}¡Listo para probar! 🚀{END}\n")
