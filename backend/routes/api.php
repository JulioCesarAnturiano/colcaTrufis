<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TrufiController;
use App\Http\Controllers\TrufiRutaController;

// ===========================
// API PÚBLICA (FLUTTER) - SOLO LECTURA
// ===========================
Route::get('/trufis', [TrufiController::class, 'index']);
Route::get('/trufis/{id}', [TrufiController::class, 'show']);

Route::get('/trufi-rutas', [TrufiRutaController::class, 'index']);
Route::get('/trufi-rutas/{id}', [TrufiRutaController::class, 'show']);
Route::get('/trufis/{idtrufi}/rutas', [TrufiRutaController::class, 'rutasPorTrufi']);
