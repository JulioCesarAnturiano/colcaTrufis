<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TrufiController;
use App\Http\Controllers\TrufiRutaController;
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
//trufis
Route::get('/trufis', [TrufiController::class, 'index']);
Route::get('/trufis/{id}', [TrufiController::class, 'show']);
//trufi_rutas
Route::get('/trufi-rutas', [TrufiRutaController::class, 'index']);
Route::get('/trufi-rutas/{id}', [TrufiRutaController::class, 'show']);
Route::get('/trufis/{idtrufi}/rutas', [TrufiRutaController::class, 'rutasPorTrufi']);
