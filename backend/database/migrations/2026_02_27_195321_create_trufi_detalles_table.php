<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trufi_detalles', function (Blueprint $table) {
            $table->id();

            // FK -> trufis.idtrufi (bigint unsigned)
            $table->unsignedBigInteger('trufi_id');

            $table->string('referencias', 255);
            $table->time('hora_entrada')->nullable();
            $table->time('hora_salida')->nullable();

            $table->timestamps();

            $table->foreign('trufi_id')
                ->references('idtrufi')
                ->on('trufis')
                ->onDelete('cascade');

            // Si quieres 1 registro de detalle por trufi (1:1), deja esto:
            $table->unique('trufi_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trufi_detalles');
    }
};