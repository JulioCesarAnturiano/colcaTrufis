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
        'tipo_via',
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