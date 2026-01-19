<?php

use App\Http\Controllers\ProfileController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/dashboard', function () {
    return view('dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

Route::middleware(['auth', 'role:admin|encargado'])->group(function () {
    Route::post('/admin/trufis', [TrufiController::class, 'store']);
    Route::put('/admin/trufis/{id}', [TrufiController::class, 'update']);
    Route::delete('/admin/trufis/{id}', [TrufiController::class, 'destroy']);
});

require __DIR__.'/auth.php';
