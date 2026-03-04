<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Trufidetalle extends Model
{
    protected $table = 'trufi_detalles';

    protected $fillable = [
    'trufi_id',
    'hora_entrada',
    'hora_salida',
];
    public function trufi()
    {
        return $this->belongsTo(Trufi::class, 'trufi_id', 'idtrufi');
    }
}