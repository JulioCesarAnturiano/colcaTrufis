<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trufi_ruta_ubicaciones', function (Blueprint $table) {
            $table->id();

            // Relación con trufis
            $table->unsignedBigInteger('idtrufi');

            // Orden de aparición en la lista (1,2,3...)
            $table->unsignedInteger('orden');

            // Nombre de la vía/calle/avenida
            $table->string('nombre_via', 255);

            // Opcional: tipo (Avenida, Calle, etc.)
            $table->string('tipo_via', 80)->nullable();

            // Opcional: datos extra del geocoder (json)
            $table->json('meta')->nullable();

            $table->boolean('estado')->default(true);

            $table->timestamps();

            // Índices y restricciones
            $table->index(['idtrufi']);
            $table->unique(['idtrufi', 'orden'], 'uniq_trufi_ubicacion_orden');

            $table->foreign('idtrufi')
                ->references('idtrufi')
                ->on('trufis')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trufi_ruta_ubicaciones');
    }
};