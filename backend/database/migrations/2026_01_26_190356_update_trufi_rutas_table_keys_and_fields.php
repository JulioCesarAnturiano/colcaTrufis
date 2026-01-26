<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1) Eliminar PK anterior (si existe)
        try {
            DB::statement('ALTER TABLE `trufi_rutas` DROP PRIMARY KEY');
        } catch (\Throwable $e) {
            // Si no existe o ya fue eliminada, no pasa nada
        }

        // 2) Eliminar columna id (si existe)
        if (Schema::hasColumn('trufi_rutas', 'id')) {
            Schema::table('trufi_rutas', function (Blueprint $table) {
                $table->dropColumn('id');
            });
        }

        // 3) Cambios de columnas
        Schema::table('trufi_rutas', function (Blueprint $table) {
            // es_parada -> puntos
            if (Schema::hasColumn('trufi_rutas', 'es_parada') && !Schema::hasColumn('trufi_rutas', 'puntos')) {
                $table->renameColumn('es_parada', 'puntos');
            }

            // puntos boolean default 0 (change puede requerir doctrine/dbal)
            if (Schema::hasColumn('trufi_rutas', 'puntos')) {
                $table->boolean('puntos')->default(false)->change();
            }

            // agregar nuevo es_parada
            if (!Schema::hasColumn('trufi_rutas', 'es_parada')) {
                $table->boolean('es_parada')->default(false);
            }

            // agregar sindicato_radiotaxi_id + FK cascade
            if (!Schema::hasColumn('trufi_rutas', 'sindicato_radiotaxi_id')) {
                $table->foreignId('sindicato_radiotaxi_id')
                    ->nullable()
                    ->constrained('sindicato_radiotaxis')
                    ->cascadeOnDelete();
            }

            // idtrufi nullable (change puede requerir doctrine/dbal)
            if (Schema::hasColumn('trufi_rutas', 'idtrufi')) {
                $table->unsignedBigInteger('idtrufi')->nullable()->change();
            }
        });

        // 4) PK compuesta (idtrufi, orden)
        // ADVERTENCIA: MySQL no permite NULL en PK. Si existe algún NULL en idtrufi, esto puede fallar.
        DB::statement('ALTER TABLE `trufi_rutas` ADD PRIMARY KEY (`idtrufi`, `orden`)');
    }

    public function down(): void
    {
        // Revertir PK compuesta
        try {
            DB::statement('ALTER TABLE `trufi_rutas` DROP PRIMARY KEY');
        } catch (\Throwable $e) {}

        Schema::table('trufi_rutas', function (Blueprint $table) {
            // quitar FK y columna sindicato_radiotaxi_id
            if (Schema::hasColumn('trufi_rutas', 'sindicato_radiotaxi_id')) {
                $table->dropForeign(['sindicato_radiotaxi_id']);
                $table->dropColumn('sindicato_radiotaxi_id');
            }

            // quitar es_parada nuevo
            if (Schema::hasColumn('trufi_rutas', 'es_parada')) {
                $table->dropColumn('es_parada');
            }

            // puntos -> es_parada
            if (Schema::hasColumn('trufi_rutas', 'puntos')) {
                $table->renameColumn('puntos', 'es_parada');
            }

            // restaurar id (solo si lo necesitas de vuelta)
            if (!Schema::hasColumn('trufi_rutas', 'id')) {
                $table->bigIncrements('id');
            }
        });

        // restaurar PK en id
        try {
            DB::statement('ALTER TABLE `trufi_rutas` ADD PRIMARY KEY (`id`)');
        } catch (\Throwable $e) {}
    }
};
