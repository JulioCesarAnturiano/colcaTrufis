@extends('admin.layout')

@section('title', 'Rutas - Admin')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4 d-flex justify-content-between align-items-center">
        <div>
            <h2 class="ct-title">Rutas</h2>
            <div class="ct-subtitle">
                Gestión De Rutas Asociadas A Trufis En ColcaTrufis
            </div>
        </div>

        @can('admin.rutas.crear')
            <a href="{{ route('admin.rutas.crear') }}" class="btn ct-btn ct-btn-create">
                Crear Ruta
            </a>
        @endcan
    </div>

    {{-- Tabla --}}
    @if(isset($rutas) && count($rutas) > 0)
        <div class="card ct-stat-card">
            <div class="card-body">

                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead>
                            <tr class="table-light">
                                <th>ID Trufi</th>
                                <th>Trufi</th>
                                <th>Puntos</th>
                                <th>Orden Inicio</th>
                                <th>Orden Fin</th>
                                <th style="width: 200px;">Acciones</th>
                            </tr>
                        </thead>

                        <tbody>
                            @foreach($rutas as $r)
                                @php
                                    $trufi = $trufis->firstWhere('idtrufi', $r->idtrufi);
                                @endphp

                                <tr>
                                    <td>{{ $r->idtrufi }}</td>
                                    <td class="fw-semibold">{{ $trufi ? $trufi->nom_linea : 'Sin Nombre' }}</td>
                                    <td>{{ $r->total_puntos }}</td>
                                    <td>{{ $r->orden_inicio }}</td>
                                    <td>{{ $r->orden_fin }}</td>
                                    <td>
                                        <div class="d-flex gap-1">

                                            @can('admin.rutas.editar')
                                                <a
                                                    href="{{ route('admin.rutas.editar', ['idtrufi' => $r->idtrufi]) }}"
                                                    class="btn ct-btn ct-btn-view btn-sm"
                                                >
                                                    Editar
                                                </a>
                                            @endcan

                                            @can('admin.rutas.eliminar')
                                                <form
                                                    action="{{ route('admin.rutas.eliminar', ['idtrufi' => $r->idtrufi]) }}"
                                                    method="POST"
                                                    onsubmit="return confirm('¿Eliminar toda la ruta de este trufi?');"
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

        {{-- Paginación --}}
        <div class="mt-3">
            {{ $rutas->links() }}
        </div>
    @else
        <div class="alert alert-info">
            No Hay Rutas Registradas.
        </div>
    @endif

@endsection
