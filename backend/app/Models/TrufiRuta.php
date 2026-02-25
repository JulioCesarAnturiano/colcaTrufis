<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Trufiruta extends Model
{
    protected $table = 'trufi_rutas'; // Especificar tabla

    protected $fillable = [
        'idtrufi',
        'sindicato_radiotaxi_id', // Agregué este campo (está en tu BD)
        'latitud',
        'longitud',
        'orden',
        'puntos',                // Agregué este campo (está en tu BD)
        'es_parada',
        'estado'
    ];

    protected $casts = [
        'estado' => 'boolean',
        'es_parada' => 'boolean',
        'puntos' => 'boolean'
    ];

    public function trufi()
    {
        return $this->belongsTo(Trufi::class, 'idtrufi', 'idtrufi');
    }

    public function sindicatoRadiotaxi()
    {
        return $this->belongsTo(Sindicatoradiotaxi::class, 'sindicato_radiotaxi_id');
    }
}
