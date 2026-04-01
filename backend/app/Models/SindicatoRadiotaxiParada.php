<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Sindicatoradiotaxiparada extends Model
{
    protected $table = 'sindicato_radiotaxi_paradas';

    protected $fillable = [
        'sindicato_radiotaxi_id',
        'latitud',
        'longitud',
        'descripcion',
        'direccion',
        'estado',
    ];
}
