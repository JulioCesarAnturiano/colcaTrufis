{{-- resources/views/admin/rutas/edit.blade.php --}}
@extends('admin.layout')

@section('title', 'Editar Ruta')

@section('content')
    <h2 class="mb-3">Editar Ruta</h2>

    <form action="{{ route('admin.rutas.actualizar', ['idtrufi' => $ruta->idtrufi, 'orden' => $ruta->orden]) }}" method="POST">
        @csrf
        @method('PUT')

        <div class="row">
            <div class="col-md-4 mb-3">
                <label class="form-label">ID Trufi</label>
                <input type="number" name="idtrufi" class="form-control" required value="{{ old('idtrufi', $ruta->idtrufi) }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Latitud</label>
                <input type="text" name="latitud" class="form-control" required value="{{ old('latitud', $ruta->latitud) }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Longitud</label>
                <input type="text" name="longitud" class="form-control" required value="{{ old('longitud', $ruta->longitud) }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Orden</label>
                <input type="number" name="orden" class="form-control" value="{{ old('orden', $ruta->orden) }}">
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Es Parada</label>
                <select name="es_parada" class="form-select">
                    <option value="1" @selected(old('es_parada', $ruta->es_parada) == 1)>Sí</option>
                    <option value="0" @selected(old('es_parada', $ruta->es_parada) == 0)>No</option>
                </select>
            </div>

            <div class="col-md-4 mb-3">
                <label class="form-label">Estado</label>
                <select name="estado" class="form-select">
                    <option value="1" @selected(old('estado', $ruta->estado) == 1)>Activo</option>
                    <option value="0" @selected(old('estado', $ruta->estado) == 0)>Inactivo</option>
                </select>
            </div>
        </div>

        <div class="d-flex gap-2">
            <button class="btn btn-primary">Actualizar</button>
            <a href="{{ route('admin.rutas.index') }}" class="btn btn-secondary">Volver</a>
        </div>
    </form>
@endsection
