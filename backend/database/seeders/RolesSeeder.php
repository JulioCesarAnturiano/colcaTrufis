<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class RolesSeeder extends Seeder
{
    public function run(): void
    {
        // =========================
        // ROLES
        // =========================
        $admin = Role::firstOrCreate(['name' => 'admin']);
        $encargado = Role::firstOrCreate(['name' => 'encargado']);

        // =========================
        // PERMISOS - TRUFIS
        // =========================
        $permisos = [
            // Trufis
            'trufis.ver',
            'trufis.crear',
            'trufis.editar',
            'trufis.eliminar',

            // Rutas
            'rutas.ver',
            'rutas.crear',
            'rutas.editar',
            'rutas.eliminar',

            // FilePond / Archivos
            'archivos.subir',
            'archivos.eliminar',

            // Dashboard
            'dashboard.ver',
        ];

        foreach ($permisos as $permiso) {
            Permission::firstOrCreate(['name' => $permiso]);
        }

        // =========================
        // ASIGNACIÓN DE PERMISOS
        // =========================

        // Admin -> TODO
        $admin->givePermissionTo($permisos);

        // Encargado -> SIN eliminar
        $encargado->givePermissionTo([
            'trufis.ver',
            'trufis.crear',
            'trufis.editar',

            'rutas.ver',
            'rutas.crear',
            'rutas.editar',

            'archivos.subir',
            'dashboard.ver',
        ]);
    }
}
