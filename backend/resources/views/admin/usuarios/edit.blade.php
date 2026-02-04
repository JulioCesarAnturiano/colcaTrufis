@extends('admin.layout')

@section('title', 'Editar Usuario')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4">
        <h2 class="ct-title">Editar Usuario</h2>
        <div class="ct-subtitle">
            Actualización De Datos Y Rol Del Usuario En ColcaTrufis
        </div>
    </div>

    {{-- Formulario --}}
    <div class="card ct-stat-card">
        <div class="card-body">

            <form action="{{ route('admin.usuarios.actualizar', $usuario->id) }}" method="POST">
                @csrf
                @method('PUT')

                <div class="row">

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Nombre</label>
                        <input
                            type="text"
                            name="name"
                            class="form-control"
                            required
                            value="{{ old('name', $usuario->name) }}"
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Email</label>
                        <input
                            type="email"
                            name="email"
                            class="form-control"
                            required
                            value="{{ old('email', $usuario->email) }}"
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">
                            Nueva Contraseña <span class="text-muted">(Opcional)</span>
                        </label>
                        <input
                            type="password"
                            name="password"
                            class="form-control"
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Confirmar Nueva Contraseña</label>
                        <input
                            type="password"
                            name="password_confirmation"
                            class="form-control"
                        >
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label fw-semibold">Rol</label>
                        <select name="rol" class="form-select" required>
                            @foreach($roles as $r)
                                <option
                                    value="{{ $r }}"
                                    @selected($usuario->getRoleNames()->first() == $r)
                                >
                                    {{ $r }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                </div>

                {{-- Acciones --}}
                <div class="d-flex gap-2 mt-3">
                    <button type="submit" class="btn ct-btn ct-btn-view">
                        Actualizar
                    </button>

                    <a href="{{ route('admin.usuarios.index') }}" class="btn ct-btn ct-btn-back">
                        Volver
                    </a>
                </div>

            </form>

        </div>
    </div>

@endsection
