<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trufi;
use App\Models\Trufiruta;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Trufirutaubicacion;
use App\Services\GeocodingService;

class RutaAdminController extends Controller
{
    // Listar rutas
public function listarRutas(Request $request)
{
    $usuario = $request->user();
    if (!$usuario) return redirect()->route('login');

    $trufiId = $request->query('trufi_id');

    // 1 fila por idtrufi (resumen)
    $query = DB::table('trufi_rutas')
        ->select(
            'idtrufi',
            DB::raw('MIN(orden) as orden_inicio'),
            DB::raw('MAX(orden) as orden_fin'),
            DB::raw('COUNT(*) as total_puntos')
        )
        ->groupBy('idtrufi')
        ->orderBy('idtrufi', 'asc');

    if ($trufiId) {
        $query->where('idtrufi', $trufiId);
    }

    $rutas = $query->paginate(20);

    $trufis = Trufi::orderBy('nom_linea')->get();

    return view('admin.rutas.index', [
        'rutas' => $rutas,
        'trufis' => $trufis,
        'trufiId' => $trufiId,
        'usuario' => $usuario
    ]);
}



    // Mostrar formulario crear
    public function mostrarCrearRuta()
{
    $trufis = DB::table('trufis as t')
        ->leftJoin('trufi_rutas as r', 'r.idtrufi', '=', 't.idtrufi')
        ->whereNull('r.idtrufi') // ✅ solo los que NO tienen rutas
        ->select('t.idtrufi', 't.nom_linea')
        ->orderBy('t.nom_linea')
        ->get();

    return view('admin.rutas.create', compact('trufis'));
}

