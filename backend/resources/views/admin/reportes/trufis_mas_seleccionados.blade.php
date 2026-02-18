@extends('admin.layout')

@section('title', 'Reporte: Trufis Más Seleccionados')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-3">
    <h2 class="mb-0">Trufis Más Seleccionados (Últimos {{ $dias }} Días)</h2>

    <form method="GET" class="d-flex gap-2">
        <select name="dias" class="form-select" style="width: 180px;">
            <option value="7"  {{ $dias==7 ? 'selected' : '' }}>Últimos 7 días</option>
            <option value="30" {{ $dias==30 ? 'selected' : '' }}>Últimos 30 días</option>
            <option value="90" {{ $dias==90 ? 'selected' : '' }}>Últimos 90 días</option>
        </select>
        <button class="btn btn-primary" type="submit">Ver</button>
    </form>
</div>

<div class="card">
    <div class="card-body">
        @if($top->isEmpty())
            <p class="text-muted mb-0">No hay selecciones registradas en este período.</p>
        @else
            <div class="table-responsive">
                <table class="table table-striped align-middle">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Trufi</th>
                            <th>Tipo</th>
                            <th>Selecciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($top as $i => $row)
                            <tr>
                                <td>{{ $i + 1 }}</td>
                                <td>{{ optional($row->trufi)->nom_linea ?? ('ID ' . $row->idtrufi) }}</td>
                                <td>{{ optional($row->trufi)->tipo ?? '-' }}</td>
                                <td><strong>{{ $row->total }}</strong></td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </div>
</div>
@endsection
