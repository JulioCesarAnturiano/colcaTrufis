<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Sindicatoradiotaxi;
use App\Models\Sindicatoradiotaxiparada;


class RadioTaxiAdminController extends Controller
{
    public function index(Request $request)
{
    $usuario = $request->user();
    if (!$usuario) return redirect()->route('login');

    $radiotaxis = Sindicatoradiotaxi::with('parada')
        ->orderBy('nombre_comercial')
        ->paginate(20);

    return view('admin.radiotaxis.index', compact('radiotaxis', 'usuario'));
}


    public function create(Request $request)
    {
        $usuario = $request->user();
        if (!$usuario) return redirect()->route('login');

        return view('admin.radiotaxis.create', compact('usuario'));
    }


public function store(Request $request)
{
    $data = $request->validate([
        'nombre_comercial' => ['required','string','max:255'],
        'telefono_base' => ['required','string','max:255'],
        'latitud' => ['required','numeric'],
        'longitud' => ['required','numeric'],
        'direccion' => ['nullable','string','max:500'],
    ]);

    DB::beginTransaction();

    try {
        $radiotaxi = Sindicatoradiotaxi::create([
            'nombre_comercial' => $data['nombre_comercial'],
            'telefono_base' => $data['telefono_base'],
        ]);

        $parada = Sindicatoradiotaxiparada::updateOrCreate(
            ['sindicato_radiotaxi_id' => $radiotaxi->id],
            [
                'latitud' => $data['latitud'],
                'longitud' => $data['longitud'],
                'direccion' => $data['direccion'] ?? null,
                'estado' => 1,
            ]
        );

        DB::commit();

        return redirect()->route('admin.radiotaxis.index')
            ->with('success', 'RadioTaxi y parada registrados. Parada ID: '.$parada->id);

    } catch (\Throwable $e) {
        DB::rollBack();

        // muestra el error REAL
        dd(
            'ERROR GUARDANDO PARADA',
            $e->getMessage(),
            $e->getFile().':'.$e->getLine(),
            $e->getTraceAsString()
        );
    }
}


public function edit(Request $request, $id)
{
    $usuario = $request->user();
    if (!$usuario) return redirect()->route('login');

    $radiotaxi = Sindicatoradiotaxi::with('parada')->findOrFail($id);

    return view('admin.radiotaxis.edit', compact('radiotaxi', 'usuario'));
}


    public function update(Request $request, $id)
{
    $request->validate([
        'nombre_comercial' => ['required','string','max:255'],
        'telefono_base' => ['required','string','max:255'],
        'latitud' => ['required','numeric'],
        'longitud' => ['required','numeric'],
        'direccion' => ['nullable','string','max:500'],
    ]);

    $radiotaxi = Sindicatoradiotaxi::findOrFail($id);

    $radiotaxi->update([
        'nombre_comercial' => $request->nombre_comercial,
        'telefono_base' => $request->telefono_base,
    ]);

    Sindicatoradiotaxiparada::updateOrCreate(
        ['sindicato_radiotaxi_id' => $radiotaxi->id],
        [
            'latitud' => $request->latitud,
            'longitud' => $request->longitud,
            'direccion' => $request->direccion ?? null,
            'estado' => true,
        ]
    );

    return redirect()->route('admin.radiotaxis.index')
        ->with('success', 'RadioTaxi actualizado correctamente.');
}
public function destroy(Request $request, $id)
{
    Sindicatoradiotaxiparada::where('sindicato_radiotaxi_id', $id)->delete();
    Sindicatoradiotaxi::where('id', $id)->delete();

    return redirect()->route('admin.radiotaxis.index')
        ->with('success', 'RadioTaxi eliminado correctamente.');
}

}
