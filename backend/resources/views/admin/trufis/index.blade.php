@extends('admin.layout')

@section('title', 'Trufis - Admin')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4 d-flex justify-content-between align-items-center">
        <div>
            <h2 class="ct-title">Trufis</h2>
            <div class="ct-subtitle">
                Gestión De Líneas De Trufi Registradas En ColcaTrufis
            </div>
        </div>

        @can('admin.trufis.crear')
            <a href="{{ route('admin.trufis.crear') }}" class="btn ct-btn ct-btn-create">
                Crear Trufi
            </a>
        @endcan
    </div>

    {{-- Tabla --}}
    @if($trufis->count())
        <div class="card ct-stat-card">
            <div class="card-body">

                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead>
                            <tr class="table-light">
                                <th>ID</th>
                                <th>Línea</th>
                                <th>Costo</th>
                                <th>Frecuencia</th>
                                <th>Tipo</th>
                                <th>Sindicato</th>
                                <th>Referencias</th>
                                <th>Horario</th>
                                <th>Estado</th>
                                <th style="width: 200px;">Acciones</th>
                            </tr>
                        </thead>

                        <tbody>
                            @foreach($trufis as $t)
                                <tr>
                                    <td>{{ $t->idtrufi }}</td>
                                    <td class="fw-semibold">{{ $t->nom_linea }}</td>
                                    <td>{{ $t->costo }}</td>
                                    <td>{{ $t->frecuencia }}</td>
                                    <td>{{ $t->tipo }}</td>
                                    <td>{{ $t->sindicato->nombre ?? '-' }}</td>
                                    <td>{{ optional($t->detalle)->referencias ?? '-' }}</td>
                                    <td>
                                        @php
                                            $he = optional($t->detalle)->hora_entrada;
                                            $hs = optional($t->detalle)->hora_salida;
                                        @endphp
                                        {{ $he || $hs ? (($he ?? '-') . ' - ' . ($hs ?? '-')) : '-' }}
                                    </td>
                                    <td>
                                        <span class="badge {{ $t->estado ? 'bg-success' : 'bg-secondary' }}">
                                            {{ $t->estado ? 'Activo' : 'Inactivo' }}
                                        </span>
                                    </td>
                                    <td>
                                        <div class="d-flex gap-1">

                                            @can('admin.trufis.editar')
                                                <a
                                                    href="{{ route('admin.trufis.editar', $t->idtrufi) }}"
                                                    class="btn ct-btn ct-btn-view btn-sm"
                                                >
                                                    Editar
                                                </a>
                                            @endcan

                                            @can('admin.trufis.eliminar')
                                                <form
                                                    action="{{ route('admin.trufis.eliminar', $t->idtrufi) }}"
                                                    method="POST"
                                                    onsubmit="return confirm('¿Eliminar este trufi?');"
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
            {{ $trufis->links() }}
        </div>
    @else
        <div class="alert alert-info">
            No Hay Trufis Registrados.
        </div>
    @endif

@endsection