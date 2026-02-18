@extends('admin.layout')

@section('title', 'Configuración: Reclamos')

@section('content')
<div class="ct-header mb-4">
    <h2 class="ct-title">Números de Reclamos</h2>
    <div class="ct-subtitle">Estos números se muestran en la app Flutter.</div>
</div>

@if(session('success'))
    <div class="alert alert-success">{{ session('success') }}</div>
@endif

<form method="POST" action="{{ route('admin.settings.reclamos.update') }}">
    @csrf
    @method('PUT')

    <div class="card ct-stat-card">
        <div class="card-body">
            @foreach($items as $it)
                <div class="mb-3">
                    <label class="form-label fw-bold">{{ $it->key }}</label>
                    <input
                        type="text"
                        class="form-control"
                        name="settings[{{ $it->id }}][value]"
                        value="{{ old('settings.'.$it->id.'.value', $it->value) }}"
                        placeholder="Ej: +591 7xxxxxxx"
                    >
                    <div class="form-check mt-2">
                        <input
                            class="form-check-input"
                            type="checkbox"
                            name="settings[{{ $it->id }}][activo]"
                            value="1"
                            {{ $it->activo ? 'checked' : '' }}
                        >
                        <label class="form-check-label">Activo</label>
                    </div>
                </div>
                <hr>
            @endforeach

            <button class="btn ct-btn ct-btn-save">Guardar Cambios</button>
        </div>
    </div>
</form>
@endsection
