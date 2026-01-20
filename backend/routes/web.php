<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Auth;

use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\FilePondController;
use App\Http\Controllers\Admin\TrufiAdminController;
use App\Http\Controllers\Admin\RutaAdminController;

Route::get('/', function () {
    return view('welcome');
});

// Si tienes Breeze/Jetstream, este archivo existe.
// Si no existe, déjalo, pero si te da error coméntalo.
require __DIR__ . '/auth.php';

// ===========================
// LOGIN ADMIN (PÚBLICO)
// ===========================
// Si ya usas Breeze y su login, puedes borrar estas 2 rutas y usar /login normal.
Route::get('/admin/login', [LoginController::class, 'mostrarFormulario'])->name('login');
Route::post('/admin/login', [LoginController::class, 'autenticar'])->name('login.submit');

// ===========================
// PANEL ADMIN (PROTEGIDO)
// auth = debe estar logueado
// role:admin|encargado = debe tener rol Spatie
// ===========================
Route::middleware(['auth', 'role:admin|encargado'])
    ->prefix('admin')
    ->name('admin.')
    ->group(function () {

        // Dashboard
        Route::get('/dashboard', [DashboardController::class, 'mostrarDashboard'])->name('dashboard');

        // Logout
        Route::post('/logout', function () {
            Auth::logout();
            request()->session()->invalidate();
            request()->session()->regenerateToken();
            return redirect()->route('login');
        })->name('logout');

        // ===========================
        // FILEPOND (PROTEGIDO)
        // ===========================
        Route::post('/filepond/upload', [FilePondController::class, 'subirArchivo'])->name('filepond.upload');
        Route::delete('/filepond/revert', [FilePondController::class, 'eliminarArchivo'])->name('filepond.revert');

        // ===========================
        // TRUFIS ADMIN (BLADE)
        // ===========================
        Route::get('/trufis', [TrufiAdminController::class, 'listarTrufis'])->name('trufis.index');
        Route::get('/trufis/crear', [TrufiAdminController::class, 'mostrarCrear'])->name('trufis.crear');
        Route::post('/trufis', [TrufiAdminController::class, 'guardarTrufi'])->name('trufis.guardar');

        Route::get('/trufis/{id}/editar', [TrufiAdminController::class, 'mostrarEditar'])->name('trufis.editar');
        Route::put('/trufis/{id}', [TrufiAdminController::class, 'actualizarTrufi'])->name('trufis.actualizar');
        Route::delete('/trufis/{id}', [TrufiAdminController::class, 'eliminarTrufi'])->name('trufis.eliminar');

        // ===========================
        // RUTAS ADMIN (BLADE)
        // ===========================
        Route::get('/rutas', [RutaAdminController::class, 'listarRutas'])->name('rutas.index');
        Route::get('/rutas/crear', [RutaAdminController::class, 'mostrarCrearRuta'])->name('rutas.crear');
        Route::post('/rutas', [RutaAdminController::class, 'guardarRuta'])->name('rutas.guardar');

        Route::get('/rutas/{id}/editar', [RutaAdminController::class, 'mostrarEditarRuta'])->name('rutas.editar');
        Route::put('/rutas/{id}', [RutaAdminController::class, 'actualizarRuta'])->name('rutas.actualizar');
        Route::delete('/rutas/{id}', [RutaAdminController::class, 'eliminarRuta'])->name('rutas.eliminar');
    });
