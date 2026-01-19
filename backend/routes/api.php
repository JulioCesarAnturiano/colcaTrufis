<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TrufiController;
use App\Http\Controllers\TrufiRutaController;

Route::apiResource('trufis', TrufiController::class);
Route::apiResource('trufi-rutas', TrufiRutaController::class);

Route::get('trufis/{idtrufi}/rutas', [TrufiRutaController::class, 'rutasPorTrufi']);


Route::get('trufis', [TrufiController::class, 'index']);
Route::get('trufis/{id}', [TrufiController::class, 'show']);
Route::get('trufis/{idtrufi}/rutas', [TrufiRutaController::class, 'rutasPorTrufi']);
Route::get('trufi-rutas', [TrufiRutaController::class, 'index']);
Route::get('trufi-rutas/{id}', [TrufiRutaController::class, 'show']);
