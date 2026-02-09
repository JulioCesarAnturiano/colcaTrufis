<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('normativas', function (Blueprint $table) {
            $table->id();
            $table->string('titulo', 255);
            $table->text('descripcion')->nullable();
            $table->string('categoria', 100)->nullable();
            $table->string('version', 50)->nullable();
            $table->date('fecha_publicacion')->nullable();

            // Archivo
            $table->string('file_path'); // ej: normativas/abc.pdf
            $table->string('original_name')->nullable();
            $table->string('mime', 100)->default('application/pdf');
            $table->unsignedBigInteger('size_bytes')->nullable();

            // Control
            $table->boolean('activo')->default(true);
            $table->unsignedBigInteger('created_by')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->index(['activo', 'categoria']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('normativas');
    }
};