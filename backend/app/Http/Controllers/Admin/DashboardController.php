<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trufi;
use App\Models\TrufiRuta;
use App\Models\Sindicatoradiotaxi;
use App\Models\User;
use App\Models\Normativa;


class DashboardController extends Controller
{
    public function mostrarDashboard()
    {
        $usuario = auth()->user();

        if (! $usuario) {
            return redirect()->route('login');
        }

        $estadisticas = [
    'total_trufis'     => Trufi::count(),
    'trufis_activos'   => Trufi::where('estado', 1)->count(),
    'total_rutas'      => TrufiRuta::distinct('idtrufi')->count('idtrufi'),

    // NUEVAS
    'total_usuarios'   => User::count(),
    'total_radiotaxis' => Sindicatoradiotaxi::count(),
    'total_normativas' => Normativa::count(),
];


        return view('admin.dashboard', [
            'usuario' => $usuario,
            'stats'   => $estadisticas,
        ]);
    }
}
