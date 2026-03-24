<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sindicato_radiotaxi_paradas', function (Blueprint $table) {
            $table->renameColumn('descripcion', 'ubicacion');
        });
    }

    public function down(): void
    {
        Schema::table('sindicato_radiotaxi_paradas', function (Blueprint $table) {
            $table->renameColumn('ubicacion', 'descripcion');
        });
    }
};
