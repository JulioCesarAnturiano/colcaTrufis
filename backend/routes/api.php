<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TrufiController;
use App\Http\Controllers\TrufiRutaController;
use App\Http\Controllers\SindicatoController;
use App\Http\Controllers\SindicatoRadioTaxisController;

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
