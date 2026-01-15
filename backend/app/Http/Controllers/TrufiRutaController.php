<?php

namespace App\Http\Controllers;

use App\Models\Trufi;
use App\Models\TrufiRuta;
use Illuminate\Http\Request;

class TrufiRutaController extends Controller
{
    // GET /api/trufi-rutas
    public function index()
    {
        return response()->json(
            TrufiRuta::with('trufi')->orderBy('idtrufi')->orderBy('orden')->get()
        );
    }

    // POST /api/trufi-rutas
    public function store(Request $request)
    {
        $ruta = TrufiRuta::create($request->all());
        return response()->json($ruta, 201);
    }

    // GET /api/trufi-rutas/{id}
    public function show($id)
    {
        return response()->json(
            TrufiRuta::with('trufi')->findOrFail($id)
        );
    }

    // PUT/PATCH /api/trufi-rutas/{id}
    public function update(Request $request, $id)
    {
        $ruta = TrufiRuta::findOrFail($id);
        $ruta->update($request->all());
        return response()->json($ruta);
    }

    // DELETE /api/trufi-rutas/{id}
    public function destroy($id)
    {
        $ruta = TrufiRuta::findOrFail($id);
        $ruta->delete();
        return response()->json(['message' => 'Ruta eliminada']);
    }

    // GET /api/trufis/{idtrufi}/rutas  (rutas por trufi)
    public function rutasPorTrufi($idtrufi)
    {
        // valida que exista el trufi
        Trufi::findOrFail($idtrufi);

        return response()->json(
            TrufiRuta::where('idtrufi', $idtrufi)
                ->orderBy('orden')
                ->get()
        );
    }
}
