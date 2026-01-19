<?php

namespace App\Traits;

use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

trait HandleFileUpload
{
    /**
     * Procesar subida de FilePond
     */
    public function procesarImagenFilePond($tempFileName, $folder = 'trufis')
    {
        if (!$tempFileName) {
            return null;
        }

        $tempPath = 'temp/' . $tempFileName;
        
        if (!Storage::disk('public')->exists($tempPath)) {
            throw new \Exception("Archivo temporal no encontrado: {$tempFileName}");
        }

        // Generar nombre único
        $extension = pathinfo($tempFileName, PATHINFO_EXTENSION);
        $finalName = $folder . '_' . $this->idtrufi . '_' . time() . '.' . $extension;
        $finalPath = $folder . '/' . $finalName;

        // Mover archivo
        Storage::disk('public')->move($tempPath, $finalPath);

        return [
            'path' => $finalPath,
            'url' => Storage::url($finalPath),
            'filename' => $finalName
        ];
    }

    /**
     * Guardar imagen desde FilePond
     */
    public function guardarImagenDesdeFilePond($tempFileName)
    {
        // Eliminar imagen anterior si existe
        $this->eliminarImagenAnterior();
        
        // Procesar nueva imagen
        $fileData = $this->procesarImagenFilePond($tempFileName);
        
        if ($fileData) {
            $this->imagen_url = $fileData['url'];
            $this->imagen_path = $fileData['path'];
            $this->save();
        }
        
        return $this;
    }

    /**
     * Eliminar imagen anterior
     */
    public function eliminarImagenAnterior()
    {
        $oldPath = $this->getOriginal('imagen_path');
        
        if ($oldPath && Storage::disk('public')->exists($oldPath)) {
            Storage::disk('public')->delete($oldPath);
        }

        return $this;
    }
}