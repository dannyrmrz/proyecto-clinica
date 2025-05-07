// charts.js
function renderChart(reportId, data) {
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
    if (type === 'pie' || type === 'doughnut') {
        const colors = [
            'rgba(255, 99, 132, 0.7)',
            'rgba(54, 162, 235, 0.7)',
            'rgba(255, 206, 86, 0.7)',
            'rgba(75, 192, 192, 0.7)',
            'rgba(153, 102, 255, 0.7)',
            'rgba(255, 159, 64, 0.7)',
            'rgba(199, 199, 199, 0.7)',
            'rgba(83, 102, 255, 0.7)',
            'rgba(40, 159, 64, 0.7)',
            'rgba(210, 199, 199, 0.7)'
        ];
        return colors.slice(0, count);
    } else if (type === 'bar' || type === 'horizontalBar') {
        return 'rgba(54, 162, 235, 0.5)';
    } else {
        return 'rgba(75, 192, 192, 0.5)';
    }
}