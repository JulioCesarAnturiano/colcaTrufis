<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // Verificar si la columna descripcion ya existe
        if (!Schema::hasColumn('sindicato_radiotaxi_paradas', 'descripcion')) {
            Schema::table('sindicato_radiotaxi_paradas', function (Blueprint $table) {
                $table->string('descripcion', 255)->nullable()->after('longitud');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('sindicato_radiotaxi_paradas', 'descripcion')) {
            Schema::table('sindicato_radiotaxi_paradas', function (Blueprint $table) {
                $table->dropColumn('descripcion');
            });
        }
    }
};
