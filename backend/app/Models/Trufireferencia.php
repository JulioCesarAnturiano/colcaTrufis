<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Trufireferencia extends Model
{
    protected $table = 'trufi_referencias';

    protected $fillable = [
        'trufi_id',
        'referencia',
    ];

    public function trufi()
    {
        return $this->belongsTo(Trufi::class, 'trufi_id', 'idtrufi');
    }
}