<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;

use App\Models\Trufi;
use App\Models\TrufiRuta;
use Illuminate\Http\Request;

class RutaAdminController extends Controller
{
    // Listar rutas
    public function listarRutas(Request $request)
    {
        $usuario = $request->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        $trufiId = $request->query('trufi_id');
        
        $query = TrufiRuta::query();
        
        if ($trufiId) {
            $query->where('idtrufi', $trufiId);
        }
        
        $rutas = $query->orderBy('orden')->paginate(20);
        $trufis = Trufi::orderBy('nombre')->get();
        
        return view('admin.rutas.index', [
            'rutas' => $rutas,
            'trufis' => $trufis,
            'trufiId' => $trufiId,
            'usuario' => $usuario
        ]);
    }
    
    // Mostrar formulario crear
    public function mostrarCrearRuta()
    {
        $usuario = request()->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        $trufis = Trufi::orderBy('nombre')->get();
        
        return view('admin.rutas.create', [
            'trufis' => $trufis,
            'usuario' => $usuario
        ]);
    }
    
    // Guardar ruta
    public function guardarRuta(Request $request)
    {
        $usuario = $request->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        $request->validate([
            'idtrufi' => 'required|exists:trufis,idtrufi',
            'latitud' => 'required|numeric',
            'longitud' => 'required|numeric',
            'orden' => 'required|integer',
        ]);
        
        TrufiRuta::create([
            'idtrufi' => $request->idtrufi,
            'latitud' => $request->latitud,
            'longitud' => $request->longitud,
            'orden' => $request->orden,
            'es_parada' => $request->has('es_parada') ? 1 : 0,
            'estado' => $request->has('estado') ? 1 : 0,
        ]);
        
        return redirect()->route('admin.rutas.index', ['trufi_id' => $request->idtrufi])
            ->with('success', 'Ruta creada exitosamente');
    }
    
    // Mostrar formulario editar
    public function mostrarEditarRuta($id)
    {
        $usuario = request()->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        $ruta = TrufiRuta::with('trufi')->findOrFail($id);
        $trufis = Trufi::orderBy('nombre')->get();
        
        return view('admin.rutas.edit', [
            'ruta' => $ruta,
            'trufis' => $trufis,
            'usuario' => $usuario
        ]);
    }
    
    // Actualizar ruta
    public function actualizarRuta(Request $request, $id)
    {
        $usuario = $request->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        $ruta = TrufiRuta::findOrFail($id);
        
        $request->validate([
            'idtrufi' => 'required|exists:trufis,idtrufi',
            'latitud' => 'required|numeric',
            'longitud' => 'required|numeric',
            'orden' => 'required|integer',
        ]);
        
        $ruta->update([
            'idtrufi' => $request->idtrufi,
            'latitud' => $request->latitud,
            'longitud' => $request->longitud,
            'orden' => $request->orden,
            'es_parada' => $request->has('es_parada') ? 1 : 0,
            'estado' => $request->has('estado') ? 1 : 0,
        ]);
        
        return redirect()->route('admin.rutas.index', ['trufi_id' => $request->idtrufi])
            ->with('success', 'Ruta actualizada exitosamente');
    }
    
    // Eliminar ruta
    public function eliminarRuta($id)
    {
        $usuario = request()->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        $ruta = TrufiRuta::findOrFail($id);
        $trufiId = $ruta->idtrufi;
        $ruta->delete();
        
        return redirect()->route('admin.rutas.index', ['trufi_id' => $trufiId])
            ->with('success', 'Ruta eliminada');
    }
}