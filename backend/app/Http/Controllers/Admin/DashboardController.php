<?php

namespace App\Http\Controllers;

use App\Models\Trufi;
use App\Models\TrufiRuta;

class DashboardController extends Controller
{
    public function mostrarDashboard()
    {
        // Obtener usuario autenticado
        $usuario = request()->user(); // Esta es la forma CORRECTA en Laravel 11
        
        if (!$usuario) {
            return redirect()->route('login');
        }
        
        // Estadísticas
        $estadisticas = [
            'total_trufis' => Trufi::count(),
            'trufis_activos' => Trufi::where('estado', true)->count(),
            'total_rutas' => TrufiRuta::count(),
        ];
        
        return view('admin.dashboard', [
            'usuario' => $usuario,
            'stats' => $estadisticas
        ]);
    }
}