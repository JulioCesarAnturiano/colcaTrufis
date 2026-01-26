<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sindicato_radiotaxis', function (Blueprint $table) {
            $table->id();
            $table->string('nombre_comercial');
            $table->string('telefono_base');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sindicato_radiotaxis');
    }
};
