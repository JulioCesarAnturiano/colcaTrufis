<?php

namespace App\Http\Controllers;

use App\Models\AppSetting;

class AppSettingsController extends Controller
{
    // GET /api/public/settings/reclamos
    public function reclamos()
{
    $items = \App\Models\AppSetting::query()
        ->where('group', 'reclamos')
        ->get(['id', 'key', 'value', 'activo']);

    return response()->json([
        'success' => true,
        'data' => $items->map(function ($item) {
            return [
                'key'     => $item->key,
                'value'   => $item->value,
                'activo'  => (bool) $item->activo,
            ];
        }),
    ]);
}

}
