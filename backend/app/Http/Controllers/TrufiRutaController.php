<?php

namespace App\Http\Controllers;

use App\Models\Trufi;
use App\Models\TrufiRuta;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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
    public function geojsonPorTrufi($idtrufi)
{
    $puntos = DB::table('trufi_rutas')
        ->where('idtrufi', $idtrufi)
        ->orderBy('orden', 'asc')
        ->get(['longitud', 'latitud']);

    if ($puntos->isEmpty()) {
        return response()->json([
            'type' => 'FeatureCollection',
            'features' => []
        ], 404);
    }

    $coords = $puntos->map(function ($p) {
        return [(float) $p->longitud, (float) $p->latitud];
    })->values()->all();

    return response()->json([
        'type' => 'FeatureCollection',
        'features' => [
            [
                'type' => 'Feature',
                'properties' => (object) [],
                'geometry' => [
                    'type' => 'LineString',
                    'coordinates' => $coords
                ]
            ]
        ]
    ]);
}

public function geojsonTodas()
{
    $rutas = \App\Models\TrufiRuta::where('estado', 1)
        ->orderBy('idtrufi')
        ->orderBy('orden')
        ->get()
        ->groupBy('idtrufi');

    $features = [];

    foreach ($rutas as $idtrufi => $puntos) {
        $coords = $puntos->map(function ($p) {
            return [(float)$p->longitud, (float)$p->latitud]; // GeoJSON: [lng, lat]
        })->values()->all();

        if (count($coords) < 2) continue;

        $features[] = [
            "type" => "Feature",
            "properties" => [
                "idtrufi" => (int)$idtrufi,
            ],
            "geometry" => [
                "type" => "LineString",
                "coordinates" => $coords
            ]
        ];
    }

    return response()->json([
        "type" => "FeatureCollection",
        "features" => $features
    ]);
}


}
