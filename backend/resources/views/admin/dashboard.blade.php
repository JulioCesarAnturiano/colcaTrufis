<!DOCTYPE html>
<html>
<head>
    <title>Dashboard - Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>

    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container">
            <a class="navbar-brand" href="{{ route('admin.dashboard') }}">ColcaTrufis Admin</a>

            <div class="navbar-nav ms-auto d-flex align-items-center">
                <span class="navbar-text text-light me-3">
                    {{ $usuario->name }}
                    <span class="text-white-50">
                        ({{ $usuario->getRoleNames()->join(', ') ?: 'Sin rol' }})
                    </span>
                </span>

                <form action="{{ route('admin.logout') }}" method="POST" class="mb-0">
                    @csrf
                    <button type="submit" class="btn btn-outline-light btn-sm">Salir</button>
                </form>
            </div>
        </div>
    </nav>

    <div class="container mt-4">

        @if(session('success'))
            <div class="alert alert-success alert-dismissible fade show">
                {{ session('success') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        @endif

        @if(session('error'))
            <div class="alert alert-danger alert-dismissible fade show">
                {{ session('error') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        @endif

        <h2 class="mb-4">Dashboard</h2>

        {{-- Estadísticas --}}
        <div class="row">
            <div class="col-md-4 mb-3">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Total Trufis</h5>
                        <h2>{{ $stats['total_trufis'] }}</h2>
                    </div>
                </div>
            </div>

            <div class="col-md-4 mb-3">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Trufis Activos</h5>
                        <h2>{{ $stats['trufis_activos'] }}</h2>
                    </div>
                </div>
            </div>

            <div class="col-md-4 mb-3">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Total Rutas</h5>
                        <h2>{{ $stats['total_rutas'] }}</h2>
                    </div>
                </div>
            </div>
        </div>

        {{-- Acciones --}}
        <div class="mt-4">
            <h5 class="mb-3">Acciones</h5>

            {{-- TRUFIS --}}
            <div class="mb-3">
                <strong class="d-block mb-2">Trufis</strong>

                @can('admin.trufis.ver')
                    <a href="{{ route('admin.trufis.index') }}" class="btn btn-primary me-2">Ver Trufis</a>
                @endcan

                @can('admin.trufis.crear')
                    <a href="{{ route('admin.trufis.crear') }}" class="btn btn-success me-2">Crear Trufi</a>
                @endcan

                @cannot('admin.trufis.ver')
                    @cannot('admin.trufis.crear')
                        <span class="text-muted">No tienes permisos para Trufis.</span>
                    @endcannot
                @endcannot
            </div>

            {{-- RUTAS --}}
            <div class="mb-3">
                <strong class="d-block mb-2">Rutas</strong>

                @can('admin.rutas.ver')
                    <a href="{{ route('admin.rutas.index') }}" class="btn btn-secondary me-2">Ver Rutas</a>
                @endcan

                @can('admin.rutas.crear')
                    <a href="{{ route('admin.rutas.crear') }}" class="btn btn-success me-2">Crear Ruta</a>
                @endcan

                @cannot('admin.rutas.ver')
                    @cannot('admin.rutas.crear')
                        <span class="text-muted">No tienes permisos para Rutas.</span>
                    @endcannot
                @endcannot
            </div>

            {{-- USUARIOS --}}
            <div class="mb-3">
                <strong class="d-block mb-2">Usuarios</strong>

                @can('admin.usuarios.ver')
                    <a href="{{ route('admin.usuarios.index') }}" class="btn btn-warning me-2">Ver Usuarios</a>
                @endcan

                @can('admin.usuarios.crear')
                    <a href="{{ route('admin.usuarios.crear') }}" class="btn btn-success me-2">Crear Usuario</a>
                @endcan

                @cannot('admin.usuarios.ver')
                    @cannot('admin.usuarios.crear')
                        <span class="text-muted">No tienes permisos para Usuarios.</span>
                    @endcannot
                @endcannot
            </div>

            {{-- SINDICATOS --}}
            <div class="mb-3">
                <strong class="d-block mb-2">Sindicatos</strong>

                @can('admin.sindicatos.ver')
                    <a href="{{ route('admin.sindicatos.index') }}" class="btn btn-info me-2">Ver Sindicatos</a>
                @endcan

                @can('admin.sindicatos.crear')
                    <a href="{{ route('admin.sindicatos.crear') }}" class="btn btn-success me-2">Crear Sindicato</a>
                @endcan

                @cannot('admin.sindicatos.ver')
                    @cannot('admin.sindicatos.crear')
                        <span class="text-muted">No tienes permisos para Sindicatos.</span>
                    @endcannot
                @endcannot
            </div>

            {{-- RADIOTAXIS --}}
            <div class="mb-3">
                <strong class="d-block mb-2">RadioTaxis</strong>

                @can('admin.radiotaxis.ver')
                    <a href="{{ route('admin.radiotaxis.index') }}" class="btn btn-dark me-2">Ver RadioTaxis</a>
                @endcan

                @can('admin.radiotaxis.crear')
                    <a href="{{ route('admin.radiotaxis.crear') }}" class="btn btn-success me-2">Crear RadioTaxi</a>
                @endcan

                @cannot('admin.radiotaxis.ver')
                    @cannot('admin.radiotaxis.crear')
                        <span class="text-muted">No tienes permisos para RadioTaxis.</span>
                    @endcannot
                @endcannot
            </div>

        </div>

        <div class="mt-4">
            <div class="alert alert-info">
                <strong>Info:</strong>
                Encargado solo tendrá permisos de <strong>crear</strong>. Admin tendrá <strong>todas</strong> las opciones.
            </div>
        </div>

    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
