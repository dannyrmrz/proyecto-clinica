-- Tabla de pacientes
CREATE TABLE pacientes (
    id_paciente SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero VARCHAR(20) NOT NULL CHECK (genero IN ('Masculino', 'Femenino', 'Otro')),
    direccion VARCHAR(200),
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de médicos
CREATE TABLE medicos (
    id_medico SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    especialidad VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    fecha_contratacion DATE NOT NULL
);

-- Tabla de citas
CREATE TABLE citas (
    id_cita SERIAL PRIMARY KEY,
    id_paciente INTEGER NOT NULL REFERENCES pacientes(id_paciente),
    id_medico INTEGER NOT NULL REFERENCES medicos(id_medico),
    fecha_hora TIMESTAMP NOT NULL,
    motivo VARCHAR(200) NOT NULL,
    estado VARCHAR(20) DEFAULT 'programada' NOT NULL CHECK (estado IN ('programada', 'completada', 'cancelada', 'no_asistio'))
);

-- Tabla de historiales médicos
CREATE TABLE historiales_medicos (
    id_historial SERIAL PRIMARY KEY,
    id_paciente INTEGER NOT NULL REFERENCES pacientes(id_paciente),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notas TEXT
);

-- Tabla de diagnósticos
CREATE TABLE diagnosticos (
    id_diagnostico SERIAL PRIMARY KEY,
    id_historial INTEGER NOT NULL REFERENCES historiales_medicos(id_historial),
    id_medico INTEGER NOT NULL REFERENCES medicos(id_medico),
    fecha_diagnostico TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diagnostico TEXT NOT NULL,
    tratamiento TEXT
);

-- Tabla de exámenes
CREATE TABLE examenes (
    id_examen SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    costo DECIMAL(10,2) NOT NULL CHECK (costo > 0)
);

-- Tabla de exámenes de pacientes
CREATE TABLE examenes_pacientes (
    id_examen_paciente SERIAL PRIMARY KEY,
    id_paciente INTEGER NOT NULL REFERENCES pacientes(id_paciente),
    id_examen INTEGER NOT NULL REFERENCES examenes(id_examen),
    id_medico INTEGER NOT NULL REFERENCES medicos(id_medico),
    fecha_realizacion TIMESTAMP NOT NULL,
    resultados TEXT,
    costo_final DECIMAL(10,2) NOT NULL CHECK (costo_final >= 0)
);

-- Tabla de medicamentos
CREATE TABLE medicamentos (
    id_medicamento SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario > 0),
    stock INTEGER NOT NULL CHECK (stock >= 0)
);

-- Tabla de recetas
CREATE TABLE recetas (
    id_receta SERIAL PRIMARY KEY,
    id_diagnostico INTEGER NOT NULL REFERENCES diagnosticos(id_diagnostico),
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    instrucciones TEXT
);

-- Tabla de relación recetas-medicamentos
CREATE TABLE recetas_medicamentos (
    id_receta_medicamento SERIAL PRIMARY KEY,
    id_receta INTEGER NOT NULL REFERENCES recetas(id_receta),
    id_medicamento INTEGER NOT NULL REFERENCES medicamentos(id_medicamento),
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    dosis VARCHAR(100) NOT NULL
);

-- Tabla de facturas
CREATE TABLE facturas (
    id_factura SERIAL PRIMARY KEY,
    id_paciente INTEGER NOT NULL REFERENCES pacientes(id_paciente),
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    estado VARCHAR(20) DEFAULT 'pendiente' NOT NULL CHECK (estado IN ('pendiente', 'pagada', 'cancelada'))
);

-- Tabla de detalles de factura
CREATE TABLE facturas_detalles (
    id_detalle SERIAL PRIMARY KEY,
    id_factura INTEGER NOT NULL REFERENCES facturas(id_factura),
    concepto VARCHAR(100) NOT NULL,
    tipo_concepto VARCHAR(50) NOT NULL CHECK (tipo_concepto IN ('consulta', 'examen', 'medicamento')),
    id_referencia INTEGER NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0)
);

-- Triggers
-- Trigger para actualizar stock al agregar medicamentos a una receta
CREATE OR REPLACE FUNCTION actualizar_stock_medicamento()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE medicamentos 
    SET stock = stock - NEW.cantidad 
    WHERE id_medicamento = NEW.id_medicamento;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_actualizar_stock
AFTER INSERT ON recetas_medicamentos
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_medicamento();

-- Trigger para calcular el total de una factura cuando se agregan detalles
CREATE OR REPLACE FUNCTION calcular_total_factura()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE facturas 
    SET total = (SELECT COALESCE(SUM(subtotal), 0) FROM facturas_detalles WHERE id_factura = NEW.id_factura)
    WHERE id_factura = NEW.id_factura;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_calcular_total_factura
AFTER INSERT OR UPDATE OR DELETE ON facturas_detalles
FOR EACH ROW
EXECUTE FUNCTION calcular_total_factura();

-- Trigger para verificar disponibilidad de medicamentos antes de recetar
CREATE OR REPLACE FUNCTION verificar_stock_medicamento()
RETURNS TRIGGER AS $$
DECLARE
    stock_actual INTEGER;
BEGIN
    SELECT stock INTO stock_actual 
    FROM medicamentos 
    WHERE id_medicamento = NEW.id_medicamento;
    
    IF stock_actual < NEW.cantidad THEN
        RAISE EXCEPTION 'No hay suficiente stock del medicamento (Stock actual: %)', stock_actual;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_verificar_stock
BEFORE INSERT ON recetas_medicamentos
FOR EACH ROW
EXECUTE FUNCTION verificar_stock_medicamento();