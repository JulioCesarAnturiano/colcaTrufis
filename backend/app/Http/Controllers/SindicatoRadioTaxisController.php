<?php

namespace App\Http\Controllers;

use App\Models\SindicatoRadioTaxi;
use Illuminate\Http\Request;

class SindicatoRadioTaxisController extends Controller
{
    // GET /api/sindicato-radiotaxis
   public function index()
{
    return response()->json(SindicatoRadioTaxi::all());
}


    // POST /api/sindicato-radiotaxis
    public function store(Request $request)
    {
        $data = $request->validate([
            'nombre_comercial' => ['required', 'string', 'max:255'],
            'telefono_base' => ['required', 'string', 'max:255'],
        ]);

        $sindicatoRadioTaxi = SindicatoRadioTaxi::create($data);

        return response()->json($sindicatoRadioTaxi, 201);
    }

    // GET /api/sindicato-radiotaxis/{id}
    public function show($id)
    {
        return response()->json(
            SindicatoRadioTaxi::with('trufiRutas.trufi')->findOrFail($id)
        );
    }

    // PUT/PATCH /api/sindicato-radiotaxis/{id}
    public function update(Request $request, $id)
    {
        $sindicatoRadioTaxi = SindicatoRadioTaxi::findOrFail($id);

        $data = $request->validate([
            'nombre_comercial' => ['sometimes', 'required', 'string', 'max:255'],
            'telefono_base' => ['sometimes', 'required', 'string', 'max:255'],
        ]);

        $sindicatoRadioTaxi->update($data);

        return response()->json($sindicatoRadioTaxi);
    }

    // DELETE /api/sindicato-radiotaxis/{id}
    public function destroy($id)
    {
        $sindicatoRadioTaxi = SindicatoRadioTaxi::findOrFail($id);
        $sindicatoRadioTaxi->delete();

        return response()->json(['message' => 'SindicatoRadioTaxi eliminado']);
    }
}
