@extends('admin.layout')

@section('title', 'Sindicatos - Admin')

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2>Sindicatos</h2>

        @can('admin.sindicatos.crear')
            <a class="btn btn-success" href="{{ route('admin.sindicatos.crear') }}">Crear Sindicato</a>
        @endcan
    </div>

    @if(isset($sindicatos) && count($sindicatos) > 0)
        <div class="table-responsive">
            <table class="table table-bordered align-middle">
                <thead class="table-dark">
                <tr>
                    <th>ID</th>
                    <th>Nombre</th>
                    <th>Descripción</th>
                    <th style="width: 220px;">Acciones</th>
                </tr>
                </thead>
                <tbody>
                @foreach($sindicatos as $s)
                    <tr>
                        <td>{{ $s->id }}</td>
                        <td>{{ $s->nombre }}</td>
                        <td>{{ $s->descripcion ?? '-' }}</td>
                        <td>
                            @can('admin.sindicatos.editar')
                                <a class="btn btn-sm btn-primary" href="{{ route('admin.sindicatos.editar', $s->id) }}">Editar</a>
                            @endcan

                            @can('admin.sindicatos.eliminar')
                                <form action="{{ route('admin.sindicatos.eliminar', $s->id) }}"
                                      method="POST" class="d-inline"
                                      onsubmit="return confirm('¿Eliminar este sindicato?');">
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

        <div class="mt-3">
            {{ $sindicatos->links() }}
        </div>
    @else
        <div class="alert alert-info">No hay sindicatos registrados.</div>
    @endif
@endsection
