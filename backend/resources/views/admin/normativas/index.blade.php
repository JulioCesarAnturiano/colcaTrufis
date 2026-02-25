@extends('admin.layout')

@section('title', 'Normativas')

@section('content')

<div class="ct-header mb-4">
    <h2 class="ct-title">Normativas</h2>
    <div class="ct-subtitle">
        Gestión De Normativas En PDF Del Sistema
    </div>
</div>

<div class="card ct-stat-card">
    <div class="card-body">

        <div class="mb-3 text-end">
            @can('admin.normativas.crear')
                <a href="{{ route('admin.normativas.crear') }}" class="btn ct-btn ct-btn-save">
                    Nueva Normativa
                </a>
            @endcan
        </div>

        <table class="table table-bordered align-middle">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Título</th>
                    <th>Categoría</th>
                    <th>Versión</th>
                    <th>Activo</th>
                    <th style="width:320px;">Acciones</th>
                </tr>
            </thead>
            <tbody>
                @forelse($items as $n)
                    <tr>
                        <td>{{ $n->id }}</td>
                        <td>{{ $n->titulo }}</td>
                        <td>{{ $n->categoria ?? '-' }}</td>
                        <td>{{ $n->version ?? '-' }}</td>
                        <td>
                            @if($n->activo)
                                <span class="badge bg-success">Sí</span>
                            @else
                                <span class="badge bg-secondary">No</span>
                            @endif
                        </td>
                        <td>
                            <div class="d-flex gap-2 flex-wrap">

                                {{-- VER PDF (ADMIN: web.php + NormativaAdminController@verPdf) --}}
                                @can('admin.normativas.ver')
                                    <a href="{{ route('admin.normativas.verPdf', $n->id) }}"
                                       target="_blank"
                                       class="btn btn-sm btn-info">
                                        Ver
                                    </a>
                                @endcan

                                {{-- DESCARGAR (API PÚBLICA) --}}
                                <a href="{{ url('/api/normativas/'.$n->id.'/download') }}"
                                   class="btn btn-sm btn-secondary">
                                    Descargar
                                </a>

                                @can('admin.normativas.editar')
                                    <a href="{{ route('admin.normativas.editar', $n->id) }}"
                                       class="btn btn-sm btn-warning">
                                        Editar
                                    </a>
                                @endcan

                                @can('admin.normativas.eliminar')
                                    <form method="POST"
                                          action="{{ route('admin.normativas.destroy', $n->id) }}"
                                          onsubmit="return confirm('¿Eliminar normativa?')">
                                        @csrf
                                        @method('DELETE')
                                        <button class="btn btn-sm btn-danger">
                                            Eliminar
                                        </button>
                                    </form>
                                @endcan

                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="text-center">
                            No Hay Normativas Registradas
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
<div class="mt-3">
            {{ $items->links() }}
        </div>
    </div>
</div>

@endsection