    // Guardar ruta (Opción 2: continuar el orden desde el último punto)
   public function guardarRuta(Request $request, GeocodingService $geoService)
{
    $request->validate([
        'idtrufi' => 'required|integer',
        'geojson' => 'required|string',
    ]);

    $geo = json_decode($request->geojson, true);

    if (!$geo || empty($geo['features'])) {
        return back()->with('error', 'GeoJSON inválido.')->withInput();
    }

    $feature = $geo['features'][0] ?? null;
    if (!$feature || ($feature['geometry']['type'] ?? '') !== 'LineString') {
        return back()->with('error', 'Debes dibujar una línea (ruta).')->withInput();
    }

    $coords = $feature['geometry']['coordinates'] ?? [];
    if (count($coords) < 2) {
        return back()->with('error', 'La ruta debe tener al menos 2 puntos.')->withInput();
    }

    $idtrufi = (int) $request->idtrufi;

    DB::beginTransaction();
    try {
        // 1) Insertar Puntos.
        $ultimo = DB::table('trufi_rutas')
            ->where('idtrufi', $idtrufi)
            ->max('orden');

        $orden = ($ultimo ?? 0) + 1;

        $rows = [];
        foreach ($coords as $c) {
            $lng = $c[0];
            $lat = $c[1];

            $rows[] = [
                'idtrufi'    => $idtrufi,
                'latitud'    => $lat,
                'longitud'   => $lng,
                'orden'      => $orden,
                'estado'     => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ];
            $orden++;
        }

        DB::table('trufi_rutas')->insert($rows);

        // 2) Generar Ubicaciones (Calles) Y Guardarlas.
        Trufirutaubicacion::where('idtrufi', $idtrufi)->delete();

        $ubicaciones = $geoService->buildUbicacionesFromCoords($coords, 2);

        $ordenU = 1;
        foreach ($ubicaciones as $u) {
            Trufirutaubicacion::create([
                'idtrufi' => $idtrufi,
                'orden' => $ordenU,
                'nombre_via' => $u['nombre_via'],
                'interseccion' => $u['interseccion'] ?? null,
                'tipo_via' => $u['tipo_via'] ?? null,
                'latitud' => $u['latitud'] ?? null,
                'longitud' => $u['longitud'] ?? null,
                'meta' => $u['meta'] ?? null,
                'estado' => 1,
            ]);
            $ordenU++;
        }

        DB::commit();
        return redirect()->route('admin.rutas.index')->with('success', 'Ruta y ubicaciones guardadas correctamente.');
    } catch (\Throwable $e) {
        DB::rollBack();
        return back()->with('error', 'Error al guardar ruta y ubicaciones.')->withInput();
    }
}

public function mostrarEditarRuta($idtrufi)
{
    $usuario = request()->user();
    if (!$usuario) return redirect()->route('login');

    $trufis = DB::table('trufis')
        ->select('idtrufi', 'nom_linea')
        ->orderBy('nom_linea')
        ->get();

    $trufiSeleccionado = DB::table('trufis')
        ->where('idtrufi', $idtrufi)
        ->first();

    $ubicaciones = \App\Models\Trufirutaubicacion::where('idtrufi', (int) $idtrufi)
        ->orderBy('orden')
        ->get();

    return view('admin.rutas.edit', compact(
        'trufis',
        'idtrufi',
        'trufiSeleccionado',
        'usuario',
        'ubicaciones'
    ));
}


public function actualizarRuta(Request $request, $idtrufi, \App\Services\GeocodingService $geoService)
{
    $usuario = $request->user();
    if (!$usuario) return redirect()->route('login');

    $request->validate([
        'geojson' => 'required|string',
    ]);

    $geo = json_decode($request->geojson, true);

    if (!$geo || empty($geo['features'])) {
        return back()->with('error', 'GeoJSON inválido.')->withInput();
    }

    $feature = $geo['features'][0] ?? null;
    if (!$feature || ($feature['geometry']['type'] ?? '') !== 'LineString') {
        return back()->with('error', 'Debes dibujar una línea (ruta).')->withInput();
    }

    $coords = $feature['geometry']['coordinates'] ?? [];
    if (count($coords) < 2) {
        return back()->with('error', 'La ruta debe tener al menos 2 puntos.')->withInput();
    }

    DB::beginTransaction();
    try {
        // 1) Eliminar ruta anterior completa.
        DB::table('trufi_rutas')->where('idtrufi', (int) $idtrufi)->delete();

        // 2) Insertar la nueva ruta desde orden 1.
        $rows = [];
        $orden = 1;

        foreach ($coords as $c) {
            // GeoJSON: [lng, lat]
            $lng = (float) $c[0];
            $lat = (float) $c[1];

            $rows[] = [
                'idtrufi'    => (int) $idtrufi,
                'latitud'    => $lat,
                'longitud'   => $lng,
                'orden'      => $orden,
                'estado'     => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ];

            $orden++;
        }

        DB::table('trufi_rutas')->insert($rows);

        // 3) Reemplazar ubicaciones (calles) de la ruta.
        \App\Models\Trufirutaubicacion::where('idtrufi', (int) $idtrufi)->delete();

        $ubicaciones = $geoService->buildUbicacionesFromCoords($coords, 2); // Cada 2 puntos (captura calles menores)

        $ordenU = 1;
        foreach ($ubicaciones as $u) {
            \App\Models\Trufirutaubicacion::create([
                'idtrufi' => (int) $idtrufi,
                'orden' => $ordenU,
                'nombre_via' => $u['nombre_via'],
                'interseccion' => $u['interseccion'] ?? null,
                'tipo_via' => $u['tipo_via'] ?? null,
                'latitud' => $u['latitud'] ?? null,
                'longitud' => $u['longitud'] ?? null,
                'meta' => $u['meta'] ?? null,
                'estado' => 1,
            ]);
            $ordenU++;
        }

        DB::commit();

        return redirect()->route('admin.rutas.index')
            ->with('success', 'Ruta y ubicaciones reemplazadas correctamente.');
    } catch (\Throwable $e) {
        DB::rollBack();

        return back()->with('error', 'Error al reemplazar la ruta y sus ubicaciones.')->withInput();
    }
}

public function verUbicaciones($idtrufi)
{
    $usuario = request()->user();
    if (!$usuario) return redirect()->route('login');

    $trufi = Trufi::where('idtrufi', (int) $idtrufi)->first();
    if (!$trufi) return abort(404);

    // Obtener los puntos de la ruta
    $puntos = DB::table('trufi_rutas')
        ->where('idtrufi', (int) $idtrufi)
        ->orderBy('orden')
        ->get(['latitud', 'longitud'])
        ->map(fn($p) => [(float)$p->longitud, (float)$p->latitud])
        ->toArray();

    // Obtener las ubicaciones (calles)
    $ubicaciones = Trufirutaubicacion::where('idtrufi', (int) $idtrufi)
        ->orderBy('orden')
        ->get();

    return view('admin.rutas.ver_ubicaciones', compact('trufi', 'puntos', 'ubicaciones', 'idtrufi'));
}

public function eliminarRuta($idtrufi)
{
    $usuario = request()->user();
    if (!$usuario) return redirect()->route('login');

    DB::beginTransaction();
    try {
        DB::table('trufi_rutas')->where('idtrufi', (int) $idtrufi)->delete();

        \App\Models\Trufirutaubicacion::where('idtrufi', (int) $idtrufi)->delete();

        DB::commit();

        return redirect()->route('admin.rutas.index')
            ->with('success', 'Ruta y ubicaciones eliminadas.');
    } catch (\Throwable $e) {
        DB::rollBack();

        return redirect()->route('admin.rutas.index')
            ->with('error', 'Error al eliminar la ruta.');
    }
}

}
