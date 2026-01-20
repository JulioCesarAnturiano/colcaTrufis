<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class FilePondController extends Controller
{
    public function subirArchivo(Request $request)
    {
        $usuario = $request->user();

        if (! $usuario) {
            return response()->json(['error' => 'No autenticado'], 401);
        }

        // ✅ Spatie: primero rol, luego permiso (si quieres hacerlo fino)
        if (! $usuario->hasAnyRole(['admin', 'encargado'])) {
            return response()->json(['error' => 'No autorizado'], 403);
        }

        // Si ya creaste permisos, puedes activar esta validación:
        if (! $usuario->can('archivos.subir')) {
            return response()->json(['error' => 'Sin permiso para subir archivos'], 403);
        }

        $contenido = $request->getContent();

        if (empty($contenido)) {
            return response()->json(['error' => 'Archivo vacío'], 400);
        }

        $nombreOriginal = $request->header('Upload-Name') ?: ('imagen_' . time() . '.jpg');

        $extension = pathinfo($nombreOriginal, PATHINFO_EXTENSION);
        if (empty($extension)) {
            $extension = 'jpg';
        }

        $nombreArchivo = 'temp_' . time() . '_' . uniqid() . '.' . $extension;
        $rutaTemporal = 'temp/' . $nombreArchivo;

        Storage::disk('public')->put($rutaTemporal, $contenido);

        return response()->json([
            'success' => true,
            'filename' => $nombreArchivo,
            'url' => Storage::url($rutaTemporal),
        ]);
    }

    public function eliminarArchivo(Request $request)
    {
        $usuario = $request->user();

        if (! $usuario) {
            return response()->json(['error' => 'No autenticado'], 401);
        }

        if (! $usuario->hasAnyRole(['admin', 'encargado'])) {
            return response()->json(['error' => 'No autorizado'], 403);
        }

        // Si ya creaste permisos, puedes activar esta validación:
        if (! $usuario->can('archivos.eliminar')) {
            return response()->json(['error' => 'Sin permiso para eliminar archivos'], 403);
        }

        $nombreArchivo = $request->getContent();

        if ($nombreArchivo) {
            $ruta = 'temp/' . $nombreArchivo;

            if (Storage::disk('public')->exists($ruta)) {
                Storage::disk('public')->delete($ruta);
            }
        }

        return response()->json(['success' => true]);
    }
}
