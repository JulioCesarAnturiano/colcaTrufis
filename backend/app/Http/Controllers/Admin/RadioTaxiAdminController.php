<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\SindicatoRadioTaxi;
use App\Models\SindicatoRadiotaxiParada;

class RadioTaxiAdminController extends Controller
{
    public function index(Request $request)
    {
        $usuario = $request->user();
        if (!$usuario) return redirect()->route('login');

        $radiotaxis = DB::table('sindicato_radiotaxis')->orderBy('nombre_comercial')->paginate(20);

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
        $request->validate([
    'nombre_comercial' => ['required','string','max:255'],
    'telefono_base' => ['required','string','max:50'],
    'latitud' => ['required','numeric'],
    'longitud' => ['required','numeric'],
]);

        DB::table('sindicato_radiotaxis')->insert([
            'nombre_comercial' => $request->nombre_comercial,
            'telefono_base' => $request->telefono_base,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return redirect()->route('admin.radiotaxis.index')->with('success', 'RadioTaxi creado correctamente.');
    }



public function edit($id)
{
    $radiotaxi = SindicatoRadioTaxi::with('parada')->findOrFail($id);

    return view('admin.radiotaxis.edit', compact('radiotaxi'));
}


    public function update(Request $request, $id)
{
    $request->validate([
        'nombre_comercial' => ['required','string','max:255'],
        'telefono_base' => ['required','string','max:255'],
        'latitud' => ['required','numeric'],
        'longitud' => ['required','numeric'],
    ]);

    $radiotaxi = SindicatoRadioTaxi::findOrFail($id);

    $radiotaxi->update([
        'nombre_comercial' => $request->nombre_comercial,
        'telefono_base' => $request->telefono_base,
    ]);

    SindicatoRadiotaxiParada::updateOrCreate(
        ['sindicato_radiotaxi_id' => $radiotaxi->id],
        [
            'latitud' => $request->latitud,
            'longitud' => $request->longitud,
            'estado' => true,
        ]
    );

    return redirect()->route('admin.radiotaxis.index')
        ->with('success', 'RadioTaxi actualizado correctamente.');
}

    public function destroy(Request $request, $id)
    {
        DB::table('sindicato_radiotaxis')->where('id', $id)->delete();

        return redirect()->route('admin.radiotaxis.index')->with('success', 'RadioTaxi eliminado correctamente.');
    }
}
