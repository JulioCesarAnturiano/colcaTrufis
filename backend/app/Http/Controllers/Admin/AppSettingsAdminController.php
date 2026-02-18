<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\Request;

class AppSettingsAdminController extends Controller
{
    public function editReclamos()
    {
        $items = AppSetting::where('group', 'reclamos')
            ->orderBy('key')
            ->get();

        return view('admin.settings.reclamos', compact('items'));
    }

    public function updateReclamos(Request $request)
    {
        $data = $request->validate([
            'settings' => 'required|array',
            'settings.*.value' => 'nullable|string|max:255',
            'settings.*.activo' => 'nullable|boolean',
        ]);

        foreach ($data['settings'] as $id => $row) {
            AppSetting::where('id', $id)->update([
                'value' => $row['value'] ?? null,
                'activo' => isset($row['activo']) ? (bool)$row['activo'] : false,
                'updated_by' => optional($request->user())->id_usuario ?? null,
            ]);
        }

        return redirect()->back()->with('success', 'Números de reclamos actualizados.');
    }
}
