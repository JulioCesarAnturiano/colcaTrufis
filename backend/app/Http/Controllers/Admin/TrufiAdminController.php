<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trufi;
use App\Models\Sindicato;
use App\Models\Trufidetalle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TrufiAdminController extends Controller
{
    // Listar trufis
    public function listarTrufis()
    {
        $usuario = request()->user();
        if (!$usuario) {
            return redirect()->route('login');
        }

        $trufis = Trufi::with(['sindicato', 'detalle'])
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
        if (!$usuario) {
            return redirect()->route('login');
        }

        $sindicatos = Sindicato::orderBy('nombre')->get();

        return view('admin.trufis.create', [
            'usuario' => $usuario,
            'sindicatos' => $sindicatos,
        ]);
    }

    // Guardar trufi + detalle (solo horario)
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

            // Solo horario
            'hora_entrada' => 'nullable|date_format:H:i',
            'hora_salida'  => 'nullable|date_format:H:i',
        ]);

        DB::beginTransaction();

        try {
            $trufi = Trufi::create([
                'nom_linea'    => $request->nom_linea,
                'costo'        => $request->costo,
                'frecuencia'   => $request->frecuencia,
                'tipo'         => $request->tipo,
                'descripcion'  => $request->descripcion,
                'sindicato_id' => $request->sindicato_id,
                'estado'       => $request->estado ?? 1,
            ]);

            // Si al menos uno de los horarios viene, guardamos detalle
            if ($request->filled('hora_entrada') || $request->filled('hora_salida')) {
                Trufidetalle::updateOrCreate(
                    ['trufi_id' => $trufi->idtrufi],
                    [
                        'hora_entrada' => $request->hora_entrada,
                        'hora_salida'  => $request->hora_salida,
                    ]
                );
            }

            DB::commit();

            return redirect()->route('admin.trufis.index')
                ->with('success', 'Trufi creado exitosamente');
        } catch (\Throwable $e) {
            DB::rollBack();

            return back()
                ->withInput()
                ->with('error', 'Ocurrió un error al crear el trufi: ' . $e->getMessage());
        }
    }

    // Mostrar formulario editar
    public function mostrarEditar($id)
    {
        $usuario = request()->user();
        if (!$usuario) {
            return redirect()->route('login');
        }

        // PK real: idtrufi
        $trufi = Trufi::with('detalle')->where('idtrufi', $id)->firstOrFail();
        $sindicatos = Sindicato::orderBy('nombre')->get();

        return view('admin.trufis.edit', [
            'trufi' => $trufi,
            'usuario' => $usuario,
            'sindicatos' => $sindicatos,
        ]);
    }

    // Actualizar trufi + detalle (solo horario)
    public function actualizarTrufi(Request $request, $id)
    {
        $usuario = $request->user();
        if (!$usuario) {
            return redirect()->route('login');
        }

        // PK real: idtrufi
        $trufi = Trufi::where('idtrufi', $id)->firstOrFail();

        $request->validate([
            'nom_linea'    => 'required|string|max:255',
            'costo'        => 'required|numeric|min:0',
            'frecuencia'   => 'required|integer|min:1',
            'tipo'         => 'required|string|max:255',
            'descripcion'  => 'nullable|string',
            'sindicato_id' => 'required|exists:sindicatos,id',
            'estado'       => 'nullable|in:0,1',

            // Solo horario
            'hora_entrada' => 'nullable|date_format:H:i',
            'hora_salida'  => 'nullable|date_format:H:i',
        ]);

        DB::beginTransaction();

        try {
            $trufi->update([
                'nom_linea'    => $request->nom_linea,
                'costo'        => $request->costo,
                'frecuencia'   => $request->frecuencia,
                'tipo'         => $request->tipo,
                'descripcion'  => $request->descripcion,
                'sindicato_id' => $request->sindicato_id,
                'estado'       => $request->estado ?? 1,
            ]);

            // Si al menos uno de los horarios viene, guardamos detalle
            if ($request->filled('hora_entrada') || $request->filled('hora_salida')) {
                Trufidetalle::updateOrCreate(
                    ['trufi_id' => $trufi->idtrufi],
                    [
                        'hora_entrada' => $request->hora_entrada,
                        'hora_salida'  => $request->hora_salida,
                    ]
                );
            }

            DB::commit();

            return redirect()->route('admin.trufis.index')
                ->with('success', 'Trufi actualizado exitosamente');
        } catch (\Throwable $e) {
            DB::rollBack();

            return back()
                ->withInput()
                ->with('error', 'Ocurrió un error al actualizar el trufi: ' . $e->getMessage());
        }
    }

    // Eliminar trufi
    public function eliminarTrufi($id)
    {
        $usuario = request()->user();

        if (!$usuario || !$usuario->hasRole('admin')) {
            return redirect()->route('login')->with('error', 'No autorizado');
        }

        // PK real: idtrufi
        $trufi = Trufi::where('idtrufi', $id)->firstOrFail();
        $trufi->delete();

        return redirect()->route('admin.trufis.index')
            ->with('success', 'Trufi eliminado');
    }
}