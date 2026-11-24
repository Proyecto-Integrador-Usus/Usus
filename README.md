# Usus

Aplicación Flutter para encontrar y rentar artículos por categoría y ubicación. La entrega actual cubre la portada y el catálogo de demostración; no incluye servicios de servidor ni una base de datos.

## Lineamientos considerados

- La referencia visual compartida define la paleta: mostaza `#D4AF37`, marfil `#F5F0E6`, café oscuro `#3B2F2F`, arena `#B08D57` y blanco `#FFFFFF`.
- La portada muestra búsqueda, acceso de invitado, filtros, categorías y tarjetas de artículos.
- Las acciones para publicar artículos y abrir el carrito solo aparecen al iniciar sesión.
- La interfaz se adapta a teléfono, tableta y escritorio.

No se encontraron otros lineamientos o documentos de requisitos dentro del repositorio. El resto de las decisiones de estructura en este documento son recomendaciones para evolucionar el proyecto.

## Estructura actual del front

```text
lib/
├── core/
│   └── theme/                 # Paleta y tema compartido
├── features/
│   └── catalog/
│       ├── data/              # Repositorio de catálogo y datos demo
│       ├── domain/            # Producto y categorías
│       └── presentation/      # Portada, filtros y tarjetas
└── main.dart                 # Arranque y composición de dependencias
```

El contrato `CatalogRepository` permite cambiar `DemoCatalogRepository` por un adaptador REST sin acoplar las pantallas. La sesión y el carrito de esta portada son solo de demostración y se reinician al cerrar la app.

## Estructura recomendada al integrar Python y base de datos

Mantener el servidor como proyecto independiente del cliente Flutter facilita instalar dependencias, ejecutar despliegues y configurar ambientes por separado:

```text
usus/
├── lib/                       # App Flutter (front)
├── backend/                   # API Python (recomendación: FastAPI)
│   ├── app/
│   │   ├── api/v1/            # Rutas HTTP y esquemas de entrada/salida
│   │   ├── core/              # Configuración, seguridad y manejo de errores
│   │   ├── models/            # Modelos ORM
│   │   ├── repositories/      # Consultas y persistencia
│   │   ├── services/          # Reglas de negocio
│   │   └── main.py            # Ensamble de la API
│   ├── migrations/            # Migraciones versionadas
│   ├── tests/
│   └── pyproject.toml
├── database/
│   ├── migrations/            # Única fuente de migraciones (si se prefiere centralizarla)
│   ├── seeds/                 # Datos iniciales de desarrollo
│   └── README.md              # Motor, respaldos y diagrama de datos
└── README.md
```

Para evitar duplicar migraciones, elijan **una sola** ubicación: `backend/migrations/` o `database/migrations/`. Para este proyecto recomiendo `backend/migrations/`, junto al ORM. En producción, las credenciales deben venir de variables de entorno y nunca guardarse en Flutter ni en el repositorio.

### Contrato inicial sugerido para el catálogo

- `GET /api/v1/products?category=&search=&min_price=&max_price=&location=` devuelve `{"items": [...]}`.
- Cada artículo expone `id`, `name`, `category`, `price_per_day`, `location`, `rating` e `image_url`.
- El front configura la URL base al crear una implementación de `CatalogRepository`; el catálogo de esta portada actualmente usa datos demo locales.
- `RestCatalogRepository` ya adapta la respuesta JSON al modelo del front y recibe un transporte HTTP inyectado. La URL base se prepara con `CatalogApiConfig` y `--dart-define=API_BASE_URL=...`; al elegir cliente HTTP se inyectará su función GET en el repositorio.
- Autenticación, publicación, carrito y pagos requieren endpoints propios y validación del lado del servidor antes de usarse con datos reales.

## Ejecutar

```bash
flutter pub get
flutter run
```
