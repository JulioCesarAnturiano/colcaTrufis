@extends('admin.layout')

@section('title', 'Crear Ruta')

@section('content')
    <h2 class="mb-3">Crear Ruta</h2>

    <form action="{{ route('admin.rutas.guardar') }}" method="POST">
        @csrf

        <div class="row">
            <div class="col-md-4 mb-3">
                <label class="form-label">ID Trufi</label>
                <input type="number" name="idtrufi" class="form-control" required value="{{ old('idtrufi') }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Latitud</label>
                <input type="text" name="latitud" class="form-control" required value="{{ old('latitud') }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Longitud</label>
                <input type="text" name="longitud" class="form-control" required value="{{ old('longitud') }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Orden</label>
                <input type="number" name="orden" class="form-control" value="{{ old('orden', 1) }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Es Parada</label>
                <select name="es_parada" class="form-select">
                    <option value="1" selected>Sí</option>
                    <option value="0">No</option>
                </select>
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Estado</label>
                <select name="estado" class="form-select">
                    <option value="1" selected>Activo</option>
                    <option value="0">Inactivo</option>
                </select>
            </div>
        </div>

        <div class="d-flex gap-2">
            <button class="btn btn-success">Guardar</button>
            <a href="{{ route('admin.rutas.index') }}" class="btn btn-secondary">Volver</a>
        </div>
    </form>
@endsection
