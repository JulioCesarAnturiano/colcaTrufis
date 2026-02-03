<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Crear usuario Admin
        $admin = User::firstOrCreate(
            ['email' => 'admin@admin.com'],
            [
                'name' => 'Administrador',
                'password' => Hash::make('password'),
            ]
        );

        // Crear usuario Encargado
        $encargado = User::firstOrCreate(
            ['email' => 'encargado@admin.com'],
            [
                'name' => 'Encargado',
                'password' => Hash::make('password'),
            ]
        );

        // Obtener roles
        $rolAdmin = Role::where('name', 'admin')->first();
        $rolEncargado = Role::where('name', 'encargado')->first();

        // Asignar roles
        if ($rolAdmin && !$admin->hasRole('admin')) {
            $admin->assignRole($rolAdmin);
        }

        if ($rolEncargado && !$encargado->hasRole('encargado')) {
            $encargado->assignRole($rolEncargado);
        }
    }
}
