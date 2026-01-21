@extends('admin.layout')

@section('title', 'Crear Trufi')

@section('content')
    <h2 class="mb-3">Crear Trufi</h2>

    <form action="{{ route('admin.trufis.guardar') }}" method="POST">
        @csrf

        <div class="row">
            <div class="col-md-6 mb-3">
                <label class="form-label">Nombre</label>
                <input type="text" name="nombre" class="form-control" required value="{{ old('nombre') }}">
            </div>

            <div class="col-md-3 mb-3">
                <label class="form-label">Costo</label>
                <input type="number" step="0.01" name="costo" class="form-control" required value="{{ old('costo') }}">
            </div>

            <div class="col-md-3 mb-3">
                <label class="form-label">Frecuencia</label>
                <input type="text" name="frecuencia" class="form-control" value="{{ old('frecuencia') }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Tipo</label>
                <input type="text" name="tipo" class="form-control" value="{{ old('tipo') }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Sindicato</label>
                <input type="text" name="nombre_sindicato" class="form-control" value="{{ old('nombre_sindicato') }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Estado</label>
                <select name="estado" class="form-select">
                    <option value="1" selected>Activo</option>
                    <option value="0">Inactivo</option>
                </select>
            </div>

            <div class="col-12 mb-3">
                <label class="form-label">Descripción</label>
                <textarea name="descripcion" class="form-control" rows="3">{{ old('descripcion') }}</textarea>
            </div>
        </div>

        <div class="d-flex gap-2">
            <button class="btn btn-success">Guardar</button>
            <a href="{{ route('admin.trufis.index') }}" class="btn btn-secondary">Volver</a>
        </div>
    </form>
@endsection
