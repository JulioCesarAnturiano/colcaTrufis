<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trufi;
use App\Models\TrufiRuta;

class DashboardController extends Controller
{
    public function mostrarDashboard()
    {
        $usuario = auth()->user();

        if (! $usuario) {
            return redirect()->route('login');
        }

        $estadisticas = [
            'total_trufis'   => Trufi::count(),
            'trufis_activos' => Trufi::where('estado', 1)->count(),
            'total_rutas'    => TrufiRuta::count(),
        ];

        return view('admin.dashboard', [
            'usuario' => $usuario,
            'stats'   => $estadisticas,
        ]);
    }
}
