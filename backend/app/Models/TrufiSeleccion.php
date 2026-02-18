<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TrufiSeleccion extends Model
{
    protected $table = 'trufi_selecciones';

    protected $fillable = [
        'idtrufi',
        'device_id',
        'source',
    ];

    public function trufi()
    {
        return $this->belongsTo(Trufi::class, 'idtrufi', 'idtrufi');
    }
}
