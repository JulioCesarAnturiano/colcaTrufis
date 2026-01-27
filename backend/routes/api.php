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
//trufi rutas
Route::get('/trufi-rutas', [TrufiRutaController::class, 'index']);
Route::get('/trufi-rutas/{id}', [TrufiRutaController::class, 'show']);
Route::get('/trufis/{idtrufi}/rutas', [TrufiRutaController::class, 'rutasPorTrufi']);
// sindicato 
Route::get('/sindicato', [SindicatoController::class, 'index']);
Route::get('/sindicato/{id}', [SindicatoController::class, 'show']);
//sindicato radio taxis
Route::get('/sindicato', [SindicatoRadioTaxisController::class, 'index']);
Route::get('/sindicato/{id}', [SindicatoRadioTaxisController::class, 'show']);
