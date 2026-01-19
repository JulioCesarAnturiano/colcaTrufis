<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class FilePondController extends Controller
{
    public function subirArchivo(Request $request)
    {
        // Verificar si hay usuario autenticado
        $usuario = $request->user();
        
        if (!$usuario) {
            return response()->json(['error' => 'No autenticado'], 401);
        }
        
        // Verificar rol
        if (!in_array($usuario->rol, ['admin', 'encargado'])) {
            return response()->json(['error' => 'No autorizado'], 403);
        }
        
        // Obtener contenido del archivo
        $contenido = $request->getContent();
        
        if (empty($contenido)) {
            return response()->json(['error' => 'Archivo vacío'], 400);
        }
        
        // Obtener nombre del archivo desde headers
        $nombreOriginal = $request->header('Upload-Name') ?: 'imagen_' . time() . '.jpg';
        
        // Extraer extensión
        $extension = pathinfo($nombreOriginal, PATHINFO_EXTENSION);
        if (empty($extension)) {
            $extension = 'jpg';
        }
        
        // Generar nombre único
        $nombreArchivo = 'temp_' . time() . '_' . uniqid() . '.' . $extension;
        $rutaTemporal = 'temp/' . $nombreArchivo;
        
        // Guardar archivo
        Storage::disk('public')->put($rutaTemporal, $contenido);
        
        return response()->json([
            'success' => true,
            'filename' => $nombreArchivo,
            'url' => Storage::url($rutaTemporal)
        ]);
    }
    
    public function eliminarArchivo(Request $request)
    {
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