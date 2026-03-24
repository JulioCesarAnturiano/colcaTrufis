@extends('admin.layout')

@section('title', 'RadioTaxis - Admin')

@section('content')

    {{-- Header --}}
    <div class="ct-header mb-4 d-flex justify-content-between align-items-center">
        <div>
            <h2 class="ct-title">RadioTaxis</h2>
            <div class="ct-subtitle">
                Gestión De RadioTaxis Registrados En El Sistema ColcaTrufis
            </div>
        </div>

        @can('admin.radiotaxis.crear')
            <a href="{{ route('admin.radiotaxis.crear') }}" class="btn ct-btn ct-btn-create">
                Crear RadioTaxi
            </a>
        @endcan
    </div>

    {{-- Tabla --}}
    @if(isset($radiotaxis) && count($radiotaxis) > 0)
        <div class="card ct-stat-card">
            <div class="card-body">

                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead>
                            <tr class="table-light">
                                <th>ID</th>
                                <th>Nombre Comercial</th>
                                <th>Teléfono Base</th>
                                <th>Ubicación</th>
                                <th style="width: 200px;">Acciones</th>
                            </tr>
                        </thead>

                        <tbody>
                            @foreach($radiotaxis as $r)
                                <tr>
                                    <td>{{ $r->id }}</td>
                                    <td class="fw-semibold">{{ $r->nombre_comercial }}</td>
                                    <td>{{ $r->telefono_base }}</td>
                                    <td>{{ optional($r->parada)->ubicacion ?? '—' }}</td>
                                    <td>
                                        <div class="d-flex gap-1">

                                            @can('admin.radiotaxis.editar')
                                                <a
                                                    href="{{ route('admin.radiotaxis.editar', $r->id) }}"
                                                    class="btn ct-btn ct-btn-view btn-sm"
                                                >
                                                    Editar
                                                </a>
                                            @endcan

                                            @can('admin.radiotaxis.eliminar')
                                                <form
                                                    action="{{ route('admin.radiotaxis.eliminar', $r->id) }}"
                                                    method="POST"
                                                    onsubmit="return confirm('¿Eliminar este radiotaxi?');"
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
            {{ $radiotaxis->links() }}
        </div>
    @else
        <div class="alert alert-info">
            No Hay RadioTaxis Registrados.
        </div>
    @endif

@endsection
