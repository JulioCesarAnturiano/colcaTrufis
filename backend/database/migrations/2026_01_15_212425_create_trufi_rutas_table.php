<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
 public function up(): void
{
    Schema::create('trufi_rutas', function (Blueprint $table) {
        $table->id(); // campo id
        $table->unsignedBigInteger('idtrufi');
        $table->decimal('latitud', 10, 7);
        $table->decimal('longitud', 10, 7);
        $table->integer('orden');
        $table->boolean('es_parada')->default(false);
        $table->boolean('estado')->default(true);
        $table->timestamps();

        $table->foreign('idtrufi')->references('idtrufi')->on('trufis')->onDelete('cascade');
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trufi_rutas');
    }
};
