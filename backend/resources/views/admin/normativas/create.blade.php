@extends('admin.layout')

@section('title', 'Crear Normativa')

@section('content')

<div class="ct-header mb-4">
    <h2 class="ct-title">Crear Normativa</h2>
    <div class="ct-subtitle">
        Registro De Nueva Normativa En PDF
    </div>
</div>

<div class="card ct-stat-card">
    <div class="card-body">

        <form action="{{ route('admin.normativas.store') }}"
              method="POST"
              enctype="multipart/form-data">
            @csrf

            <div class="row">

                <div class="col-md-6 mb-3">
                    <label class="form-label fw-semibold">Título *</label>
                    <input type="text"
                           name="titulo"
                           class="form-control"
                           required
                           value="{{ old('titulo') }}">
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label fw-semibold">Categoría</label>
                    <input type="text"
                           name="categoria"
                           class="form-control"
                           value="{{ old('categoria') }}">
                </div>

                <div class="col-md-4 mb-3">
                    <label class="form-label fw-semibold">Versión</label>
                    <input type="text"
                           name="version"
                           class="form-control"
                           value="{{ old('version') }}">
                </div>

                <div class="col-md-4 mb-3">
                    <label class="form-label fw-semibold">Fecha De Publicación</label>
                    <input type="date"
                           name="fecha_publicacion"
                           class="form-control"
                           value="{{ old('fecha_publicacion') }}">
                </div>

                <div class="col-md-4 mb-3 d-flex align-items-center">
                    <div class="form-check mt-4">
                        <input class="form-check-input"
                               type="checkbox"
                               name="activo"
                               value="1"
                               checked>
                        <label class="form-check-label">
                            Activo
                        </label>
                    </div>
                </div>

                {{-- FilePond --}}
                <div class="col-12 mb-4">
                    <label class="form-label fw-semibold">Archivo PDF *</label>
                    <input type="file"
                           name="pdf"
                           id="pdf"
                           required>
                </div>

            </div>

            <div class="d-flex gap-2 mt-3">
                <button type="submit" class="btn ct-btn ct-btn-save">
                    Guardar
                </button>

                <a href="{{ route('admin.normativas.index') }}"
                   class="btn ct-btn ct-btn-back">
                    Volver
                </a>
            </div>

        </form>

    </div>
</div>

<script>
    FilePond.registerPlugin(
        FilePondPluginFileValidateType,
        FilePondPluginFileValidateSize
    );

    FilePond.create(document.querySelector('#pdf'), {
        acceptedFileTypes: ['application/pdf'],
        maxFileSize: '50MB',
        labelIdle: 'Arrastra El PDF O <span class="filepond--label-action">Selecciona</span>',

        // ✅ CLAVE: Envía El Archivo Dentro Del Form (No Subida Asíncrona)
        storeAsFile: true
    });
</script>

@endsection
