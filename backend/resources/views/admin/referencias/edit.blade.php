@extends('admin.layout')

@section('title', 'Editar Referencia')

@section('content')
<div class="container-fluid">
    <div class="d-flex align-items-center justify-content-between mb-3">
        <h4 class="mb-0">Editar Referencia</h4>
        <a href="{{ route('admin.referencias') }}" class="btn btn-secondary">Volver</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger">
            <strong>Revisa los campos:</strong>
            <ul class="mb-0">
                @foreach ($errors->all() as $e)
                    <li>{{ $e }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    @php
        $isTaxi  = $referencia->referenciable_type === \App\Models\Sindicatoradiotaxi::class;
        $isTrufi = $referencia->referenciable_type === \App\Models\Trufi::class;
    @endphp

    <div class="card">
        <div class="card-body">
            <form action="{{ route('admin.referencias.actualizar', $referencia->id) }}" method="POST" id="refForm">
                @csrf
                @method('PUT')

                <div class="mb-3">
                    <label class="form-label">Referencia</label>
                    <input type="text"
                           name="referencia"
                           class="form-control"
                           value="{{ old('referencia', $referencia->referencia) }}"
                           required>
                </div>

                <div class="mb-3">
                    <label class="form-label">Asignar A</label>

                    <div class="d-flex gap-3 mb-2">
                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="tipo" id="tipoTaxi" value="taxi"
                                   {{ old('tipo', $isTaxi ? 'taxi' : 'trufi') === 'taxi' ? 'checked' : '' }}>
                            <label class="form-check-label" for="tipoTaxi">Taxi</label>
                        </div>

                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="tipo" id="tipoTrufi" value="trufi"
                                   {{ old('tipo', $isTaxi ? 'taxi' : 'trufi') === 'trufi' ? 'checked' : '' }}>
                            <label class="form-check-label" for="tipoTrufi">Trufi</label>
                        </div>
                    </div>

                    <div class="mb-2" id="taxiSelectWrap">
                        <label class="form-label">Selecciona Un Taxi</label>
                        <select class="form-select" id="taxiSelect">
                            <option value="">-- Selecciona --</option>
                            @foreach($taxis as $t)
                                <option value="{{ $t->id }}"
                                    {{ (int) old('taxi_id', $isTaxi ? $referencia->referenciable_id : 0) === (int) $t->id ? 'selected' : '' }}>
                                    {{ $t->nombre_comercial ?? ('Taxi #' . $t->id) }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div class="mb-2" id="trufiSelectWrap">
                        <label class="form-label">Selecciona Un Trufi</label>
                        <select class="form-select" id="trufiSelect">
                            <option value="">-- Selecciona --</option>
                            @foreach($trufis as $tr)
                                <option value="{{ $tr->idtrufi }}"
                                    {{ (int) old('trufi_id', $isTrufi ? $referencia->referenciable_id : 0) === (int) $tr->idtrufi ? 'selected' : '' }}>
                                    {{ $tr->nom_linea ?? ('Trufi #' . $tr->idtrufi) }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <input type="hidden" name="referenciable_type" id="referenciableType" value="">
                    <input type="hidden" name="referenciable_id" id="referenciableId" value="">
                </div>

                <div class="d-flex gap-2">
                    <button class="btn btn-primary" type="submit">Actualizar</button>
                    <a href="{{ route('admin.referencias') }}" class="btn btn-secondary">Cancelar</a>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
(function () {
    // Strings Correctos Para Morph (Con Backslashes)
    const taxiClass  = "App\\\\Models\\\\Sindicatoradiotaxi";
    const trufiClass = "App\\\\Models\\\\Trufi";

    const tipoTaxi  = document.getElementById('tipoTaxi');
    const tipoTrufi = document.getElementById('tipoTrufi');

    const taxiWrap  = document.getElementById('taxiSelectWrap');
    const trufiWrap = document.getElementById('trufiSelectWrap');

    const taxiSelect  = document.getElementById('taxiSelect');
    const trufiSelect = document.getElementById('trufiSelect');

    const refType = document.getElementById('referenciableType');
    const refId   = document.getElementById('referenciableId');

    function sync() {
        if (tipoTaxi.checked) {
            taxiWrap.classList.remove('d-none');
            trufiWrap.classList.add('d-none');
            refType.value = taxiClass;
            refId.value = taxiSelect.value || '';
        } else {
            trufiWrap.classList.remove('d-none');
            taxiWrap.classList.add('d-none');
            refType.value = trufiClass;
            refId.value = trufiSelect.value || '';
        }
    }

    tipoTaxi.addEventListener('change', sync);
    tipoTrufi.addEventListener('change', sync);
    taxiSelect.addEventListener('change', sync);
    trufiSelect.addEventListener('change', sync);

    document.getElementById('refForm').addEventListener('submit', function (e) {
        sync();
        if (!refType.value || !refId.value) {
            e.preventDefault();
            alert('Debes Seleccionar Un Taxi O Un Trufi Antes De Actualizar.');
        }
    });

    // Estado Inicial
    sync();
})();
</script>
@endsection