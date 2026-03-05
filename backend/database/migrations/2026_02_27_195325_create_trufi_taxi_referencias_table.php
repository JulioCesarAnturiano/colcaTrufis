<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trufi_taxi_referencias', function (Blueprint $table) {
            $table->id();

            // FK -> sindicato_radiotaxis.id
            $table->unsignedBigInteger('sindicato_radiotaxi_id');

            $table->string('referencias', 255);

            $table->timestamps();

            $table->foreign('sindicato_radiotaxi_id')
                ->references('id')
                ->on('sindicato_radiotaxis')
                ->onDelete('cascade');

            // 1:1 (Una Referencia Por RadioTaxi)
            $table->unique('sindicato_radiotaxi_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trufi_taxi_referencias');
    }
};