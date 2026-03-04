<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('referencias', function (Blueprint $table) {
            $table->id();

            // Polimórfico: referencia puede pertenecer a Trufi o Sindicatoradiotaxi
            $table->unsignedBigInteger('referenciable_id');
            $table->string('referenciable_type');

            $table->string('referencia', 255);

            $table->timestamps();

            $table->index(['referenciable_id', 'referenciable_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('referencias');
    }
};