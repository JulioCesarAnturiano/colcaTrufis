<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Trufi extends Model
{
    protected $table = 'trufis';
    protected $primaryKey = 'idtrufi';

    // Si Tu PK No Se Llama "id", Esto Ayuda A Eloquent
    public $incrementing = true;
    protected $keyType = 'int';

    protected $fillable = [
        'nom_linea',
        'costo',
        'frecuencia',
        'tipo',
        'descripcion',
        'estado',
        'sindicato_id',
    ];

    protected $casts = [
        'estado' => 'boolean',
        'costo'  => 'decimal:2',
    ];

    // Relaciones
    public function rutas()
    {
        return $this->hasMany(\App\Models\Trufiruta::class, 'idtrufi', 'idtrufi');
    }

    public function sindicato()
    {
        return $this->belongsTo(\App\Models\Sindicato::class, 'sindicato_id', 'id');
    }

    // Opcional: Compatibilidad Si En Algún Lado Aún Usas "nombre"
    public function getNombreAttribute()
    {
        return $this->nom_linea;
    }

    // Opcional: Compatibilidad Si En Algún Lado Aún Usas "nombre_sindicato"
    public function getNombreSindicatoAttribute()
    {
        return $this->sindicato?->nombre;
    }
}
