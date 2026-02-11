<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SindicatoRadiotaxi extends Model
{
    protected $table = 'sindicato_radiotaxis';

    protected $fillable = [
        'nombre_comercial',
        'telefono_base'
    ];

    public function parada(){
    return $this->hasOne(\App\Models\SindicatoRadiotaxiParada::class, 'sindicato_radiotaxi_id');
    }

}
