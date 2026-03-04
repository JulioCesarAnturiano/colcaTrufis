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
    ];

    public function referenciable()
    {
        return $this->morphTo();
    }
}