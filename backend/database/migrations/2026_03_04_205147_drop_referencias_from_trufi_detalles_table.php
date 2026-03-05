<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('trufi_detalles', function (Blueprint $table) {
            $table->dropColumn('referencias');
        });
    }

    public function down(): void
    {
        Schema::table('trufi_detalles', function (Blueprint $table) {
            $table->string('referencias', 255);
        });
    }
};