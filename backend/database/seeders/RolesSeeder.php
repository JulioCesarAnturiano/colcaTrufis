<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class RolesSeeder extends Seeder
{
    public function run(): void
    {
        $admin = Role::firstOrCreate(['name' => 'admin']);
        $encargado = Role::firstOrCreate(['name' => 'encargado']);

       $permisos = [
        // =====================
        // TRUFIS
        // =====================
        'admin.trufis.crear',
        'admin.trufis.ver',
        'admin.trufis.editar',
        'admin.trufis.eliminar',

        // =====================
        // RUTAS
        // =====================
        'admin.rutas.crear',
        'admin.rutas.ver',
        'admin.rutas.editar',
        'admin.rutas.eliminar',

        // =====================
        // USUARIOS
        // =====================
        'admin.usuarios.crear',
        'admin.usuarios.ver',
        'admin.usuarios.editar',
        'admin.usuarios.eliminar',
    ];


        foreach ($permisos as $p) {
            Permission::firstOrCreate(['name' => $p]);
        }

        // Admin: todos los permisos
        $admin->syncPermissions($permisos);

        // Encargado: solo crear
        $encargado->syncPermissions([
            'admin.trufis.crear',
            'admin.rutas.crear',
        ]);
    }
}
