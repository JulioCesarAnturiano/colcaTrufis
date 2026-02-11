<?php
// routes/web.php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\TrufiAdminController;
use App\Http\Controllers\Admin\RutaAdminController;
use App\Http\Controllers\Admin\FilePondController;
use App\Http\Controllers\Admin\UsuarioAdminController;
use App\Http\Controllers\Admin\SindicatoAdminController;
use App\Http\Controllers\Admin\RadioTaxiAdminController;
use App\Http\Controllers\Admin\NormativaAdminController;

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
    // RUTAS (CRUD)  ✅ (PK compuesta: idtrufi + orden)
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

    Route::get('/rutas/{idtrufi}/editar', [RutaAdminController::class, 'mostrarEditarRuta'])
    ->middleware('permission:admin.rutas.editar')
    ->name('admin.rutas.editar');

    Route::put('/rutas/{idtrufi}', [RutaAdminController::class, 'actualizarRuta'])
    ->middleware('permission:admin.rutas.editar')
    ->name('admin.rutas.actualizar');

    Route::delete('/rutas/{idtrufi}', [RutaAdminController::class, 'eliminarRuta'])
    ->middleware('permission:admin.rutas.eliminar')
    ->name('admin.rutas.eliminar');

    // ===========================
// SINDICATOS (CRUD)
// ===========================
Route::get('/sindicatos', [SindicatoAdminController::class, 'index'])
    ->middleware('permission:admin.sindicatos.ver')
    ->name('admin.sindicatos.index');

Route::get('/sindicatos/crear', [SindicatoAdminController::class, 'create'])
    ->middleware('permission:admin.sindicatos.crear')
    ->name('admin.sindicatos.crear');

Route::post('/sindicatos', [SindicatoAdminController::class, 'store'])
    ->middleware('permission:admin.sindicatos.crear')
    ->name('admin.sindicatos.guardar');

Route::get('/sindicatos/{id}/editar', [SindicatoAdminController::class, 'edit'])
    ->middleware('permission:admin.sindicatos.editar')
    ->name('admin.sindicatos.editar');

Route::put('/sindicatos/{id}', [SindicatoAdminController::class, 'update'])
    ->middleware('permission:admin.sindicatos.editar')
    ->name('admin.sindicatos.actualizar');

Route::delete('/sindicatos/{id}', [SindicatoAdminController::class, 'destroy'])
    ->middleware('permission:admin.sindicatos.eliminar')
    ->name('admin.sindicatos.eliminar');


// ===========================
// SINDICATO RADIOTAXIS (CRUD)
// ===========================
Route::get('/radiotaxis', [RadioTaxiAdminController::class, 'index'])
    ->middleware('permission:admin.radiotaxis.ver')
    ->name('admin.radiotaxis.index');

Route::get('/radiotaxis/crear', [RadioTaxiAdminController::class, 'create'])
    ->middleware('permission:admin.radiotaxis.crear')
    ->name('admin.radiotaxis.crear');

Route::post('/radiotaxis', [RadioTaxiAdminController::class, 'store'])
    ->middleware('permission:admin.radiotaxis.crear')
    ->name('admin.radiotaxis.guardar');

Route::get('/radiotaxis/{id}/editar', [RadioTaxiAdminController::class, 'edit'])
    ->middleware('permission:admin.radiotaxis.editar')
    ->name('admin.radiotaxis.editar');

Route::put('/radiotaxis/{id}', [RadioTaxiAdminController::class, 'update'])
    ->middleware('permission:admin.radiotaxis.editar')
    ->name('admin.radiotaxis.actualizar');

Route::delete('/radiotaxis/{id}', [RadioTaxiAdminController::class, 'destroy'])
    ->middleware('permission:admin.radiotaxis.eliminar')
    ->name('admin.radiotaxis.eliminar');



    // ===========================
    // USUARIOS (CRUD)
    // ===========================
    Route::get('/usuarios', [UsuarioAdminController::class, 'index'])
        ->middleware('permission:admin.usuarios.ver')
        ->name('admin.usuarios.index');

    Route::get('/usuarios/crear', [UsuarioAdminController::class, 'create'])
        ->middleware('permission:admin.usuarios.crear')
        ->name('admin.usuarios.crear');

    Route::post('/usuarios', [UsuarioAdminController::class, 'store'])
        ->middleware('permission:admin.usuarios.crear')
        ->name('admin.usuarios.guardar');

    Route::get('/usuarios/{id}/editar', [UsuarioAdminController::class, 'edit'])
        ->middleware('permission:admin.usuarios.editar')
        ->name('admin.usuarios.editar');

    Route::put('/usuarios/{id}', [UsuarioAdminController::class, 'update'])
        ->middleware('permission:admin.usuarios.editar')
        ->name('admin.usuarios.actualizar');

    Route::delete('/usuarios/{id}', [UsuarioAdminController::class, 'destroy'])
        ->middleware('permission:admin.usuarios.eliminar')
        ->name('admin.usuarios.eliminar');
        Route::get('/normativas', [NormativaAdminController::class, 'index'])
    ->middleware('permission:admin.normativas.ver')
    ->name('admin.normativas.index');

Route::get('/normativas/crear', [NormativaAdminController::class, 'create'])
    ->middleware('permission:admin.normativas.crear')
    ->name('admin.normativas.crear');

Route::post('/normativas', [NormativaAdminController::class, 'store'])
    ->middleware('permission:admin.normativas.crear')
    ->name('admin.normativas.store');

Route::get('/normativas/{id}/editar', [NormativaAdminController::class, 'edit'])
    ->middleware('permission:admin.normativas.editar')
    ->name('admin.normativas.editar');

Route::put('/normativas/{id}', [NormativaAdminController::class, 'update'])
    ->middleware('permission:admin.normativas.editar')
    ->name('admin.normativas.update');

Route::delete('/normativas/{id}', [NormativaAdminController::class, 'destroy'])
    ->middleware('permission:admin.normativas.eliminar')
    ->name('admin.normativas.destroy');
    Route::get('/normativas/{id}/ver', [NormativaAdminController::class, 'verPdf'])
    ->middleware('permission:admin.normativas.ver')
    ->name('admin.normativas.verPdf');

    
});
