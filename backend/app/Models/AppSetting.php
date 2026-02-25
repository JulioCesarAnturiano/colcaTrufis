<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Appsetting extends Model
{
    protected $table = 'app_settings';

    protected $fillable = [
        'key', 'value', 'group', 'activo', 'updated_by'
    ];
}
