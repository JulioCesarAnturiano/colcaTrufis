<?php

namespace App\Http\Controllers;

use App\Models\Normativa;
use Illuminate\Support\Facades\Storage;

class NormativaController extends Controller
{
    // GET /api/normativas
    public function index()
    {
        return Normativa::query()
            ->where('activo', true)
            ->orderByDesc('id')
            ->get([
                'id',
                'titulo',
                'descripcion',
                'categoria',
                'version',
                'fecha_publicacion'
            ]);
    }

    // GET /api/normativas/{id}/download
    public function download($id)
    {
        $item = Normativa::query()
            ->where('activo', true)
            ->findOrFail($id);

        if (!Storage::exists($item->file_path)) {
            return response()->json(['error' => 'Archivo no encontrado'], 404);
        }

        $downloadName = $item->original_name ?: ('normativa_' . $item->id . '.pdf');

        return Storage::download(
            $item->file_path,
            $downloadName,
            ['Content-Type' => $item->mime ?: 'application/pdf']
        );
    }
}
