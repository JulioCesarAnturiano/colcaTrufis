<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Referencia extends Model
{
    protected $table = 'referencias';

    protected $fillable = [
        'referencia',
        'referenciable_id',
        'referenciable_type',
        'latitud',
        'longitud',
    ];

    public function referenciable()
    {
        return $this->morphTo();
    }
}