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
                    <th>Trufi</th>
                    <th>Puntos</th>
                    <th>Orden Inicio</th>
                    <th>Orden Fin</th>
                    <th style="width: 220px;">Acciones</th>
                </tr>
                </thead>
                <tbody>
                @foreach($rutas as $r)
                    @php
                        $trufi = $trufis->firstWhere('idtrufi', $r->idtrufi);
                    @endphp
                    <tr>
                        <td>{{ $r->idtrufi }}</td>
                        <td>{{ $trufi ? $trufi->nom_linea : 'Sin nombre' }}</td>
                        <td>{{ $r->total_puntos }}</td>
                        <td>{{ $r->orden_inicio }}</td>
                        <td>{{ $r->orden_fin }}</td>
                        <td>
                            @can('admin.rutas.editar')
                                <a class="btn btn-sm btn-primary"
                                   href="{{ route('admin.rutas.editar', ['idtrufi' => $r->idtrufi]) }}">
                                    Editar
                                </a>
                            @endcan

                            @can('admin.rutas.eliminar')
                                <form action="{{ route('admin.rutas.eliminar', ['idtrufi' => $r->idtrufi]) }}"
                                      method="POST" class="d-inline"
                                      onsubmit="return confirm('¿Eliminar toda la ruta de este trufi?');">
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
            {{ $rutas->links() }}
        </div>
    @else
        <div class="alert alert-info">No hay rutas registradas.</div>
    @endif
@endsection
