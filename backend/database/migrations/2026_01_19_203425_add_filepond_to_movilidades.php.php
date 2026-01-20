<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('movilidades', function (Blueprint $table) {
            // Campos para FilePond
            $table->string('imagen_url')->nullable()->after('sindicato');
            $table->string('imagen_path')->nullable()->after('imagen_url');
            
            // Campos para control de permisos
            $table->foreignId('creado_por')->nullable()->after('imagen_path')
                  ->constrained('users')->onDelete('set null');
            $table->foreignId('actualizado_por')->nullable()->after('creado_por')
                  ->constrained('users')->onDelete('set null');
            
            // Si quieres que encargados solo editen sus propias líneas
            $table->json('encargados_asignados')->nullable()->after('actualizado_por');
        });
    }

    public function down()
    {
        Schema::table('movilidades', function (Blueprint $table) {
            $table->dropColumn([
                'imagen_url',
                'imagen_path',
                'creado_por',
                'actualizado_por',
                'encargados_asignados'
            ]);
        });
    }
};