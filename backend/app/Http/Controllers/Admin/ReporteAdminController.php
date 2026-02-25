<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trufiseleccion;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReporteAdminController extends Controller
{
    public function trufisMasSeleccionados(Request $request)
    {
        $dias = (int) ($request->query('dias', 30));
        if ($dias <= 0 || $dias > 365) $dias = 30;

        $desde = Carbon::now()->subDays($dias);

        $top = Trufiseleccion::query()
            ->select('idtrufi', DB::raw('COUNT(*) as total'))
            ->where('created_at', '>=', $desde)
            ->groupBy('idtrufi')
            ->orderByDesc('total')
            ->with(['trufi:idtrufi,nom_linea,tipo,sindicato_id'])
            ->limit(10)
            ->get();

        return view('admin.reportes.trufis_mas_seleccionados', [
            'dias' => $dias,
            'top'  => $top,
        ]);
    }
}
