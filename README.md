
---

````markdown
# 🏥 Sistema de Reportes Médicos - Flask App

Esta aplicación web permite visualizar reportes médicos a partir de información en una base de datos PostgreSQL. Incluye gráficos en distintos formatos, exportación a PDF y CSV, y una interfaz simple en HTML.

---

## ⚙️ Requisitos

- Python 3.8 o superior
- PostgreSQL con base de datos configurada
- Acceso a Internet para instalar paquetes

---

## 📦 Instalación

1. **Clona este repositorio** o descarga los archivos del proyecto.

2. **Crea un entorno virtual**:

```bash
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
````

3. **Instala las dependencias**:

```bash
pip install -r requirements.txt
```


## 🛠️ Configuración

Edita la sección `DB_CONFIG` en el archivo `app.py` con los datos reales de tu base de datos:

```python
DB_CONFIG = {
    "dbname": "Example",
    "user": "Example",
    "password": "Example",
    "host": "localhost",
    "port": "5432"
}
```

---

## ▶️ Cómo ejecutar

Desde la terminal, con el entorno virtual activado:

```bash
python app.py
```

Esto levantará el servidor en:

```
http://127.0.0.1:5000/
```

---

## 📁 Estructura esperada

Asegúrate de tener estas carpetas creadas:

```
/static/img        ← para guardar los gráficos de los reportes
/static/pdf        ← para guardar los PDFs generados
/templates         ← debe contener base.html, dashboard.html, reportes.html
```

---

## 📤 Exportaciones

* CSV: vía `/api/export_csv`
* PDF: vía `/api/export_pdf`

---

