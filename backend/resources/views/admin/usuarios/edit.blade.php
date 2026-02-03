@extends('admin.layout')

@section('title', 'Editar Usuario')

@section('content')
    <h2 class="mb-3">Editar Usuario</h2>

    <form action="{{ route('admin.usuarios.actualizar', $usuario->id) }}" method="POST">
        @csrf
        @method('PUT')

        <div class="row">
            <div class="col-md-6 mb-3">
                <label class="form-label">Nombre</label>
                <input type="text" name="name" class="form-control" required value="{{ old('name', $usuario->name) }}">
            </div>

            <div class="col-md-6 mb-3">
                <label class="form-label">Email</label>
                <input type="email" name="email" class="form-control" required value="{{ old('email', $usuario->email) }}">
            </div>

            <div class="col-md-6 mb-3">
                <label class="form-label">Nueva Contraseña (Opcional)</label>
                <input type="password" name="password" class="form-control">
            </div>

            <div class="col-md-6 mb-3">
                <label class="form-label">Confirmar Nueva Contraseña</label>
                <input type="password" name="password_confirmation" class="form-control">
            </div>

            <div class="col-md-6 mb-3">
                <label class="form-label">Rol</label>
                <select name="rol" class="form-select" required>
                    @foreach($roles as $r)
                        <option value="{{ $r }}" @selected($usuario->getRoleNames()->first() == $r)>{{ $r }}</option>
                    @endforeach
                </select>
            </div>
        </div>

        <div class="d-flex gap-2">
            <button class="btn btn-primary">Actualizar</button>
            <a href="{{ route('admin.usuarios.index') }}" class="btn btn-secondary">Volver</a>
        </div>
    </form>
@endsection
