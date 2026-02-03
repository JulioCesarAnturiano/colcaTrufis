<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trufi;
use App\Models\Sindicato;
use Illuminate\Http\Request;

class TrufiAdminController extends Controller
{
    // Listar trufis
    public function listarTrufis()
    {
        $usuario = request()->user();

        if (!$usuario) {
            return redirect()->route('login');
        }

        $trufis = Trufi::with('sindicato')
            ->orderBy('nom_linea')
            ->paginate(10);

        return view('admin.trufis.index', [
            'trufis' => $trufis,
            'usuario' => $usuario
        ]);
    }


    public function mostrarCrear()
{
    $usuario = request()->user();
    if (!$usuario) return redirect()->route('login');

    $sindicatos = Sindicato::orderBy('nombre')->get();

    return view('admin.trufis.create', [
        'usuario' => $usuario,
        'sindicatos' => $sindicatos,
    ]);
}


    // Guardar trufi
    public function guardarTrufi(Request $request)
    {
        $usuario = $request->user();
        if (!$usuario) {
            return redirect()->route('login');
        }

        $request->validate([
            'nom_linea'    => 'required|string|max:255',
            'costo'        => 'required|numeric|min:0',
            'frecuencia'   => 'required|integer|min:1',
            'tipo'         => 'required|string|max:255',
            'descripcion'  => 'nullable|string',
            'sindicato_id' => 'required|exists:sindicatos,id',
            'estado'       => 'nullable|in:0,1',
        ]);

        Trufi::create([
            'nom_linea'    => $request->nom_linea,
            'costo'        => $request->costo,
            'frecuencia'   => $request->frecuencia,
            'tipo'         => $request->tipo,
            'descripcion'  => $request->descripcion,
            'sindicato_id' => $request->sindicato_id,
            'estado'       => $request->estado ?? 1,
        ]);

        return redirect()->route('admin.trufis.index')
            ->with('success', 'Trufi creado exitosamente');
    }

    // Mostrar formulario editar
    public function mostrarEditar($id)
{
    $usuario = request()->user();
    if (!$usuario) return redirect()->route('login');

    $trufi = Trufi::findOrFail($id);
    $sindicatos = Sindicato::orderBy('nombre')->get();

    return view('admin.trufis.edit', [
        'trufi' => $trufi,
        'usuario' => $usuario,
        'sindicatos' => $sindicatos,
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

        $request->validate([
            'nom_linea'    => 'required|string|max:255',
            'costo'        => 'required|numeric|min:0',
            'frecuencia'   => 'required|integer|min:1',
            'tipo'         => 'required|string|max:255',
            'descripcion'  => 'nullable|string',
            'sindicato_id' => 'required|exists:sindicatos,id',
            'estado'       => 'nullable|in:0,1',
        ]);

        $trufi->update([
            'nom_linea'    => $request->nom_linea,
            'costo'        => $request->costo,
            'frecuencia'   => $request->frecuencia,
            'tipo'         => $request->tipo,
            'descripcion'  => $request->descripcion,
            'sindicato_id' => $request->sindicato_id,
            'estado'       => $request->estado ?? 1,
        ]);

        return redirect()->route('admin.trufis.index')
            ->with('success', 'Trufi actualizado exitosamente');
    }

    // Eliminar trufi
    public function eliminarTrufi($id)
    {
        $usuario = request()->user();

        if (!$usuario || !$usuario->hasRole('admin')) {
            return redirect()->route('login')->with('error', 'No autorizado');
        }

        $trufi = Trufi::findOrFail($id);
        $trufi->delete();

        return redirect()->route('admin.trufis.index')
            ->with('success', 'Trufi eliminado');
    }
}
