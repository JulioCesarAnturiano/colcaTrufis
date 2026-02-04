@extends('admin.layout')

@section('title', 'Sindicatos - Admin')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4 d-flex justify-content-between align-items-center">
        <div>
            <h2 class="ct-title">Sindicatos</h2>
            <div class="ct-subtitle">
                Gestión De Sindicatos Registrados En ColcaTrufis
            </div>
        </div>

        @can('admin.sindicatos.crear')
            <a href="{{ route('admin.sindicatos.crear') }}" class="btn ct-btn ct-btn-create">
                Crear Sindicato
            </a>
        @endcan
    </div>

    {{-- Tabla --}}
    @if(isset($sindicatos) && count($sindicatos) > 0)
        <div class="card ct-stat-card">
            <div class="card-body">

                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead>
                            <tr class="table-light">
                                <th>ID</th>
                                <th>Nombre</th>
                                <th>Descripción</th>
                                <th style="width: 200px;">Acciones</th>
                            </tr>
                        </thead>

                        <tbody>
                            @foreach($sindicatos as $s)
                                <tr>
                                    <td>{{ $s->id }}</td>
                                    <td class="fw-semibold">{{ $s->nombre }}</td>
                                    <td>{{ $s->descripcion ?? '-' }}</td>
                                    <td>
                                        <div class="d-flex gap-1">

                                            @can('admin.sindicatos.editar')
                                                <a
                                                    href="{{ route('admin.sindicatos.editar', $s->id) }}"
                                                    class="btn ct-btn ct-btn-view btn-sm"
                                                >
                                                    Editar
                                                </a>
                                            @endcan

                                            @can('admin.sindicatos.eliminar')
                                                <form
                                                    action="{{ route('admin.sindicatos.eliminar', $s->id) }}"
                                                    method="POST"
                                                    onsubmit="return confirm('¿Eliminar este sindicato?');"
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
            {{ $sindicatos->links() }}
        </div>
    @else
        <div class="alert alert-info">
            No Hay Sindicatos Registrados.
        </div>
    @endif

@endsection
