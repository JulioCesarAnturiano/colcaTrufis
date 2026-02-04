@extends('admin.layout')

@section('title', 'Editar RadioTaxi')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4">
        <h2 class="ct-title">Editar RadioTaxi</h2>
        <div class="ct-subtitle">
            Actualización De Información Del RadioTaxi En El Sistema ColcaTrufis
        </div>
    </div>

    {{-- Formulario --}}
    <div class="card ct-stat-card">
        <div class="card-body">

            <form action="{{ route('admin.radiotaxis.actualizar', $radiotaxi->id) }}" method="POST">
                @csrf
                @method('PUT')

                <div class="row">

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Nombre Comercial</label>
                        <input
                            type="text"
                            name="nombre_comercial"
                            class="form-control"
                            required
                            value="{{ old('nombre_comercial', $radiotaxi->nombre_comercial) }}"
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Teléfono Base</label>
                        <input
                            type="text"
                            name="telefono_base"
                            class="form-control"
                            required
                            value="{{ old('telefono_base', $radiotaxi->telefono_base) }}"
                        >
                    </div>

                </div>

                {{-- Acciones --}}
                <div class="d-flex gap-2 mt-3">
                    <button type="submit" class="btn ct-btn ct-btn-view">
                        Actualizar
                    </button>

                    <a href="{{ route('admin.radiotaxis.index') }}" class="btn ct-btn ct-btn-back">
                        Volver
                    </a>
                </div>

            </form>

        </div>
    </div>

@endsection
