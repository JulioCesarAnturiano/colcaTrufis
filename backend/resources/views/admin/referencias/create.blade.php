@extends('admin.layout')

@section('title', 'Crear Referencias')

@section('content')
<div class="container-fluid">
    <div class="d-flex align-items-center justify-content-between mb-3">
        <h4 class="mb-0">Crear Referencia</h4>
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

    <div class="card">
        <div class="card-body">
            <form action="{{ route('admin.referencias.guardar') }}" method="POST" id="refForm">
                @csrf

                <div class="mb-3">
                    <label class="form-label">Referencia</label>
                    <input type="text"
                           name="referencia"
                           class="form-control"
                           value="{{ old('referencia') }}"
                           required>
                </div>

                <div class="mb-3">
                    <label class="form-label">Asignar A</label>

                    <div class="d-flex gap-3 mb-2">
                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="tipo" id="tipoTaxi" value="taxi"
                                   {{ old('tipo', 'taxi') === 'taxi' ? 'checked' : '' }}>
                            <label class="form-check-label" for="tipoTaxi">RadioTaxi</label>
                        </div>

                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="tipo" id="tipoTrufi" value="trufi"
                                   {{ old('tipo') === 'trufi' ? 'checked' : '' }}>
                            <label class="form-check-label" for="tipoTrufi">Trufi</label>
                        </div>
                    </div>

                    <div class="mb-2" id="taxiSelectWrap">
                        <label class="form-label">Selecciona Un RadioTaxi</label>
                        <select class="form-select" id="taxiSelect" name="taxi_id">
                            <option value="">-- Selecciona --</option>
                            @foreach($taxis as $t)
                                <option value="{{ $t->id }}" @selected(old('taxi_id') == $t->id)>
                                    {{ $t->nombre_comercial ?? ('RadioTaxi #' . $t->id) }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div class="mb-2 d-none" id="trufiSelectWrap">
                        <label class="form-label">Selecciona Un Trufi</label>
                        <select class="form-select" id="trufiSelect" name="trufi_id">
                            <option value="">-- Selecciona --</option>
                            @foreach($trufis as $tr)
                                <option value="{{ $tr->idtrufi }}" @selected(old('trufi_id') == $tr->idtrufi)>
                                    {{ $tr->nom_linea ?? ('Trufi #' . $tr->idtrufi) }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    {{-- Campos Polimórficos Reales --}}
                    <input type="hidden" name="referenciable_type" id="referenciableType" value="">
                    <input type="hidden" name="referenciable_id" id="referenciableId" value="">
                    <small class="text-muted">Debes seleccionar un RadioTaxi o un Trufi para guardar.</small>
                </div>

                <button class="btn btn-primary" type="submit">Guardar</button>
            </form>
        </div>
    </div>
</div>

<script>
(function () {
    // IMPORTANTE: Enviar El FQCN Con Backslashes Correctos
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
            refId.value   = taxiSelect.value || '';

            // Limpia El Otro Select
            trufiSelect.value = '';
        } else {
            trufiWrap.classList.remove('d-none');
            taxiWrap.classList.add('d-none');

            refType.value = trufiClass;
            refId.value   = trufiSelect.value || '';

            taxiSelect.value = '';
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
            alert('Debes Seleccionar Un RadioTaxi O Un Trufi Antes De Guardar.');
        }
    });

    sync();
})();
</script>
@endsection