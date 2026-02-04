@extends('admin.layout')

@section('title', 'Crear Sindicato')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4">
        <h2 class="ct-title">Crear Sindicato</h2>
        <div class="ct-subtitle">
            Registro De Nuevo Sindicato De Trufis En El Sistema ColcaTrufis
        </div>
    </div>

    {{-- Formulario --}}
    <div class="card ct-stat-card">
        <div class="card-body">

            <form action="{{ route('admin.sindicatos.guardar') }}" method="POST">
                @csrf

                <div class="row">

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Nombre</label>
                        <input
                            type="text"
                            name="nombre"
                            class="form-control"
                            required
                            value="{{ old('nombre') }}"
                        >
                    </div>

                    <div class="col-12 mb-3">
                        <label class="form-label fw-semibold">Descripción</label>
                        <textarea
                            name="descripcion"
                            class="form-control"
                            rows="3"
                        >{{ old('descripcion') }}</textarea>
                    </div>

                </div>

                {{-- Acciones --}}
                <div class="d-flex gap-2 mt-3">
                    <button type="submit" class="btn ct-btn ct-btn-save">
                        Guardar
                    </button>

                    <a href="{{ route('admin.sindicatos.index') }}" class="btn ct-btn ct-btn-back">
                        Volver
                    </a>
                </div>

            </form>

        </div>
    </div>

@endsection
