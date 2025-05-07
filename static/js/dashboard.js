

// Mostrar fecha actual
function displayCurrentDate() {
    const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    const today = new Date().toLocaleDateString('es-ES', options);
    $('#current-date').text(today.charAt(0).toUpperCase() + today.slice(1));
}

// Cargar datos de las tarjetas resumen
function loadSummaryCards() {
    // Total pacientes
    $.get('/api/reporte1', function(data) {
        const total = data.data.reduce((a, b) => a + b, 0);
        $('#total-pacientes').text(total);
    });
    
    // Citas hoy
    $.get('/api/reporte2', {
        fecha_inicio: new Date().toISOString().split('T')[0],
        fecha_fin: new Date().toISOString().split('T')[0],
        estado: 'programada'
    }, function(data) {
        const total = data.datasets.reduce((sum, dataset) => sum + dataset.data.reduce((a, b) => a + b, 0), 0);
        $('#citas-hoy').text(total);
    });
    
    // Ingresos mensuales
    const firstDay = new Date();
    firstDay.setDate(1);
    
    $.get('/api/reporte3', {
        fecha_inicio: firstDay.toISOString().split('T')[0],
        fecha_fin: new Date().toISOString().split('T')[0]
    }, function(data) {
        const total = data.datasets.reduce((sum, dataset) => sum + dataset.data.reduce((a, b) => a + b, 0), 0);
        $('#ingresos-mes').text('Q' + total.toFixed(2));
    });
}

// Inicializar el dashboard
function initDashboard() {
    displayCurrentDate();
    loadSummaryCards();
    
    // Actualizar cada 5 minutos
    setInterval(loadSummaryCards, 300000);
}

// Iniciar cuando el documento esté listo
$(document).ready(initDashboard);