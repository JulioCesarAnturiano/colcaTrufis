<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Normativa;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\SindicatoRadiotaxiParada;
use App\Models\SindicatoRadioTaxi;

class NormativaAdminController extends Controller
{
    public function index()
    {
        $items = Normativa::orderByDesc('id')->paginate(10);
        return view('admin.normativas.index', compact('items'));
    }

    public function create()
    {
        return view('admin.normativas.create');
    }

    public function store(Request $request)
{
    $request->validate([
        'nombre_comercial' => ['required','string','max:255'],
        'telefono_base' => ['required','string','max:255'],
        'latitud' => ['required','numeric'],
        'longitud' => ['required','numeric'],
    ]);

    $radiotaxi = SindicatoRadioTaxi::create([
        'nombre_comercial' => $request->nombre_comercial,
        'telefono_base' => $request->telefono_base,
    ]);

    SindicatoRadiotaxiParada::updateOrCreate(
        ['sindicato_radiotaxi_id' => $radiotaxi->id],
        [
            'latitud' => $request->latitud,
            'longitud' => $request->longitud,
            'estado' => true,
        ]
    );

    return redirect()->route('admin.radiotaxis.index')
        ->with('success', 'RadioTaxi y parada registrados correctamente.');
}

    public function edit($id)
    {
        $item = Normativa::findOrFail($id);
        return view('admin.normativas.edit', compact('item'));
    }

    public function update(Request $request, $id)
    {
        $item = Normativa::findOrFail($id);

        $request->validate([
            'titulo' => ['required','string','max:255'],
            'descripcion' => ['nullable','string'],
            'categoria' => ['nullable','string','max:100'],
            'version' => ['nullable','string','max:50'],
            'fecha_publicacion' => ['nullable','date'],
            'activo' => ['nullable','boolean'],
            'pdf' => ['nullable','file','mimes:pdf','max:51200'],
        ]);

        if ($request->hasFile('pdf')) {
            if ($item->file_path && Storage::exists($item->file_path)) {
                Storage::delete($item->file_path);
            }

            $file = $request->file('pdf');
            $item->file_path = $file->store('normativas');
            $item->original_name = $file->getClientOriginalName();
            $item->mime = $file->getMimeType();
            $item->size_bytes = $file->getSize();
        }

        $item->titulo = $request->titulo;
        $item->descripcion = $request->descripcion;
        $item->categoria = $request->categoria;
        $item->version = $request->version;
        $item->fecha_publicacion = $request->fecha_publicacion;
        $item->activo = $request->boolean('activo', true);
        $item->save();

        return redirect()->route('admin.normativas.index')
            ->with('success', 'Normativa actualizada correctamente.');
    }

    public function destroy($id)
    {
        $item = Normativa::findOrFail($id);

        if ($item->file_path && Storage::exists($item->file_path)) {
            Storage::delete($item->file_path);
        }

        $item->delete();

        return redirect()->route('admin.normativas.index')
            ->with('success', 'Normativa eliminada.');
    }
public function verPdf($id)
{
    $item = \App\Models\Normativa::findOrFail($id);

    if (!Storage::exists($item->file_path)) {
        abort(404, 'Archivo no encontrado en storage');
    }

    // Ruta absoluta según el disk configurado (local/public)
    $absolutePath = Storage::path($item->file_path);

    return response()->file($absolutePath, [
        'Content-Type' => $item->mime ?: 'application/pdf',
        'Content-Disposition' => 'inline; filename="' . ($item->original_name ?: 'normativa_'.$item->id.'.pdf') . '"',
    ]);
}

}
