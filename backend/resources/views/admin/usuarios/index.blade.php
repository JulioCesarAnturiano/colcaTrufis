@extends('admin.layout')

@section('title', 'Usuarios - Admin')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4 d-flex justify-content-between align-items-center">
        <div>
            <h2 class="ct-title">Usuarios</h2>
            <div class="ct-subtitle">
                Gestión De Usuarios Y Roles Del Panel Administrativo ColcaTrufis
            </div>
        </div>

        @can('admin.usuarios.crear')
            <a href="{{ route('admin.usuarios.crear') }}" class="btn ct-btn ct-btn-create">
                Crear Usuario
            </a>
        @endcan
    </div>

    {{-- Tabla --}}
    @if(isset($usuarios) && count($usuarios) > 0)
        <div class="card ct-stat-card">
            <div class="card-body">

                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead>
                            <tr class="table-light">
                                <th>ID</th>
                                <th>Nombre</th>
                                <th>Email</th>
                                <th>Roles</th>
                                <th style="width: 200px;">Acciones</th>
                            </tr>
                        </thead>

                        <tbody>
                            @foreach($usuarios as $u)
                                <tr>
                                    <td>{{ $u->id }}</td>
                                    <td class="fw-semibold">{{ $u->name }}</td>
                                    <td>{{ $u->email }}</td>
                                    <td>{{ $u->getRoleNames()->join(', ') ?: 'Sin rol' }}</td>
                                    <td>
                                        <div class="d-flex gap-1">

                                            @can('admin.usuarios.editar')
                                                <a
                                                    href="{{ route('admin.usuarios.editar', $u->id) }}"
                                                    class="btn ct-btn ct-btn-view btn-sm"
                                                >
                                                    Editar
                                                </a>
                                            @endcan

                                            @can('admin.usuarios.eliminar')
                                                <form
                                                    action="{{ route('admin.usuarios.eliminar', $u->id) }}"
                                                    method="POST"
                                                    onsubmit="return confirm('¿Eliminar este usuario?');"
                                                >
                                                    @csrf
                                                    @method('DELETE')
                                                    <button class="btn ct-btn ct-btn-danger btn-sm">
                                                        Eliminar
                                                    </button>
                                                </form>
                                            @endcan

                                        </div>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>

            </div>
        </div>
    @else
        <div class="alert alert-info">
            No Hay Usuarios Registrados.
        </div>
    @endif

@endsection
