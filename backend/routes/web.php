<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\FilePondController;
use App\Http\Controllers\TrufiAdminController;
use App\Http\Controllers\RutaAdminController;
use Illuminate\Support\Facades\Auth;

// ===========================================
// RUTAS PÚBLICAS
// ===========================================
Route::get('/admin/login', [LoginController::class, 'mostrarFormulario'])->name('login');
Route::post('/admin/login', [LoginController::class, 'autenticar'])->name('login.submit');

// ===========================================
// FUNCIÓN PARA VERIFICAR ACCESO ADMIN
// ===========================================
function verificarAdminAcceso()
{
    if (!Auth::check()) {
        return redirect()->route('login');
    }
    
    $usuario = Auth::user();
    if (!in_array($usuario->rol, ['admin', 'encargado'])) {
        // Limpiar sesión
        Auth::logout();
        session()->invalidate();
        session()->regenerateToken();
        
        return redirect()->route('login')
            ->with('error', 'Acceso no autorizado al panel admin');
    }
    
    return null; // Todo OK
}

// ===========================================
// RUTAS PROTEGIDAS - CON VERIFICACIÓN MANUAL
// ===========================================

// Logout
Route::post('/admin/logout', function () {
    Auth::logout();
    session()->invalidate();
    session()->regenerateToken();
    return redirect()->route('login');
})->name('admin.logout');

// Dashboard
Route::get('/admin/dashboard', function () {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(DashboardController::class)->mostrarDashboard();
})->name('admin.dashboard');

// FilePond
Route::post('/admin/filepond/upload', function (Illuminate\Http\Request $request) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(FilePondController::class)->subirArchivo($request);
})->name('admin.filepond.upload');

Route::delete('/admin/filepond/revert', function (Illuminate\Http\Request $request) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(FilePondController::class)->eliminarArchivo($request);
})->name('admin.filepond.revert');

// Trufis - Rutas individuales
Route::get('/admin/trufis', function () {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(TrufiAdminController::class)->listarTrufis();
})->name('admin.trufis.index');

Route::get('/admin/trufis/crear', function () {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(TrufiAdminController::class)->mostrarCrear();
})->name('admin.trufis.crear');

Route::post('/admin/trufis', function (Illuminate\Http\Request $request) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(TrufiAdminController::class)->guardarTrufi($request);
})->name('admin.trufis.guardar');

Route::get('/admin/trufis/{id}/editar', function ($id) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(TrufiAdminController::class)->mostrarEditar($id);
})->name('admin.trufis.editar');

Route::put('/admin/trufis/{id}', function (Illuminate\Http\Request $request, $id) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(TrufiAdminController::class)->actualizarTrufi($request, $id);
})->name('admin.trufis.actualizar');

Route::delete('/admin/trufis/{id}', function ($id) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(TrufiAdminController::class)->eliminarTrufi($id);
})->name('admin.trufis.eliminar');

// Rutas - Rutas individuales
Route::get('/admin/rutas', function (Illuminate\Http\Request $request) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(RutaAdminController::class)->listarRutas($request);
})->name('admin.rutas.index');

Route::get('/admin/rutas/crear', function () {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(RutaAdminController::class)->mostrarCrearRuta();
})->name('admin.rutas.crear');

Route::post('/admin/rutas', function (Illuminate\Http\Request $request) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(RutaAdminController::class)->guardarRuta($request);
})->name('admin.rutas.guardar');

Route::get('/admin/rutas/{id}/editar', function ($id) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(RutaAdminController::class)->mostrarEditarRuta($id);
})->name('admin.rutas.editar');

Route::put('/admin/rutas/{id}', function (Illuminate\Http\Request $request, $id) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(RutaAdminController::class)->actualizarRuta($request, $id);
})->name('admin.rutas.actualizar');

Route::delete('/admin/rutas/{id}', function ($id) {
    $verificacion = verificarAdminAcceso();
    if ($verificacion) return $verificacion;
    return app()->make(RutaAdminController::class)->eliminarRuta($id);
})->name('admin.rutas.eliminar');

// ===========================================
// RUTAS API (mantén tus rutas existentes)
// ===========================================
Route::prefix('api')->group(function () {
    // Tus rutas API actuales aquí - NO las cambies
    // Route::get('/trufis', [App\Http\Controllers\TrufiController::class, 'index']);
    // Route::get('/trufis/{id}', [App\Http\Controllers\TrufiController::class, 'show']);
});