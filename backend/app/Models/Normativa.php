<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Normativa extends Model
{
    use SoftDeletes;

    protected $table = 'normativas';

    protected $fillable = [
        'titulo','descripcion','categoria','version','fecha_publicacion',
        'file_path','original_name','mime','size_bytes',
        'activo','created_by'
    ];

    protected $casts = [
        'activo' => 'boolean',
        'fecha_publicacion' => 'date',
    ];
}
