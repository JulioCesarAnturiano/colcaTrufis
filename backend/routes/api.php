<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TrufiController;
use App\Http\Controllers\TrufiRutaController;

Route::apiResource('trufis', TrufiController::class);
Route::apiResource('trufi-rutas', TrufiRutaController::class);

Route::get('trufis/{idtrufi}/rutas', [TrufiRutaController::class, 'rutasPorTrufi']);
