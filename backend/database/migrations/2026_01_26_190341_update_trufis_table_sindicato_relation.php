<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('trufis', function (Blueprint $table) {
            // nombre -> nom_linea
            if (Schema::hasColumn('trufis', 'nombre') && !Schema::hasColumn('trufis', 'nom_linea')) {
                $table->renameColumn('nombre', 'nom_linea');
            }

            // drop nombre_sindicato
            if (Schema::hasColumn('trufis', 'nombre_sindicato')) {
                $table->dropColumn('nombre_sindicato');
            }

            // add sindicato_id + FK (ON DELETE SET NULL)
            if (!Schema::hasColumn('trufis', 'sindicato_id')) {
                $table->foreignId('sindicato_id')
                    ->nullable()
                    ->constrained('sindicatos')
                    ->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('trufis', function (Blueprint $table) {
            if (Schema::hasColumn('trufis', 'sindicato_id')) {
                $table->dropForeign(['sindicato_id']);
                $table->dropColumn('sindicato_id');
            }

            if (Schema::hasColumn('trufis', 'nom_linea') && !Schema::hasColumn('trufis', 'nombre')) {
                $table->renameColumn('nom_linea', 'nombre');
            }

            if (!Schema::hasColumn('trufis', 'nombre_sindicato')) {
                $table->string('nombre_sindicato')->nullable();
            }
        });
    }
};
