<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Trufi extends Model
{
    protected $primaryKey = 'idtrufi';

    protected $fillable = [
        'nom_linea',      // Cambié 'nombre' por 'nom_linea' (como está en tu BD)
        'costo',
        'frecuencia',
        'tipo',
        'descripcion',
        'estado',
        'sindicato_id',   // Agregué este campo (está en tu BD)
        // Campos para FilePond
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

    // Relaciones
    public function rutas()
    {
        return $this->hasMany(TrufiRuta::class, 'idtrufi');
    }

    public function sindicato()
    {
        return $this->belongsTo(Sindicato::class, 'sindicato_id');
    }

    public function creador()
    {
        return $this->belongsTo(User::class, 'creado_por');
    }

    public function actualizador()
    {
        return $this->belongsTo(User::class, 'actualizado_por');
    }

    // Accessor para compatibilidad (si tus APIs usan 'nombre')
    public function getNombreAttribute()
    {
        return $this->nom_linea;
    }

    // Accessor para nombre_sindicato (compatibilidad)
    public function getNombreSindicatoAttribute()
    {
        return $this->sindicato->nombre ?? null;
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
