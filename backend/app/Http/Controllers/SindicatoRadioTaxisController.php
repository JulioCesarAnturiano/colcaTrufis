<?php

namespace App\Http\Controllers;

use App\Models\SindicatoRadioTaxi;
use App\Models\SindicatoRadiotaxiParada;
use Illuminate\Http\Request;

class SindicatoRadioTaxisController extends Controller
{
    // GET /api/sindicato-radiotaxis
    // Lista radiotaxis + parada (ideal para Flutter)
    public function index()
    {
        return response()->json(
            SindicatoRadioTaxi::query()
                ->with(['parada' => function ($q) {
                    $q->select('id', 'sindicato_radiotaxi_id', 'latitud', 'longitud', 'descripcion', 'estado');
                }])
                ->select('id', 'nombre_comercial', 'telefono_base', 'created_at')
                ->orderByDesc('id')
                ->get()
        );
    }

    // POST /api/sindicato-radiotaxis
    // (Si tu API pública no debe crear, puedes eliminar este método y su ruta)
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
    // Devuelve 1 radiotaxi + parada
    public function show($id)
    {
        return response()->json(
            SindicatoRadioTaxi::with(['parada' => function ($q) {
                $q->select('id', 'sindicato_radiotaxi_id', 'latitud', 'longitud', 'descripcion', 'estado');
            }])->findOrFail($id)
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



    // ==========================
    // NUEVAS RUTAS PARA PARADAS
    // ==========================

    // GET /api/sindicato-radiotaxis/paradas
    // Devuelve solo puntos (para mapa en Flutter)
    public function paradas()
    {
        return response()->json(
            SindicatoRadiotaxiParada::query()
                ->where('estado', 1)
                ->select('id', 'sindicato_radiotaxi_id', 'latitud', 'longitud', 'descripcion')
                ->orderByDesc('id')
                ->get()
        );
    }

    // GET /api/sindicato-radiotaxis/{id}/parada
    // Devuelve la parada de un radiotaxi específico
    public function paradaPorRadiotaxi($id)
    {
        $parada = SindicatoRadiotaxiParada::query()
            ->where('sindicato_radiotaxi_id', $id)
            ->where('estado', 1)
            ->select('id', 'sindicato_radiotaxi_id', 'latitud', 'longitud', 'descripcion', 'estado')
            ->first();

        if (!$parada) {
            return response()->json(['message' => 'Parada no encontrada'], 404);
        }

        return response()->json($parada);
    }
    public function paradasGeojson()
{
    $paradas = SindicatoRadiotaxiParada::query()
        ->where('estado', 1)
        ->select('id', 'sindicato_radiotaxi_id', 'latitud', 'longitud', 'descripcion')
        ->orderByDesc('id')
        ->get();

    $features = $paradas->map(function ($p) {
        return [
            "type" => "Feature",
            "properties" => [
                "id" => (int) $p->id,
                "sindicato_radiotaxi_id" => (int) $p->sindicato_radiotaxi_id,
                "descripcion" => $p->descripcion,
            ],
            "geometry" => [
                "type" => "Point",
                "coordinates" => [
                    (float) $p->longitud, // GeoJSON: [lng, lat]
                    (float) $p->latitud,
                ],
            ],
        ];
    })->values()->all();

    return response()->json([
        "type" => "FeatureCollection",
        "features" => $features,
    ]);
}

public function paradaGeojsonPorRadiotaxi($id)
{
    $p = SindicatoRadiotaxiParada::query()
        ->where('sindicato_radiotaxi_id', $id)
        ->where('estado', 1)
        ->select('id', 'sindicato_radiotaxi_id', 'latitud', 'longitud', 'descripcion')
        ->first();

    if (!$p) {
        return response()->json([
            "type" => "FeatureCollection",
            "features" => [],
        ], 404);
    }

    return response()->json([
        "type" => "FeatureCollection",
        "features" => [
            [
                "type" => "Feature",
                "properties" => [
                    "id" => (int) $p->id,
                    "sindicato_radiotaxi_id" => (int) $p->sindicato_radiotaxi_id,
                    "descripcion" => $p->descripcion,
                ],
                "geometry" => [
                    "type" => "Point",
                    "coordinates" => [
                        (float) $p->longitud,
                        (float) $p->latitud,
                    ],
                ],
            ],
        ],
    ]);
}

}
