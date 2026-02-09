@extends('admin.layout')

@section('title', 'Dashboard - Admin')

@section('content')

    {{-- Título --}}
    <div class="ct-header mb-4">
        <h2 class="ct-title">Panel Administrativo ColcaTrufis</h2>
        <div class="ct-subtitle">
            Gestión General Del Sistema
        </div>
    </div>

    {{-- Estadísticas --}}
    <div class="row mb-4">
        <div class="col-md-4 mb-3">
            <div class="card ct-stat-card">
                <div class="card-body">
                    <h6 class="text-muted">Total Trufis</h6>
                    <h2>{{ $stats['total_trufis'] }}</h2>
                </div>
            </div>
        </div>

        <div class="col-md-4 mb-3">
            <div class="card ct-stat-card">
                <div class="card-body">
                    <h6 class="text-muted">Trufis Activos</h6>
                    <h2>{{ $stats['trufis_activos'] }}</h2>
                </div>
            </div>
        </div>

        <div class="col-md-4 mb-3">
            <div class="card ct-stat-card">
                <div class="card-body">
                    <h6 class="text-muted">Total Rutas</h6>
                    <h2>{{ $stats['total_rutas'] }}</h2>
                </div>
            </div>
        </div>
    </div>

    {{-- ACCIONES --}}
    <div class="row g-4">

        {{-- CONTENEDOR 1: TRUFIS + SINDICATOS (TRUFIS) + RUTAS --}}
        <div class="col-12 col-md-4">
            <div class="card ct-stat-card h-100">
                <div class="card-body">

                    <h5 class="mb-3 text-center">Trufis Y Rutas</h5>

                    {{-- TRUFIS --}}
                    <div class="mb-3">
                        <div class="fw-semibold mb-2">Trufis</div>

                        @can('admin.trufis.crear')
                            <a href="{{ route('admin.trufis.crear') }}" class="btn ct-btn ct-btn-create w-100 mb-2">
                                Crear Trufi
                            </a>
                        @endcan

                        @can('admin.trufis.ver')
                            <a href="{{ route('admin.trufis.index') }}" class="btn ct-btn ct-btn-view w-100">
                                Ver Trufis
                            </a>
                        @endcan
                    </div>

                    <hr>

                    {{-- SINDICATOS (TRUFIS) --}}
                    <div class="mb-3">
                        <div class="fw-semibold mb-2">Sindicatos (Trufis)</div>

                        @can('admin.sindicatos.crear')
                            <a href="{{ route('admin.sindicatos.crear') }}" class="btn ct-btn ct-btn-create w-100 mb-2">
                                Crear Sindicato
                            </a>
                        @endcan

                        @can('admin.sindicatos.ver')
                            <a href="{{ route('admin.sindicatos.index') }}" class="btn ct-btn ct-btn-view w-100">
                                Ver Sindicatos
                            </a>
                        @endcan
                    </div>

                    <hr>

                    {{-- RUTAS --}}
                    <div>
                        <div class="fw-semibold mb-2">Rutas</div>

                        @can('admin.rutas.crear')
                            <a href="{{ route('admin.rutas.crear') }}" class="btn ct-btn ct-btn-create w-100 mb-2">
                                Crear Ruta
                            </a>
                        @endcan

                        @can('admin.rutas.ver')
                            <a href="{{ route('admin.rutas.index') }}" class="btn ct-btn ct-btn-view w-100">
                                Ver Rutas
                            </a>
                        @endcan
                    </div>

                </div>
            </div>
        </div>

        {{-- CONTENEDOR 2: RADIOTAXIS + NORMATIVAS --}}
        <div class="col-12 col-md-4">
            <div class="card ct-stat-card h-100">
                <div class="card-body">

                    <h5 class="mb-3 text-center">RadioTaxis Y Normativas</h5>

                    {{-- RADIOTAXIS --}}
                    <div class="mb-3">
                        <div class="fw-semibold mb-2">RadioTaxis</div>

                        @can('admin.radiotaxis.crear')
                            <a href="{{ route('admin.radiotaxis.crear') }}" class="btn ct-btn ct-btn-create w-100 mb-2">
                                Crear RadioTaxi
                            </a>
                        @endcan

                        @can('admin.radiotaxis.ver')
                            <a href="{{ route('admin.radiotaxis.index') }}" class="btn ct-btn ct-btn-view w-100">
                                Ver RadioTaxis
                            </a>
                        @endcan
                    </div>

                    <hr>

                    {{-- NORMATIVAS --}}
                    <div>
                        <div class="fw-semibold mb-2">Normativas</div>

                        @can('admin.normativas.crear')
                            <a href="{{ route('admin.normativas.crear') }}" class="btn ct-btn ct-btn-create w-100 mb-2">
                                Crear Normativa
                            </a>
                        @endcan

                        @can('admin.normativas.ver')
                            <a href="{{ route('admin.normativas.index') }}" class="btn ct-btn ct-btn-view w-100">
                                Ver Normativas
                            </a>
                        @endcan
                    </div>

                </div>
            </div>
        </div>

        {{-- CONTENEDOR 3: USUARIOS --}}
        <div class="col-12 col-md-4">
            <div class="card ct-stat-card h-100">
                <div class="card-body">

                    <h5 class="mb-3 text-center">Usuarios</h5>

                    @can('admin.usuarios.crear')
                        <a href="{{ route('admin.usuarios.crear') }}" class="btn ct-btn ct-btn-create w-100 mb-2">
                            Crear Usuario
                        </a>
                    @endcan

                    @can('admin.usuarios.ver')
                        <a href="{{ route('admin.usuarios.index') }}" class="btn ct-btn ct-btn-view w-100">
                            Ver Usuarios
                        </a>
                    @endcan

                </div>
            </div>
        </div>

    </div>

@endsection
