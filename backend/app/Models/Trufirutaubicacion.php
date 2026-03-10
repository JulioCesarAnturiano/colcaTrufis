<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Trufirutaubicacion extends Model
{
    protected $table = 'trufi_ruta_ubicaciones';

    protected $fillable = [
        'idtrufi',
        'orden',
        'nombre_via',
        'interseccion',
        'tipo_via',
        'latitud',
        'longitud',
        'meta',
        'estado',
    ];

    protected $casts = [
        'meta' => 'array',
        'estado' => 'boolean',
    ];

    public function trufi()
    {
        return $this->belongsTo(Trufi::class, 'idtrufi', 'idtrufi');
    }
}