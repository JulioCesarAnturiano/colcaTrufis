@extends('admin.layout')

@section('title', 'Crear RadioTaxi')

@section('content')
    <h2 class="mb-3">Crear RadioTaxi</h2>

    <form action="{{ route('admin.radiotaxis.guardar') }}" method="POST">
        @csrf

        <div class="row">
            <div class="col-md-6 mb-3">
                <label class="form-label">Nombre Comercial</label>
                <input type="text" name="nombre_comercial" class="form-control" required value="{{ old('nombre_comercial') }}">
            </div>

            <div class="col-md-6 mb-3">
                <label class="form-label">Teléfono Base</label>
                <input type="text" name="telefono_base" class="form-control" required value="{{ old('telefono_base') }}">
            </div>
        </div>

        <div class="d-flex gap-2">
            <button class="btn btn-success">Guardar</button>
            <a href="{{ route('admin.radiotaxis.index') }}" class="btn btn-secondary">Volver</a>
        </div>
    </form>
@endsection
