@extends('admin.layout')

@section('title', 'Usuarios - Admin')

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2>Usuarios</h2>

        @can('admin.usuarios.crear')
            <a class="btn btn-success" href="{{ route('admin.usuarios.crear') }}">Crear Usuario</a>
        @endcan
    </div>

    @if(isset($usuarios) && count($usuarios) > 0)
        <div class="table-responsive">
            <table class="table table-bordered align-middle">
                <thead class="table-dark">
                <tr>
                    <th>ID</th>
                    <th>Nombre</th>
                    <th>Email</th>
                    <th>Roles</th>
                    <th style="width: 220px;">Acciones</th>
                </tr>
                </thead>
                <tbody>
                @foreach($usuarios as $u)
                    <tr>
                        <td>{{ $u->id }}</td>
                        <td>{{ $u->name }}</td>
                        <td>{{ $u->email }}</td>
                        <td>{{ $u->getRoleNames()->join(', ') ?: 'Sin rol' }}</td>
                        <td>
                            @can('admin.usuarios.editar')
                                <a class="btn btn-sm btn-primary" href="{{ route('admin.usuarios.editar', $u->id) }}">
                                    Editar
                                </a>
                            @endcan

                            @can('admin.usuarios.eliminar')
                                <form action="{{ route('admin.usuarios.eliminar', $u->id) }}"
                                      method="POST" class="d-inline"
                                      onsubmit="return confirm('¿Eliminar este usuario?');">
                                    @csrf
                                    @method('DELETE')
                                    <button class="btn btn-sm btn-danger">Eliminar</button>
                                </form>
                            @endcan
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>
    @else
        <div class="alert alert-info">No hay usuarios registrados.</div>
    @endif
@endsection
