<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Sindicato extends Model
{
    protected $table = 'sindicatos';
    
    protected $fillable = [
        'nombre',
        'descripcion'
    ];

    public function trufis()
    {
        return $this->hasMany(Trufi::class, 'sindicato_id');
    }
}