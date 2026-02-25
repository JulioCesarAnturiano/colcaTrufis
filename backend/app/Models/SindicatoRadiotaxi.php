<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Sindicatoradiotaxi extends Model
{
    protected $table = 'sindicato_radiotaxis';

    protected $fillable = [
        'nombre_comercial',
        'telefono_base'
    ];

    public function parada(){
    return $this->hasOne(\App\Models\Sindicatoradiotaxiparada::class, 'sindicato_radiotaxi_id');
    }

}
