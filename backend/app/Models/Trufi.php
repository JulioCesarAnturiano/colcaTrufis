<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Models\TrufiRuta;

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
    ];

    public function rutas()
    {
        return $this->hasMany(TrufiRuta::class, 'idtrufi', 'idtrufi');
    }
}

