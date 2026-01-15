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
    Schema::create('trufis', function (Blueprint $table) {
        $table->bigIncrements('idtrufi');
        $table->string('nombre');
        $table->decimal('costo', 8, 2);
        $table->integer('frecuencia');
        $table->string('tipo');
        $table->text('descripcion')->nullable();
        $table->string('nombre_sindicato');
        $table->boolean('estado')->default(true);
        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trufis');
    }
};
