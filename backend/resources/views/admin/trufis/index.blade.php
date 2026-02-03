@extends('admin.layout')

@section('title', 'Trufis - Admin')

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2>Trufis</h2>

        @can('admin.trufis.crear')
            <a class="btn btn-success" href="{{ route('admin.trufis.crear') }}">Crear Trufi</a>
        @endcan
    </div>

    @if($trufis->count())
        <div class="table-responsive">
            <table class="table table-bordered align-middle">
                <thead class="table-dark">
                <tr>
                    <th>ID</th>
                    <th>Línea</th>
                    <th>Costo</th>
                    <th>Frecuencia</th>
                    <th>Tipo</th>
                    <th>Sindicato</th>
                    <th>Estado</th>
                    <th style="width: 220px;">Acciones</th>
                </tr>
                </thead>
                <tbody>
                @foreach($trufis as $t)
                    <tr>
                        <td>{{ $t->idtrufi }}</td>
                        <td>{{ $t->nom_linea }}</td>
                        <td>{{ $t->costo }}</td>
                        <td>{{ $t->frecuencia }}</td>
                        <td>{{ $t->tipo }}</td>
                        <td>{{ $t->sindicato->nombre ?? '-' }}</td>
                        <td>
                            <span class="badge {{ $t->estado ? 'bg-success' : 'bg-secondary' }}">
                                {{ $t->estado ? 'Activo' : 'Inactivo' }}
                            </span>
                        </td>
                        <td>
                            @can('admin.trufis.editar')
                                <a class="btn btn-sm btn-primary"
                                   href="{{ route('admin.trufis.editar', $t->idtrufi) }}">
                                    Editar
                                </a>
                            @endcan

                            @can('admin.trufis.eliminar')
                                <form action="{{ route('admin.trufis.eliminar', $t->idtrufi) }}"
                                      method="POST" class="d-inline"
                                      onsubmit="return confirm('¿Eliminar este trufi?');">
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
            {{ $trufis->links() }}
        </div>
    @else
        <div class="alert alert-info">No hay trufis registrados.</div>
    @endif
@endsection
