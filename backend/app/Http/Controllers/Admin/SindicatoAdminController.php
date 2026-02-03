<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SindicatoAdminController extends Controller
{
    public function index(Request $request)
    {
        $usuario = $request->user();
        if (!$usuario) return redirect()->route('login');

        $sindicatos = DB::table('sindicatos')->orderBy('nombre')->paginate(20);

        return view('admin.sindicatos.index', compact('sindicatos', 'usuario'));
    }

    public function create(Request $request)
    {
        $usuario = $request->user();
        if (!$usuario) return redirect()->route('login');

        return view('admin.sindicatos.create', compact('usuario'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
            'descripcion' => 'nullable|string',
        ]);

        DB::table('sindicatos')->insert([
            'nombre' => $request->nombre,
            'descripcion' => $request->descripcion,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return redirect()->route('admin.sindicatos.index')->with('success', 'Sindicato creado correctamente.');
    }

    public function edit(Request $request, $id)
    {
        $usuario = $request->user();
        if (!$usuario) return redirect()->route('login');

        $sindicato = DB::table('sindicatos')->where('id', $id)->first();
        if (!$sindicato) abort(404);

        return view('admin.sindicatos.edit', compact('sindicato', 'usuario'));
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
            'descripcion' => 'nullable|string',
        ]);

        DB::table('sindicatos')
            ->where('id', $id)
            ->update([
                'nombre' => $request->nombre,
                'descripcion' => $request->descripcion,
                'updated_at' => now(),
            ]);

        return redirect()->route('admin.sindicatos.index')->with('success', 'Sindicato actualizado correctamente.');
    }

    public function destroy(Request $request, $id)
    {
        DB::table('sindicatos')->where('id', $id)->delete();

        return redirect()->route('admin.sindicatos.index')->with('success', 'Sindicato eliminado correctamente.');
    }
}
