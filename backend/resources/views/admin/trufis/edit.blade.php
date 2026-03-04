@extends('admin.layout')

@section('title', 'Editar Trufi')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4">
        <h2 class="ct-title">Editar Trufi</h2>
        <div class="ct-subtitle">
            Actualiza La Información De La Línea Seleccionada En ColcaTrufis
        </div>
    </div>

    {{-- Formulario --}}
    <div class="card ct-stat-card">
        <div class="card-body">

            <form action="{{ route('admin.trufis.actualizar', $trufi->idtrufi) }}" method="POST">
                @csrf
                @method('PUT')

                <div class="row">

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Nombre De Línea</label>
                        <input
                            type="text"
                            name="nom_linea"
                            class="form-control"
                            required
                            value="{{ old('nom_linea', $trufi->nom_linea) }}"
                        >
                    </div>

                    <div class="col-md-3 mb-3">
                        <label class="form-label fw-semibold">Costo</label>
                        <input
                            type="number"
                            step="0.01"
                            name="costo"
                            class="form-control"
                            required
                            value="{{ old('costo', $trufi->costo) }}"
                        >
                    </div>

                    <div class="col-md-3 mb-3">
                        <label class="form-label fw-semibold">Frecuencia</label>
                        <input
                            type="number"
                            name="frecuencia"
                            class="form-control"
                            required
                            value="{{ old('frecuencia', $trufi->frecuencia) }}"
                        >
                    </div>

                    <div class="col-md-4 mb-3">
                        <label class="form-label fw-semibold">Tipo</label>
                        <input
                            type="text"
                            name="tipo"
                            class="form-control"
                            required
                            value="{{ old('tipo', $trufi->tipo) }}"
                        >
                    </div>

                    <div class="col-md-4 mb-3">
                        <label class="form-label fw-semibold">Sindicato</label>
                        <select name="sindicato_id" class="form-select" required>
                            <option value="">Seleccione</option>
                            @foreach($sindicatos as $s)
                                <option
                                    value="{{ $s->id }}"
                                    @selected(old('sindicato_id', $trufi->sindicato_id) == $s->id)
                                >
                                    {{ $s->nombre }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div class="col-md-4 mb-3">
                        <label class="form-label fw-semibold">Estado</label>
                        <select name="estado" class="form-select">
                            <option value="1" @selected(old('estado', $trufi->estado) == 1)>Activo</option>
                            <option value="0" @selected(old('estado', $trufi->estado) == 0)>Inactivo</option>
                        </select>
                    </div>

                    <div class="col-12 mb-3">
                        <label class="form-label fw-semibold">Descripción</label>
                        <textarea
                            name="descripcion"
                            class="form-control"
                            rows="3"
                        >{{ old('descripcion', $trufi->descripcion) }}</textarea>
                    </div>

                    {{-- NUEVOS CAMPOS --}}
                    <div class="col-12 mb-3">
                        <hr>
                        <h5 class="mb-3">Detalle De Trufi</h5>
                    </div>

                    <div class="col-md-12 mb-3">
                        <label class="form-label fw-semibold">Referencias</label>
                        <input
                            type="text"
                            name="referencias"
                            class="form-control"
                            required
                            value="{{ old('referencias', optional($trufi->detalle)->referencias) }}"
                            placeholder="Ej: Plaza Principal - Mercado - Hospital"
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Hora Entrada</label>
                        <input
                            type="time"
                            name="hora_entrada"
                            class="form-control"
                            value="{{ old('hora_entrada', optional($trufi->detalle)->hora_entrada) }}"
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Hora Salida</label>
                        <input
                            type="time"
                            name="hora_salida"
                            class="form-control"
                            value="{{ old('hora_salida', optional($trufi->detalle)->hora_salida) }}"
                        >
                    </div>

                </div>

                {{-- Acciones --}}
                <div class="d-flex gap-2 mt-3">
                    <button type="submit" class="btn ct-btn ct-btn-view">
                        Actualizar
                    </button>

                    <a href="{{ route('admin.trufis.index') }}" class="btn ct-btn ct-btn-back">
                        Volver
                    </a>
                </div>

            </form>

        </div>
    </div>

@endsection