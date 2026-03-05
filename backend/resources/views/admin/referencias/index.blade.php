@extends('admin.layout')

@section('title', 'Referencias - Admin')

@section('content')
<div class="container-fluid">
    <div class="d-flex align-items-center justify-content-between mb-3">
        <h4 class="mb-0">Referencias</h4>

        @can('admin.referencias.crear')
        <a href="{{ route('admin.referencias.crear') }}" class="btn btn-primary">
            Nueva Referencia
        </a>
        @endcan
    </div>

    @if(session('success'))
        <div class="alert alert-success">{{ session('success') }}</div>
    @endif

    <div class="card">
        <div class="card-body table-responsive">
            <table class="table table-striped align-middle">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Referencia</th>
                        <th>Tipo</th>
                        <th>Asignado A (ID)</th>
                        <th class="text-end">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                @forelse($referencias as $ref)
                    @php
                        $tipo = 'Otro';
                        if ($ref->referenciable_type === \App\Models\Sindicatoradiotaxi::class) $tipo = 'RadioTaxi';
                        if ($ref->referenciable_type === \App\Models\Trufi::class) $tipo = 'Trufi';
                    @endphp
                    <tr>
                        <td>{{ $ref->id }}</td>
                        <td>{{ $ref->referencia }}</td>
                        <td>{{ $tipo }}</td>
                        <td>{{ $ref->referenciable_id }}</td>
                        <td class="text-end">
                            @can('admin.referencias.editar')
                            <a class="btn btn-sm btn-warning"
                               href="{{ route('admin.referencias.editar', $ref->id) }}">
                                Editar
                            </a>
                            @endcan

                            @can('admin.referencias.eliminar')
                            <form action="{{ route('admin.referencias.eliminar', $ref->id) }}"
                                  method="POST" class="d-inline"
                                  onsubmit="return confirm('¿Eliminar esta referencia?');">
                                @csrf
                                @method('DELETE')
                                <button class="btn btn-sm btn-danger" type="submit">
                                    Eliminar
                                </button>
                            </form>
                            @endcan
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" class="text-center text-muted py-4">
                            No hay referencias registradas.
                        </td>
                    </tr>
                @endforelse
                </tbody>
            </table>

            <div class="mt-3">
                {{ $referencias->links() }}
            </div>
        </div>
    </div>
</div>
@endsection