<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\TrufiAdminController;
use App\Http\Controllers\Admin\RutaAdminController;
use App\Http\Controllers\Admin\FilePondController;

Route::get('/', fn() => redirect()->route('login'));

// Login Admin
Route::get('/admin/login', [LoginController::class, 'mostrarFormulario'])->name('login');
Route::post('/admin/login', [LoginController::class, 'autenticar'])->name('login.submit');
Route::post('/admin/logout', [LoginController::class, 'cerrarSesion'])->name('admin.logout');

// Panel Admin (protegido)
Route::prefix('admin')->middleware(['auth', 'role:admin|encargado'])->group(function () {

    Route::get('/dashboard', [DashboardController::class, 'mostrarDashboard'])->name('admin.dashboard');

    // FilePond (si solo admin/encargado suben)
    Route::post('/filepond/upload', [FilePondController::class, 'subirArchivo'])
        ->middleware('permission:admin.trufis.crear|admin.rutas.crear')
        ->name('admin.filepond.upload');

    Route::delete('/filepond/revert', [FilePondController::class, 'eliminarArchivo'])
        ->middleware('permission:admin.trufis.crear|admin.rutas.crear')
        ->name('admin.filepond.revert');

    // ===========================
    // TRUFIS (CRUD)
    // ===========================
    Route::get('/trufis', [TrufiAdminController::class, 'listarTrufis'])
        ->middleware('permission:admin.trufis.ver')
        ->name('admin.trufis.index');

    Route::get('/trufis/crear', [TrufiAdminController::class, 'mostrarCrear'])
        ->middleware('permission:admin.trufis.crear')
        ->name('admin.trufis.crear');

    Route::post('/trufis', [TrufiAdminController::class, 'guardarTrufi'])
        ->middleware('permission:admin.trufis.crear')
        ->name('admin.trufis.guardar');

    Route::get('/trufis/{id}/editar', [TrufiAdminController::class, 'mostrarEditar'])
        ->middleware('permission:admin.trufis.editar')
        ->name('admin.trufis.editar');

    Route::put('/trufis/{id}', [TrufiAdminController::class, 'actualizarTrufi'])
        ->middleware('permission:admin.trufis.editar')
        ->name('admin.trufis.actualizar');

    Route::delete('/trufis/{id}', [TrufiAdminController::class, 'eliminarTrufi'])
        ->middleware('permission:admin.trufis.eliminar')
        ->name('admin.trufis.eliminar');

    // ===========================
    // RUTAS (CRUD)
    // ===========================
    Route::get('/rutas', [RutaAdminController::class, 'listarRutas'])
        ->middleware('permission:admin.rutas.ver')
        ->name('admin.rutas.index');

    Route::get('/rutas/crear', [RutaAdminController::class, 'mostrarCrearRuta'])
        ->middleware('permission:admin.rutas.crear')
        ->name('admin.rutas.crear');

    Route::post('/rutas', [RutaAdminController::class, 'guardarRuta'])
        ->middleware('permission:admin.rutas.crear')
        ->name('admin.rutas.guardar');

    Route::get('/rutas/{id}/editar', [RutaAdminController::class, 'mostrarEditarRuta'])
        ->middleware('permission:admin.rutas.editar')
        ->name('admin.rutas.editar');

    Route::put('/rutas/{id}', [RutaAdminController::class, 'actualizarRuta'])
        ->middleware('permission:admin.rutas.editar')
        ->name('admin.rutas.actualizar');

    Route::delete('/rutas/{id}', [RutaAdminController::class, 'eliminarRuta'])
        ->middleware('permission:admin.rutas.eliminar')
        ->name('admin.rutas.eliminar');
});
