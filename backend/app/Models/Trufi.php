<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Trufi extends Model
{
    protected $primaryKey = 'idtrufi';

    protected $fillable = [
        'nombre',
        'costo',
        'frecuencia',
        'tipo',
        'descripcion',
        'nombre_sindicato',
        'estado',
        // Nuevos campos para FilePond
        'imagen_url',
        'imagen_path',
        'creado_por',
        'actualizado_por',
        'encargados_asignados'
    ];

    protected $casts = [
        'estado' => 'boolean',
        'costo' => 'decimal:2',
        'encargados_asignados' => 'array'
    ];

    public function rutas()
    {
        return $this->hasMany(TrufiRuta::class, 'idtrufi', 'idtrufi');
    }

    public function creador()
    {
        return $this->belongsTo(User::class, 'creado_por');
    }

    public function actualizador()
    {
        return $this->belongsTo(User::class, 'actualizado_por');
    }

    // Métodos para FilePond
    public function getImagenUrlAttribute($value)
    {
        if ($value && filter_var($value, FILTER_VALIDATE_URL)) {
            return $value;
        }
        
        if ($this->imagen_path && Storage::disk('public')->exists($this->imagen_path)) {
            return Storage::url($this->imagen_path);
        }
        
        // Imagen por defecto
        return asset('images/default-trufi.png');
    }

    public function esEncargado($userId)
    {
        if (!$this->encargados_asignados) {
            return false;
        }
        
        return in_array($userId, $this->encargados_asignados);
    }

    public function eliminarImagen()
    {
        if ($this->imagen_path && Storage::disk('public')->exists($this->imagen_path)) {
            Storage::disk('public')->delete($this->imagen_path);
        }
        
        $this->imagen_url = null;
        $this->imagen_path = null;
        $this->save();
        
        return $this;
    }
}