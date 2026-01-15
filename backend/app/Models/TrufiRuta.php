<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TrufiRuta extends Model
{
    protected $fillable = [
    'idtrufi',
    'latitud',
    'longitud',
    'orden',
    'es_parada',
    'estado',
];

public function trufi()
{
    return $this->belongsTo(Trufi::class, 'idtrufi', 'idtrufi');
}

}
