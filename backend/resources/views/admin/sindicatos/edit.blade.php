@extends('admin.layout')

@section('title', 'Editar Sindicato')

@section('content')
    <h2 class="mb-3">Editar Sindicato</h2>

    <form action="{{ route('admin.sindicatos.actualizar', $sindicato->id) }}" method="POST">
        @csrf
        @method('PUT')

        <div class="row">
            <div class="col-md-6 mb-3">
                <label class="form-label">Nombre</label>
                <input type="text" name="nombre" class="form-control" required value="{{ old('nombre', $sindicato->nombre) }}">
            </div>

            <div class="col-12 mb-3">
                <label class="form-label">Descripción</label>
                <textarea name="descripcion" class="form-control" rows="3">{{ old('descripcion', $sindicato->descripcion) }}</textarea>
            </div>
        </div>

        <div class="d-flex gap-2">
            <button class="btn btn-primary">Actualizar</button>
            <a href="{{ route('admin.sindicatos.index') }}" class="btn btn-secondary">Volver</a>
        </div>
    </form>
@endsection
