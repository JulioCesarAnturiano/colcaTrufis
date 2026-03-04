<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Referencia;
use App\Models\Trufi;
use App\Models\Sindicatoradiotaxi;

class ReferenciaAdminController extends Controller
{
    // GET /admin/referencias
    public function index()
    {
        $referencias = Referencia::orderByDesc('id')->paginate(20);

        return view('admin.referencias.index', compact('referencias'));
    }

    // GET /admin/referencias/crear
    public function create()
    {
        $taxis  = Sindicatoradiotaxi::orderByDesc('id')->get();
        $trufis = Trufi::orderByDesc('idtrufi')->get();

        return view('admin.referencias.create', compact('taxis', 'trufis'));
    }

    // POST /admin/referencias
    public function store(Request $request)
    {
        $data = $request->validate([
            'referencia'         => ['required', 'string', 'max:255'],
            'referenciable_id'   => ['required', 'integer'],
            'referenciable_type' => ['required', 'string', 'max:255'],
        ]);

        Referencia::create($data);

        return redirect()
            ->route('admin.referencias')
            ->with('success', 'Reference created successfully.');
    }

    // GET /admin/referencias/{id}/editar
    public function edit($id)
    {
        $referencia = Referencia::findOrFail($id);

        $taxis  = Sindicatoradiotaxi::orderByDesc('id')->get();
        $trufis = Trufi::orderByDesc('idtrufi')->get();

        return view('admin.referencias.edit', compact('referencia', 'taxis', 'trufis'));
    }

    // PUT /admin/referencias/{id}
    public function update(Request $request, $id)
    {
        $referencia = Referencia::findOrFail($id);

        $data = $request->validate([
            'referencia'         => ['required', 'string', 'max:255'],
            'referenciable_id'   => ['required', 'integer'],
            'referenciable_type' => ['required', 'string', 'max:255'],
        ]);

        $referencia->update($data);

        return redirect()
            ->route('admin.referencias')
            ->with('success', 'Reference updated successfully.');
    }

    // DELETE /admin/referencias/{id}
    public function destroy($id)
    {
        $referencia = Referencia::findOrFail($id);
        $referencia->delete();

        return redirect()
            ->route('admin.referencias')
            ->with('success', 'Reference deleted successfully.');
    }
}