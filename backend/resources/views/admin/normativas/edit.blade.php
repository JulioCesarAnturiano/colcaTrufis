@extends('admin.layout')

@section('title', 'Editar Normativa')

@section('content')

<div class="ct-header mb-4">
    <h2 class="ct-title">Editar Normativa</h2>
    <div class="ct-subtitle">
        Actualización De Normativa Existente
    </div>
</div>

<div class="card ct-stat-card">
    <div class="card-body">

        <form action="{{ route('admin.normativas.update', $item->id) }}"
              method="POST"
              enctype="multipart/form-data">
            @csrf
            @method('PUT')

            <div class="row">

                <div class="col-md-6 mb-3">
                    <label class="form-label fw-semibold">Título *</label>
                    <input type="text"
                           name="titulo"
                           class="form-control"
                           required
                           value="{{ old('titulo', $item->titulo) }}">
                </div>

                <div class="col-md-6 mb-3">
                    <label class="form-label fw-semibold">Categoría</label>
                    <input type="text"
                           name="categoria"
                           class="form-control"
                           value="{{ old('categoria', $item->categoria) }}">
                </div>

                <div class="col-md-4 mb-3">
                    <label class="form-label fw-semibold">Versión</label>
                    <input type="text"
                           name="version"
                           class="form-control"
                           value="{{ old('version', $item->version) }}">
                </div>

                <div class="col-md-4 mb-3">
                    <label class="form-label fw-semibold">Fecha De Publicación</label>
                    <input type="date"
                           name="fecha_publicacion"
                           class="form-control"
                           value="{{ old('fecha_publicacion', optional($item->fecha_publicacion)->format('Y-m-d')) }}">
                </div>

                <div class="col-md-4 mb-3 d-flex align-items-center">
                    <div class="form-check mt-4">
                        <input class="form-check-input"
                               type="checkbox"
                               name="activo"
                               value="1"
                               {{ $item->activo ? 'checked' : '' }}>
                        <label class="form-check-label">
                            Activo
                        </label>
                    </div>
                </div>

                {{-- Reemplazo PDF --}}
                <div class="col-12 mb-4">
                    <label class="form-label fw-semibold">
                        Reemplazar PDF (Opcional)
                    </label>
                    <input type="file"
                           name="pdf"
                           id="pdf">
                </div>

            </div>

            <div class="d-flex gap-2 mt-3">
                <button type="submit" class="btn ct-btn ct-btn-save">
                    Actualizar
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
        labelIdle: 'Arrastra El Nuevo PDF O <span class="filepond--label-action">Selecciona</span>',

        // ✅ CLAVE: Envía El Archivo Dentro Del Form (No Subida Asíncrona)
        storeAsFile: true
    });
</script>

@endsection
