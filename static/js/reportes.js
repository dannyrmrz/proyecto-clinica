// reportes.js
$(document).ready(function() {
    // Inicialización de reportes
    initReportFilters();
    loadReport(1);
    
    // Manejar clic en botones de reporte
    $('.report-btn').click(function() {
        // Remover clase active de todos los botones
        $('.report-btn').removeClass('active');
        // Añadir clase active al botón clickeado
        $(this).addClass('active');
        
        const reportId = $(this).data('report');
        switchReport(reportId);
    });
});

function switchReport(reportId) {
    // Ocultar todos los formularios y contenedores
    $('.report-form').addClass('d-none');
    $('.report-form').removeClass('active');
    $('#report-title-' + reportId).removeClass('d-none');
    $('#report-title-' + reportId).siblings('h5').addClass('d-none');
    
    // Mostrar el formulario y contenedor correspondiente
    $('#report-form-' + reportId).removeClass('d-none');
    $('#report-form-' + reportId).addClass('active');
    
    // Cargar el reporte
    loadReport(reportId);
}

function initReportFilters() {
    // Cargar médicos en los selectores
    $.get('/api/medicos', function(data) {
        const selectors = $('.medico-select');
        selectors.empty();
        selectors.append('<option value="%">Todos los médicos</option>');
        
        data.forEach(function(medico) {
            selectors.append(`<option value="${medico.id}">${medico.nombre}</option>`);
        });
    });
    
    // Configurar datepickers con fecha actual
    const today = new Date().toISOString().split('T')[0];
    $('.date-input').val(today);
    
    // Configurar fechas de inicio y fin para el mes actual
    const firstDay = new Date();
    firstDay.setDate(1);
    const firstDayStr = firstDay.toISOString().split('T')[0];
    
    $('.date-input').each(function() {
        const id = $(this).attr('id');
        if (id.includes('inicio')) {
            $(this).val(firstDayStr);
        }
    });
}

function loadReport(reportId) {
    // Ocultar todos los contenedores de reporte
    $('[id^="report-container-"]').addClass('d-none');
    
    // Mostrar loader
    const container = $(`#report-container-${reportId}`);
    container.removeClass('d-none');
    container.html('<div class="text-center py-5"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Cargando...</span></div></div>');
    
    // Obtener parámetros del formulario
    const formData = $(`#report-form-${reportId}`).serialize();
    
    // Llamar a la API correspondiente
    $.get(`/api/reporte${reportId}?${formData}`, function(data) {
        renderChart(reportId, data);
    }).fail(function() {
        container.html('<div class="alert alert-danger">Error al cargar el reporte</div>');
    });
}

function exportToCSV(reportId) {
    // Obtener parámetros del formulario
    const formData = $(`#report-form-${reportId}`).serialize();
    
    $.post('/api/export_csv', { 
        report_id: reportId,
        filters: formData
    }, function(data) {
        const blob = new Blob([data.csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        
        link.setAttribute('href', url);
        link.setAttribute('download', `reporte_${reportId}_${new Date().toISOString().slice(0,10)}.csv`);
        link.style.visibility = 'hidden';
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    });
}

function exportToPDF(reportId, chart) {
    // Obtener parámetros del formulario
    const formData = $(`#report-form-${reportId}`).serialize();
    
    // Obtener datos del gráfico para el PDF
    const chartData = {
        report_id: reportId,
        filters: formData,
        chart_data: {
            type: chart.config.type,
            labels: chart.data.labels,
            datasets: chart.data.datasets
        }
    };
    
    $.post('/api/export_pdf', chartData, function(data) {
        window.open(data.pdf_url, '_blank');
    });
}