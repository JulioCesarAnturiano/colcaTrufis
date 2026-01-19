<?php

namespace App\Http\Controllers;

use App\Models\Trufi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class TrufiAdminController extends Controller
{
    // Listar trufis
    public function listarTrufis()
    {
        $usuario = request()->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        $trufis = Trufi::orderBy('nombre')->paginate(10);
        
        return view('admin.trufis.index', [
            'trufis' => $trufis,
            'usuario' => $usuario
        ]);
    }
    
    // Mostrar formulario crear
    public function mostrarCrear()
    {
        $usuario = request()->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        return view('admin.trufis.crear', ['usuario' => $usuario]);
    }
    
    // Guardar trufi
    public function guardarTrufi(Request $request)
    {
        $usuario = $request->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        // Validar
        $request->validate([
            'nombre' => 'required|string|max:100',
            'tipo' => 'required|in:trufi,radiomovil',
            'costo' => 'required|numeric|min:0',
            'frecuencia' => 'required|integer|min:1',
            'nombre_sindicato' => 'required|string|max:100',
        ]);
        
        // Crear trufi
        $trufi = Trufi::create([
            'nombre' => $request->nombre,
            'tipo' => $request->tipo,
            'costo' => $request->costo,
            'frecuencia' => $request->frecuencia,
            'descripcion' => $request->descripcion,
            'nombre_sindicato' => $request->nombre_sindicato,
            'estado' => $request->has('estado') ? 1 : 0,
            'creado_por' => $usuario->id,
            'actualizado_por' => $usuario->id,
        ]);
        
        // Procesar imagen si existe
        if ($request->imagen_temp) {
            $this->procesarImagen($trufi, $request->imagen_temp);
        }
        
        return redirect()->route('admin.trufis.index')
            ->with('success', 'Trufi creado exitosamente');
    }
    
    // Mostrar formulario editar
    public function mostrarEditar($id)
    {
        $usuario = request()->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        $trufi = Trufi::findOrFail($id);
        
        return view('admin.trufis.editar', [
            'trufi' => $trufi,
            'usuario' => $usuario
        ]);
    }
    
    // Actualizar trufi
    public function actualizarTrufi(Request $request, $id)
    {
        $usuario = $request->user();
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        $trufi = Trufi::findOrFail($id);
        
        // Validar
        $request->validate([
            'nombre' => 'required|string|max:100',
            'tipo' => 'required|in:trufi,radiomovil',
            'costo' => 'required|numeric|min:0',
            'frecuencia' => 'required|integer|min:1',
            'nombre_sindicato' => 'required|string|max:100',
        ]);
        
        // Actualizar
        $trufi->update([
            'nombre' => $request->nombre,
            'tipo' => $request->tipo,
            'costo' => $request->costo,
            'frecuencia' => $request->frecuencia,
            'descripcion' => $request->descripcion,
            'nombre_sindicato' => $request->nombre_sindicato,
            'estado' => $request->has('estado') ? 1 : 0,
            'actualizado_por' => $usuario->id,
        ]);
        
        // Procesar imagen
        if ($request->imagen_temp) {
            $this->procesarImagen($trufi, $request->imagen_temp);
        }
        
        return redirect()->route('admin.trufis.index')
            ->with('success', 'Trufi actualizado exitosamente');
    }
    
    // Eliminar trufi
    public function eliminarTrufi($id)
    {
        $usuario = request()->user();
        
        if (!$usuario || !$usuario->esAdmin()) {
            return redirect()->route('login')
                ->with('error', 'No autorizado');
        }
        
        $trufi = Trufi::findOrFail($id);
        $trufi->delete();
        
        return redirect()->route('admin.trufis.index')
            ->with('success', 'Trufi eliminado');
    }
    
    // Método auxiliar para procesar imagen
    private function procesarImagen($trufi, $nombreTemporal)
    {
        $rutaOrigen = 'temp/' . $nombreTemporal;
        $rutaDestino = 'trufis/' . $trufi->idtrufi . '_' . time() . '.jpg';
        
        if (Storage::disk('public')->exists($rutaOrigen)) {
            Storage::disk('public')->move($rutaOrigen, $rutaDestino);
            
            $trufi->update([
                'imagen_url' => Storage::url($rutaDestino),
                'imagen_path' => $rutaDestino
            ]);
        }
    }
}