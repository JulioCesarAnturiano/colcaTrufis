@extends('admin.layout')

@section('title', 'Crear Usuario')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4">
        <h2 class="ct-title">Crear Usuario</h2>
        <div class="ct-subtitle">
            Registro De Nuevo Usuario Para La Administración De ColcaTrufis
        </div>
    </div>

    {{-- Formulario --}}
    <div class="card ct-stat-card">
        <div class="card-body">

            <form action="{{ route('admin.usuarios.guardar') }}" method="POST">
                @csrf

                <div class="row">

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Nombre</label>
                        <input
                            type="text"
                            name="name"
                            class="form-control"
                            required
                            value="{{ old('name') }}"
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Email</label>
                        <input
                            type="email"
                            name="email"
                            class="form-control"
                            required
                            value="{{ old('email') }}"
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Contraseña</label>
                        <input
                            type="password"
                            name="password"
                            class="form-control"
                            required
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Confirmar Contraseña</label>
                        <input
                            type="password"
                            name="password_confirmation"
                            class="form-control"
                            required
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Rol</label>
                        <select name="rol" class="form-select" required>
                            <option value="">Seleccione</option>
                            @foreach($roles as $r)
                                <option value="{{ $r }}" @selected(old('rol') == $r)>
                                    {{ $r }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                </div>

                {{-- Acciones --}}
                <div class="d-flex gap-2 mt-3">
                    <button type="submit" class="btn ct-btn ct-btn-save">
                        Guardar
                    </button>

                    <a href="{{ route('admin.usuarios.index') }}" class="btn ct-btn ct-btn-back">
                        Volver
                    </a>
                </div>

            </form>

        </div>
    </div>

@endsection
