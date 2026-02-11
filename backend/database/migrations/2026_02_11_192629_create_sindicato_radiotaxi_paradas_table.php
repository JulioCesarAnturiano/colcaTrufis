<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('sindicato_radiotaxi_paradas', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('sindicato_radiotaxi_id');
            $table->decimal('latitud', 10, 7);
            $table->decimal('longitud', 10, 7);

            $table->string('descripcion', 255)->nullable();
            $table->boolean('estado')->default(true);

            $table->timestamps();

            $table->foreign('sindicato_radiotaxi_id')
                ->references('id')
                ->on('sindicato_radiotaxis')
                ->onDelete('cascade');

            // 1 sola parada por radiotaxi (si quieres SOLO UNA)
            $table->unique('sindicato_radiotaxi_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sindicato_radiotaxi_paradas');
    }
};
