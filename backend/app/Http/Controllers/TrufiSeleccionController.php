<?php

namespace App\Http\Controllers;

use App\Models\TrufiSeleccion;
use Illuminate\Http\Request;

class TrufiSeleccionController extends Controller
{
    public function registrar(Request $request, $idtrufi)
    {
        // Validación simple (sin obligar device_id, pero recomendado)
        $data = $request->validate([
            'device_id' => 'nullable|string|max:80',
            'source'    => 'nullable|string|max:20',
        ]);

        TrufiSeleccion::create([
            'idtrufi'   => (int) $idtrufi,
            'device_id' => $data['device_id'] ?? null,
            'source'    => $data['source'] ?? 'flutter',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Selección registrada',
        ]);
    }
}
