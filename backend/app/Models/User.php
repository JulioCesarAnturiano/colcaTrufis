<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Spatie\Permission\Traits\HasRoles;
use Laravel\Sanctum\HasApiTokens;
class User extends Authenticatable
{
    use HasFactory, Notifiable, HasRoles, HasApiTokens;

    protected $fillable = [
        'name',
        'email',
        'password',
        'activo'
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'activo' => 'boolean'
    ];

    // Métodos para compatibilidad (si tus APIs usan estos métodos)
    public function esAdmin()
    {
        return $this->hasRole('admin');
    }

    public function esEncargado()
    {
        return $this->hasRole('encargado');
    }

    // Accessor para compatibilidad (si tus APIs acceden a $user->rol)
    public function getRolAttribute()
    {
        return $this->getRoleNames()->first();
    }
}
