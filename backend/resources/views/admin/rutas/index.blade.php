{{-- resources/views/admin/rutas/index.blade.php --}}
@extends('admin.layout')

@section('title', 'Rutas - Admin')

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2>Rutas</h2>

        @can('admin.rutas.crear')
            <a class="btn btn-success" href="{{ route('admin.rutas.crear') }}">Crear Ruta</a>
        @endcan
    </div>

    @if(isset($rutas) && count($rutas) > 0)
        <div class="table-responsive">
            <table class="table table-bordered align-middle">
                <thead class="table-dark">
                <tr>
                    <th>ID Trufi</th>
                    <th>Latitud</th>
                    <th>Longitud</th>
                    <th>Orden</th>
                    <th>Es Parada</th>
                    <th>Estado</th>
                    <th style="width: 220px;">Acciones</th>
                </tr>
                </thead>
                <tbody>
                @foreach($rutas as $r)
                    <tr>
                        <td>{{ $r->idtrufi }}</td>
                        <td>{{ $r->latitud }}</td>
                        <td>{{ $r->longitud }}</td>
                        <td>{{ $r->orden }}</td>
                        <td>{{ $r->es_parada ? 'Sí' : 'No' }}</td>
                        <td>{{ $r->estado ? 'Activo' : 'Inactivo' }}</td>
                        <td>
                            @can('admin.rutas.editar')
                                <a class="btn btn-sm btn-primary"
                                   href="{{ route('admin.rutas.editar', ['idtrufi' => $r->idtrufi, 'orden' => $r->orden]) }}">
                                    Editar
                                </a>
                            @endcan

                            @can('admin.rutas.eliminar')
                                <form action="{{ route('admin.rutas.eliminar', ['idtrufi' => $r->idtrufi, 'orden' => $r->orden]) }}"
                                      method="POST" class="d-inline"
                                      onsubmit="return confirm('¿Eliminar esta ruta?');">
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

        {{-- Paginación --}}
        <div class="mt-3">
            {{ $rutas->links() }}
        </div>
    @else
        <div class="alert alert-info">No hay rutas registradas.</div>
    @endif
@endsection
