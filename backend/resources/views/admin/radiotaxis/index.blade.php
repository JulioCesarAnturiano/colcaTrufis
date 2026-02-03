@extends('admin.layout')

@section('title', 'RadioTaxis - Admin')

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2>RadioTaxis</h2>

        @can('admin.radiotaxis.crear')
            <a class="btn btn-success" href="{{ route('admin.radiotaxis.crear') }}">Crear RadioTaxi</a>
        @endcan
    </div>

    @if(isset($radiotaxis) && count($radiotaxis) > 0)
        <div class="table-responsive">
            <table class="table table-bordered align-middle">
                <thead class="table-dark">
                <tr>
                    <th>ID</th>
                    <th>Nombre Comercial</th>
                    <th>Teléfono Base</th>
                    <th style="width: 220px;">Acciones</th>
                </tr>
                </thead>
                <tbody>
                @foreach($radiotaxis as $r)
                    <tr>
                        <td>{{ $r->id }}</td>
                        <td>{{ $r->nombre_comercial }}</td>
                        <td>{{ $r->telefono_base }}</td>
                        <td>
                            @can('admin.radiotaxis.editar')
                                <a class="btn btn-sm btn-primary" href="{{ route('admin.radiotaxis.editar', $r->id) }}">Editar</a>
                            @endcan

                            @can('admin.radiotaxis.eliminar')
                                <form action="{{ route('admin.radiotaxis.eliminar', $r->id) }}"
                                      method="POST" class="d-inline"
                                      onsubmit="return confirm('¿Eliminar este radiotaxi?');">
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
            {{ $radiotaxis->links() }}
        </div>
    @else
        <div class="alert alert-info">No hay radiotaxis registrados.</div>
    @endif
@endsection
