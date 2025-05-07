-- Insertar médicos
INSERT INTO medicos (nombre, apellido, especialidad, telefono, email, fecha_contratacion) VALUES
('Juan', 'Pérez', 'Cardiología', '12345678', 'juan.perez@clinica.com', '2020-01-15'),
('María', 'Gómez', 'Pediatría', '23456789', 'maria.gomez@clinica.com', '2019-05-20'),
('Carlos', 'López', 'Dermatología', '34567890', 'carlos.lopez@clinica.com', '2021-03-10'),
('Ana', 'Martínez', 'Ginecología', '45678901', 'ana.martinez@clinica.com', '2018-11-05'),
('Luis', 'Rodríguez', 'Ortopedia', '56789012', 'luis.rodriguez@clinica.com', '2022-02-28');

-- Insertar pacientes (100 pacientes)
DO $$
DECLARE
    i INTEGER;
    nombres TEXT[] := ARRAY['Ana', 'Juan', 'María', 'Carlos', 'Luisa', 'Pedro', 'Sofía', 'Miguel', 'Laura', 'Jorge'];
    apellidos TEXT[] := ARRAY['García', 'Rodríguez', 'Martínez', 'López', 'Gómez', 'Pérez', 'Hernández', 'Díaz', 'Torres', 'Ramírez'];
    generos TEXT[] := ARRAY['Masculino', 'Femenino', 'Otro'];
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO pacientes (nombre, apellido, fecha_nacimiento, genero, direccion, telefono, email)
        VALUES (
            nombres[1 + floor(random() * array_length(nombres, 1))],
            apellidos[1 + floor(random() * array_length(apellidos, 1))] || ' ' || 
            apellidos[1 + floor(random() * array_length(apellidos, 1))],
            (CURRENT_DATE - (random() * 365 * 80 + 365 * 18)::INTEGER)::DATE,
            generos[1 + floor(random() * array_length(generos, 1))],
            'Dirección ' || i || ', Ciudad',
            '5' || (10000000 + floor(random() * 90000000))::TEXT,
            'paciente' || i || '@email.com'
        );
    END LOOP;
END $$;

-- Insertar exámenes
INSERT INTO examenes (nombre, descripcion, costo) VALUES
('Hemograma completo', 'Análisis de células sanguíneas', 150.00),
('Perfil lipídico', 'Medición de colesterol y triglicéridos', 200.00),
('Glucosa en ayunas', 'Medición de niveles de glucosa', 80.00),
('Radiografía de tórax', 'Imagen de rayos X del tórax', 250.00),
('Ecografía abdominal', 'Imagen por ultrasonido del abdomen', 300.00),
('Electrocardiograma', 'Registro de actividad eléctrica del corazón', 180.00),
('Prueba de función tiroidea', 'Análisis de hormonas tiroideas', 220.00),
('Análisis de orina', 'Examen físico, químico y microscópico de orina', 90.00);

-- Insertar historiales médicos (uno por paciente)
INSERT INTO historiales_medicos (id_paciente, notas)
SELECT id_paciente, 'Historial médico inicial del paciente ' || nombre || ' ' || apellido
FROM pacientes;

-- Insertar citas (3 por paciente)
INSERT INTO citas (id_paciente, id_medico, fecha_hora, motivo, estado)
SELECT 
    p.id_paciente,
    (SELECT id_medico FROM medicos ORDER BY random() LIMIT 1),
    (CURRENT_TIMESTAMP + (random() * 30 * 24 * 60 * 60 * INTERVAL '1 second') - (random() * 15 * 24 * 60 * 60 * INTERVAL '1 second')),
    CASE 
        WHEN random() < 0.3 THEN 'Consulta general'
        WHEN random() < 0.6 THEN 'Control de rutina'
        ELSE 'Seguimiento de tratamiento'
    END,
    CASE 
        WHEN random() < 0.8 THEN 'completada'
        WHEN random() < 0.9 THEN 'cancelada'
        ELSE 'no_asistio'
    END
FROM pacientes p
CROSS JOIN generate_series(1, 3);

-- Insertar diagnósticos (para citas completadas)
INSERT INTO diagnosticos (id_historial, id_medico, diagnostico, tratamiento)
SELECT 
    hm.id_historial,
    c.id_medico,
    CASE 
        WHEN random() < 0.3 THEN 'Resfriado común'
        WHEN random() < 0.5 THEN 'Hipertensión arterial'
        WHEN random() < 0.7 THEN 'Diabetes tipo 2'
        WHEN random() < 0.8 THEN 'Artritis'
        ELSE 'Gastritis'
    END,
    CASE 
        WHEN random() < 0.5 THEN 'Reposo y medicación'
        WHEN random() < 0.8 THEN 'Tratamiento farmacológico'
        ELSE 'Seguimiento especializado'
    END
FROM citas c
JOIN pacientes p ON c.id_paciente = p.id_paciente
JOIN historiales_medicos hm ON p.id_paciente = hm.id_paciente
WHERE c.estado = 'completada';

