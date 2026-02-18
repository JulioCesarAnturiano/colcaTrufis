<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TrufiController;
use App\Http\Controllers\TrufiRutaController;
use App\Http\Controllers\SindicatoController;
use App\Http\Controllers\SindicatoRadioTaxisController;
use App\Http\Controllers\NormativaController;
use App\Http\Controllers\SindicatoRadioTaxiController;
use App\Http\Controllers\TrufiSeleccionController;

Route::get('/test', function () {
    return response()->json([
        'success' => true,
        'message' => 'API Colcatrufis funcionando',
        'timestamp' => now()->toDateTimeString(),
        'endpoints' => [
            '/api/trufis' => 'Lista de trufis',
            '/api/test' => 'Prueba de conexión',
        ]
    ]);
});
// ===========================
// API PÚBLICA (FLUTTER) - SOLO LECTURA
// ===========================
//trufi normales
Route::get('/trufis', [TrufiController::class, 'index']);
Route::get('/trufis/{id}', [TrufiController::class, 'show']);
// ===========================
// GEOJSON
// ===========================
// Ruta completa (LineString) por idtrufi
Route::get('/trufis/{idtrufi}/rutas/geojson', [TrufiRutaController::class, 'geojsonPorTrufi']);
Route::get('/trufis/rutas/geojson', [TrufiRutaController::class, 'geojsonTodas']);

// Sindicatos
Route::get('/sindicatos', [SindicatoController::class, 'index']);
Route::get('/sindicatos/{id}', [SindicatoController::class, 'show']);

// Sindicato radiotaxis
Route::get('/sindicato-radiotaxis', [SindicatoRadioTaxisController::class, 'index']);
Route::get('/sindicato-radiotaxis/{id}', [SindicatoRadioTaxisController::class, 'show']);
//normativas
Route::get('/normativas', [NormativaController::class, 'index']);
Route::get('/normativas/{id}/download', [NormativaController::class, 'download']);
//radio taxis
Route::get('/radiotaxis/paradas', [SindicatoRadioTaxisController::class, 'paradas']);
Route::get('/radiotaxis/{id}/parada', [SindicatoRadioTaxisController::class, 'paradaPorRadiotaxi']);
//ParadasFormatoNormal
Route::get('/radiotaxis', [SindicatoRadioTaxisController::class, 'index']);
Route::get('/radiotaxis/{id}', [SindicatoRadioTaxisController::class, 'show']);
//ParadasFormatogeoJson
Route::get('/radiotaxis/paradas/geojson', [SindicatoRadioTaxisController::class, 'paradasGeojson']);
Route::get('/radiotaxis/{id}/parada/geojson', [SindicatoRadioTaxisController::class, 'paradaGeojsonPorRadiotaxi']);
// Registrar selección de un trufi (Flutter llamará esto cuando el usuario lo elija)
Route::post('/trufis/{idtrufi}/seleccion', [TrufiSeleccionController::class, 'registrar']);