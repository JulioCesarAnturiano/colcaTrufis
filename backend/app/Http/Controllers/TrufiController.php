<?php

namespace App\Http\Controllers;

use App\Models\Trufi;
use Illuminate\Http\Request;

class TrufiController extends Controller
{
    public function index()
    {
        return response()->json(
            Trufi::with('rutas')->get()
        );
    }

    public function store(Request $request)
    {
        $trufi = Trufi::create($request->all());
        return response()->json($trufi, 201);
    }

    public function show($id)
    {
        return response()->json(
            Trufi::with('rutas')->findOrFail($id)
        );
    }

    public function update(Request $request, $id)
    {
        $trufi = Trufi::findOrFail($id);
        $trufi->update($request->all());
        return response()->json($trufi);
    }

    public function destroy($id)
    {
        $trufi = Trufi::findOrFail($id);
        $trufi->delete();
        return response()->json(['message' => 'Trufi eliminado']);
    }
}
