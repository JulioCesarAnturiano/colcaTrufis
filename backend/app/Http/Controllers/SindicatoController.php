<?php

namespace App\Http\Controllers;

use App\Models\Sindicato;
use Illuminate\Http\Request;

class SindicatoController extends Controller
{
    // GET /api/sindicatos
    public function index()
    {
        return response()->json(
            Sindicato::with('trufis.rutas')->get()
        );
    }

    // POST /api/sindicatos
    public function store(Request $request)
    {
        $data = $request->validate([
            'nombre' => ['required', 'string', 'max:255'],
            'descripcion' => ['nullable', 'string'],
        ]);

        $sindicato = Sindicato::create($data);

        return response()->json($sindicato, 201);
    }

    // GET /api/sindicatos/{id}
    public function show($id)
    {
        return response()->json(
            Sindicato::with('trufis.trufiRutas')->findOrFail($id)
        );
    }

    // PUT /api/sindicatos/{id}
    public function update(Request $request, $id)
    {
        $sindicato = Sindicato::findOrFail($id);

        $data = $request->validate([
            'nombre' => ['required', 'string', 'max:255'],
            'descripcion' => ['nullable', 'string'],
        ]);

        $sindicato->update($data);

        return response()->json($sindicato);
    }

    // DELETE /api/sindicatos/{id}
    public function destroy($id)
    {
        $sindicato = Sindicato::findOrFail($id);
        $sindicato->delete();

        return response()->json(['message' => 'Sindicato eliminado']);
    }
}
