<?php

namespace App\Http\Controllers;

use App\Models\Referencia;
use App\Models\Trufi;
use App\Models\Sindicatoradiotaxi;
use Illuminate\Http\Request;

class ReferenciaController extends Controller
{
    // GET /api/referencias
    public function index(Request $request)
    {
        $perPage = (int) $request->query('per_page', 20);

        $referencias = Referencia::query()
            ->select(['id', 'referencia', 'referenciable_type', 'referenciable_id', 'latitud', 'longitud', 'created_at'])
            ->orderByDesc('id')
            ->paginate($perPage);

        return response()->json($referencias);
    }

    // GET /api/referencias/{id}
    public function show($id)
    {
        $ref = Referencia::query()
            ->select(['id', 'referencia', 'referenciable_type', 'referenciable_id', 'latitud', 'longitud', 'created_at'])
            ->findOrFail($id);

        return response()->json($ref);
    }

    // GET /api/trufis/{idtrufi}/referencias
public function byTrufi($idtrufi, Request $request)
{
    $perPage = (int) $request->query('per_page', 50);

    // Verifica Que Exista El Trufi (Tu PK Es idtrufi)
    Trufi::where('idtrufi', $idtrufi)->firstOrFail();

    $referencias = Referencia::query()
        ->whereIn('referenciable_type', [
            Trufi::class,                 // "App\Models\Trufi"
            'App\\Models\\Trufi',         // Por Si Está Guardado En Otro Formato
            'App\\\\Models\\\\Trufi',     // Por Si Se Guardó Con Backslashes Doblados
            'trufi',                      // Si Alguna Vez Usas morphMap
        ])
        ->where('referenciable_id', $idtrufi)
        ->select(['id', 'referencia', 'latitud', 'longitud', 'created_at'])
        ->orderByDesc('id')
        ->paginate($perPage);

    return response()->json($referencias);
}

    // GET /api/radiotaxis/{id}/referencias
    public function byRadiotaxi($id, Request $request)
{
    $perPage = (int) $request->query('per_page', 50);

    Sindicatoradiotaxi::where('id', $id)->firstOrFail();

    $referencias = Referencia::query()
        ->where('referenciable_type', 'App\\\\Models\\\\Sindicatoradiotaxi')
        ->where('referenciable_id', $id)
        ->select(['id', 'referencia', 'latitud', 'longitud', 'created_at'])
        ->orderByDesc('id')
        ->paginate($perPage);

    return response()->json($referencias);
}
}