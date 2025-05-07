$(document).ready(function() {
    // Inicialización de reportes
    initReportFilters();
    loadReport(1);
    
    // Manejar clic en botones de reporte
    $('.report-btn').click(function() {
        const reportId = $(this).data('report');
        loadReport(reportId);
    });
    
    // Manejar exportación a CSV
    $('.export-csv').click(function() {
        const reportId = $(this).data('report');
        exportToCSV(reportId);
    });
    
    // Manejar exportación a PDF
    $('.export-pdf').click(function() {
        const reportId = $(this).data('report');
        exportToPDF(reportId);
    });
});

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
    
    // Configurar datepickers
    $('.date-input').val(new Date().toISOString().split('T')[0]);
}

function loadReport(reportId) {
    // Mostrar loader
    $(`#report-container-${reportId}`).html('<div class="text-center py-5"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Cargando...</span></div></div>');
    
    // Obtener parámetros del formulario
    const formData = $(`#report-form-${reportId}`).serialize();
    
    // Llamar a la API correspondiente
    $.get(`/api/reporte${reportId}?${formData}`, function(data) {
        renderReport(reportId, data);
    }).fail(function() {
        $(`#report-container-${reportId}`).html('<div class="alert alert-danger">Error al cargar el reporte</div>');
    });
}

function renderReport(reportId, data) {
    const container = $(`#report-container-${reportId}`);
    container.empty();
    
    // Crear contenedor del gráfico
    container.append('<div class="chart-container fade-in"><canvas id="chart-' + reportId + '"></canvas></div>');
    
    // Crear gráfico con Chart.js
    const ctx = document.getElementById(`chart-${reportId}`).getContext('2d');
    
    let chart;
    if (data.type === 'combo') {
        chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: data.labels,
                datasets: data.datasets.map(dataset => {
                    if (dataset.type === 'line') {
                        return {
                            type: 'line',
                            label: dataset.label,
                            data: dataset.data,
                            borderColor: dataset.borderColor,
                            backgroundColor: dataset.backgroundColor,
                            yAxisID: 'y1'
                        };
                    } else {
                        return {
                            type: 'bar',
                            label: dataset.label,
                            data: dataset.data,
                            backgroundColor: dataset.backgroundColor
                        };
                    }
                })
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: $(`#report-title-${reportId}`).text()
                    },
                },
                scales: {
                    y: {
                        beginAtZero: true
                    },
                    y1: {
                        position: 'right',
                        beginAtZero: true,
                        grid: {
                            drawOnChartArea: false
                        }
                    }
                }
            }
        });
    } else {
        chart = new Chart(ctx, {
            type: data.type,
            data: {
                labels: data.labels,
                datasets: data.datasets || [{
                    label: $(`#report-title-${reportId}`).text(),
                    data: data.data,
                    backgroundColor: getChartColors(data.type, data.labels.length)
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: $(`#report-title-${reportId}`).text()
                    },
                },
                scales: data.type === 'horizontalBar' ? {
                    x: {
                        beginAtZero: true
                    }
                } : {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }
    
    // Agregar botones de exportación
    container.append(`
        <div class="mt-3 text-end">
            <button class="btn btn-success export-csv" data-report="${reportId}">
                <i class="bi bi-file-earmark-excel"></i> Exportar a CSV
            </button>
            <button class="btn btn-danger export-pdf" data-report="${reportId}">
                <i class="bi bi-file-earmark-pdf"></i> Exportar a PDF
            </button>
        </div>
    `);
    
    // Re-inicializar eventos de exportación
    $(`.export-csv[data-report="${reportId}"]`).click(function() {
        exportToCSV(reportId);
    });
    
    $(`.export-pdf[data-report="${reportId}"]`).click(function() {
        exportToPDF(reportId, chart);
    });
}

function getChartColors(type, count) {
    if (type === 'pie') {
        return [
            'rgba(255, 99, 132, 0.7)',
            'rgba(54, 162, 235, 0.7)',
            'rgba(255, 206, 86, 0.7)',
            'rgba(75, 192, 192, 0.7)',
            'rgba(153, 102, 255, 0.7)'
        ].slice(0, count);
    } else {
        return 'rgba(54, 162, 235, 0.5)';
    }
}

function exportToCSV(reportId) {
    $.post('/api/export_csv', { report_id: reportId }, function(data) {
        const blob = new Blob([data.csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        
        link.setAttribute('href', url);
        link.setAttribute('download', `reporte_${reportId}.csv`);
        link.style.visibility = 'hidden';
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    });
}

function exportToPDF(reportId, chart) {
    // Obtener datos del gráfico para el PDF
    const chartData = {
        report_id: reportId,
        chart_data: {
            type: chart.config.type,
            labels: chart.data.labels,
            data: chart.data.datasets[0].data,
            datasets: chart.data.datasets
        }
    };
    
    $.post('/api/export_pdf', chartData, function(data) {
        window.open(data.pdf_url, '_blank');
    });
}