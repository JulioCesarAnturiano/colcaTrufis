@extends('admin.layout')

@section('title', 'Crear Usuario')

@section('content')
    <h2 class="mb-3">Crear Usuario</h2>

    <form action="{{ route('admin.usuarios.guardar') }}" method="POST">
        @csrf

        <div class="row">
            <div class="col-md-6 mb-3">
                <label class="form-label">Nombre</label>
                <input type="text" name="name" class="form-control" required value="{{ old('name') }}">
            </div>

            <div class="col-md-6 mb-3">
                <label class="form-label">Email</label>
                <input type="email" name="email" class="form-control" required value="{{ old('email') }}">
            </div>

            <div class="col-md-6 mb-3">
                <label class="form-label">Contraseña</label>
                <input type="password" name="password" class="form-control" required>
            </div>

            <div class="col-md-6 mb-3">
                <label class="form-label">Confirmar Contraseña</label>
                <input type="password" name="password_confirmation" class="form-control" required>
            </div>

            <div class="col-md-6 mb-3">
                <label class="form-label">Rol</label>
                <select name="rol" class="form-select" required>
                    <option value="">Seleccione</option>
                    @foreach($roles as $r)
                        <option value="{{ $r }}" @selected(old('rol') == $r)>{{ $r }}</option>
                    @endforeach
                </select>
            </div>
        </div>

        <div class="d-flex gap-2">
            <button class="btn btn-success">Guardar</button>
            <a href="{{ route('admin.usuarios.index') }}" class="btn btn-secondary">Volver</a>
        </div>
    </form>
@endsection
