$(document).ready(function() {
    // Inicialización general de la aplicación
    console.log("Aplicación de gestión clínica iniciada");
    
    // Tooltips
    $('[data-bs-toggle="tooltip"]').tooltip();
    
    // Manejo de pestañas
    $('a[data-bs-toggle="tab"]').on('shown.bs.tab', function(e) {
        localStorage.setItem('activeTab', $(e.target).attr('href'));
    });
    
    var activeTab = localStorage.getItem('activeTab');
    if (activeTab) {
        $('.nav-tabs a[href="' + activeTab + '"]').tab('show');
    }
    
    // Actualizar año en el footer
    $('#current-year').text(new Date().getFullYear());
});