-- Insertar medicamentos
INSERT INTO medicamentos (nombre, descripcion, precio_unitario, stock) VALUES
('Paracetamol', 'Analgésico y antipirético', 5.50, 1000),
('Ibuprofeno', 'Antiinflamatorio no esteroideo', 7.20, 800),
('Amoxicilina', 'Antibiótico de amplio espectro', 12.80, 600),
('Loratadina', 'Antihistamínico para alergias', 8.90, 750),
('Omeprazol', 'Inhibidor de bomba de protones', 15.30, 500),
('Metformina', 'Antidiabético oral', 9.75, 400),
('Atorvastatina', 'Hipolipemiante', 18.40, 300),
('Losartán', 'Antihipertensivo', 14.20, 450);

-- Insertar recetas (para diagnósticos)
INSERT INTO recetas (id_diagnostico, instrucciones)
SELECT 
    id_diagnostico,
    CASE 
        WHEN random() < 0.5 THEN 'Tomar cada 8 horas por 7 días'
        WHEN random() < 0.8 THEN 'Tomar cada 12 horas por 10 días'
        ELSE 'Tomar según necesidad'
    END
FROM diagnosticos;

-- Insertar medicamentos en recetas (2-4 medicamentos por receta)
DO $$
DECLARE
    receta_id INTEGER;
    medicamento_id INTEGER;
    cantidad_med INTEGER;
BEGIN
    FOR receta_id IN SELECT id_receta FROM recetas LOOP
        FOR i IN 1..(2 + floor(random() * 3)) LOOP
            SELECT id_medicamento INTO medicamento_id FROM medicamentos ORDER BY random() LIMIT 1;
            cantidad_med := 1 + floor(random() * 3);
            
            INSERT INTO recetas_medicamentos (id_receta, id_medicamento, cantidad, dosis)
            VALUES (
                receta_id,
                medicamento_id,
                cantidad_med,
                CASE 
                    WHEN random() < 0.5 THEN '1 tableta'
                    WHEN random() < 0.8 THEN '2 tabletas'
                    ELSE '1 cucharada'
                END
            );
        END LOOP;
    END LOOP;
END $$;

-- Insertar exámenes para pacientes
INSERT INTO examenes_pacientes (id_paciente, id_examen, id_medico, fecha_realizacion, resultados, costo_final)
SELECT 
    p.id_paciente,
    e.id_examen,
    (SELECT id_medico FROM medicos ORDER BY random() LIMIT 1),
    (CURRENT_TIMESTAMP - (random() * 30 * 24 * 60 * 60 * INTERVAL '1 second')),
    CASE 
        WHEN random() < 0.7 THEN 'Resultados dentro de rangos normales'
        ELSE 'Resultados anormales, requiere seguimiento'
    END,
    e.costo * (0.9 + random() * 0.2) -- Variación de +/- 10% en el costo
FROM pacientes p
CROSS JOIN examenes e
WHERE random() < 0.3; -- 30% de probabilidad de que un paciente tenga un examen

-- Insertar facturas (para pacientes con citas completadas)
INSERT INTO facturas (id_paciente, estado)
SELECT DISTINCT p.id_paciente, 
    CASE 
        WHEN random() < 0.7 THEN 'pagada'
        ELSE 'pendiente'
    END
FROM citas c
JOIN pacientes p ON c.id_paciente = p.id_paciente
WHERE c.estado = 'completada';

-- Insertar detalles de factura (para consultas)
INSERT INTO facturas_detalles (id_factura, concepto, tipo_concepto, id_referencia, cantidad, precio_unitario, subtotal)
SELECT 
    f.id_factura,
    'Consulta médica con ' || m.especialidad,
    'consulta',
    c.id_cita,
    1,
    300.00 * (0.8 + random() * 0.4), -- Precio entre 240 y 420
    300.00 * (0.8 + random() * 0.4)
FROM facturas f
JOIN pacientes p ON f.id_paciente = p.id_paciente
JOIN citas c ON p.id_paciente = c.id_paciente AND c.estado = 'completada'
JOIN medicos m ON c.id_medico = m.id_medico;

-- Insertar detalles de factura (para exámenes)
INSERT INTO facturas_detalles (id_factura, concepto, tipo_concepto, id_referencia, cantidad, precio_unitario, subtotal)
SELECT 
    f.id_factura,
    e.nombre,
    'examen',
    ep.id_examen_paciente,
    1,
    ep.costo_final,
    ep.costo_final
FROM facturas f
JOIN examenes_pacientes ep ON f.id_paciente = ep.id_paciente
JOIN examenes e ON ep.id_examen = e.id_examen;

-- Insertar detalles de factura (para medicamentos)
INSERT INTO facturas_detalles (id_factura, concepto, tipo_concepto, id_referencia, cantidad, precio_unitario, subtotal)
SELECT 
    f.id_factura,
    m.nombre,
    'medicamento',
    rm.id_receta_medicamento,
    rm.cantidad,
    m.precio_unitario,
    rm.cantidad * m.precio_unitario
FROM facturas f
JOIN pacientes p ON f.id_paciente = p.id_paciente
JOIN historiales_medicos hm ON p.id_paciente = hm.id_paciente
JOIN diagnosticos d ON hm.id_historial = d.id_historial
JOIN recetas r ON d.id_diagnostico = r.id_diagnostico
JOIN recetas_medicamentos rm ON r.id_receta = rm.id_receta
JOIN medicamentos m ON rm.id_medicamento = m.id_medicamento;