@extends('admin.layout')

@section('title', 'Dashboard - Admin')

@section('content')

{{-- ═══════════════════════════════════════════════════
     BREADCRUMB
═══════════════════════════════════════════════════ --}}
<nav class="ct-breadcrumb mb-3">
    <i class="bi bi-house-fill" style="color:var(--brand-aqua)"></i>
    <span class="ct-breadcrumb-sep">/</span>
    <span style="color:var(--text-muted)">Panel Administrativo</span>
</nav>

{{-- ═══════════════════════════════════════════════════
     HEADER DE PÁGINA
═══════════════════════════════════════════════════ --}}
<div class="ct-header mb-4 d-flex align-items-center justify-content-between flex-wrap gap-3">
    <div>
        <h2 class="ct-title d-flex align-items-center gap-2">
            <span class="ct-header-icon">
                <i class="bi bi-speedometer2"></i>
            </span>
            Panel Administrativo
        </h2>
        <div class="ct-subtitle">
            ColcaTrufis &mdash; Gestión general del sistema
        </div>
    </div>
    <div class="d-flex align-items-center gap-2">
        <span class="ct-badge ct-badge-aqua">
            <i class="bi bi-circle-fill" style="font-size:7px"></i>
            Sistema activo
        </span>
        <span class="ct-badge ct-badge-muted">
            <i class="bi bi-calendar3"></i>
            {{ now()->format('d M Y') }}
        </span>
    </div>
</div>

{{-- ═══════════════════════════════════════════════════
     ESTADÍSTICAS
═══════════════════════════════════════════════════ --}}
<div class="row g-3 mb-4">

    <div class="col-6 col-md-4">
        <div class="ct-stat-card">
            <div class="card-body p-3 d-flex align-items-center gap-3">
                <div class="ct-stat-icon" style="background:var(--brand-teal-bg); color:var(--brand-primary)">
                    <i class="bi bi-bus-front-fill fs-5"></i>
                </div>
                <div>
                    <div class="ct-stat-label">Total Trufis</div>
                    <div class="ct-stat-value">{{ $stats['total_trufis'] }}</div>
                </div>
            </div>
            <div class="ct-stat-footer">
                <i class="bi bi-arrow-up-short text-success"></i>
                <span>Registrados en el sistema</span>
            </div>
        </div>
    </div>

    <div class="col-6 col-md-4">
        <div class="ct-stat-card">
            <div class="card-body p-3 d-flex align-items-center gap-3">
                <div class="ct-stat-icon" style="background:rgba(25,183,176,0.12); color:var(--brand-aqua)">
                    <i class="bi bi-check-circle-fill fs-5"></i>
                </div>
                <div>
                    <div class="ct-stat-label">Trufis Activos</div>
                    <div class="ct-stat-value">{{ $stats['trufis_activos'] }}</div>
                </div>
            </div>
            <div class="ct-stat-footer">
                <i class="bi bi-activity text-success"></i>
                <span>En circulación ahora</span>
            </div>
        </div>
    </div>

    <div class="col-12 col-md-4">
        <div class="ct-stat-card">
            <div class="card-body p-3 d-flex align-items-center gap-3">
                <div class="ct-stat-icon" style="background:rgba(6,70,86,0.08); color:var(--brand-dark)">
                    <i class="bi bi-map-fill fs-5"></i>
                </div>
                <div>
                    <div class="ct-stat-label">Total Rutas</div>
                    <div class="ct-stat-value">{{ $stats['total_rutas'] }}</div>
                </div>
            </div>
            <div class="ct-stat-footer">
                <i class="bi bi-geo-alt text-primary"></i>
                <span>Rutas mapeadas</span>
            </div>
        </div>
    </div>

</div>

{{-- ═══════════════════════════════════════════════════
     TÍTULO DE SECCIÓN ACCIONES
═══════════════════════════════════════════════════ --}}
<div class="d-flex align-items-center gap-2 mb-3">
    <div class="ct-section-rule"></div>
    <span class="ct-section-title mb-0">Gestión del Sistema</span>
    <div class="ct-section-rule"></div>
</div>

{{-- ═══════════════════════════════════════════════════
     TARJETAS DE ACCIÓN
═══════════════════════════════════════════════════ --}}
<div class="row g-4">

    {{-- ─── COLUMNA 1: TRUFIS / SINDICATOS / RUTAS ─── --}}
    <div class="col-12 col-lg-4">
        <div class="ct-action-card h-100">

            {{-- Header --}}
            <div class="ct-action-header ct-action-header--trufis">
                <div class="ct-action-header-icon">
                    <i class="bi bi-bus-front-fill"></i>
                </div>
                <div>
                    <div class="ct-action-header-title">Trufis &amp; Rutas</div>
                    <div class="ct-action-header-sub">Gestión de líneas y recorridos</div>
                </div>
            </div>

            <div class="ct-action-card-body">

                {{-- TRUFIS --}}
                <div class="ct-action-section">
                    <div class="ct-action-section-label">
                        <i class="bi bi-bus-front"></i>
                        Trufis
                    </div>
                    <div class="d-flex gap-2">
                        @can('admin.trufis.crear')
                            <a href="{{ route('admin.trufis.crear') }}"
                               class="btn ct-btn ct-btn-create flex-fill">
                                <i class="bi bi-plus-lg"></i> Crear
                            </a>
                        @endcan
                        @can('admin.trufis.ver')
                            <a href="{{ route('admin.trufis.index') }}"
                               class="btn ct-btn ct-btn-view flex-fill">
                                <i class="bi bi-list-ul"></i> Ver
                            </a>
                        @endcan
                    </div>
                </div>

                <div class="ct-action-divider"></div>

                {{-- SINDICATOS --}}
                <div class="ct-action-section">
                    <div class="ct-action-section-label">
                        <i class="bi bi-people-fill"></i>
                        Sindicatos
                    </div>
                    <div class="d-flex gap-2">
                        @can('admin.sindicatos.crear')
                            <a href="{{ route('admin.sindicatos.crear') }}"
                               class="btn ct-btn ct-btn-create flex-fill">
                                <i class="bi bi-plus-lg"></i> Crear
                            </a>
                        @endcan
                        @can('admin.sindicatos.ver')
                            <a href="{{ route('admin.sindicatos.index') }}"
                               class="btn ct-btn ct-btn-view flex-fill">
                                <i class="bi bi-list-ul"></i> Ver
                            </a>
                        @endcan
                    </div>
                </div>

                <div class="ct-action-divider"></div>

                {{-- RUTAS --}}
                <div class="ct-action-section">
                    <div class="ct-action-section-label">
                        <i class="bi bi-map"></i>
                        Rutas
                    </div>
                    <div class="d-flex gap-2">
                        @can('admin.rutas.crear')
                            <a href="{{ route('admin.rutas.crear') }}"
                               class="btn ct-btn ct-btn-create flex-fill">
                                <i class="bi bi-plus-lg"></i> Crear
                            </a>
                        @endcan
                        @can('admin.rutas.ver')
                            <a href="{{ route('admin.rutas.index') }}"
                               class="btn ct-btn ct-btn-view flex-fill">
                                <i class="bi bi-list-ul"></i> Ver
                            </a>
                        @endcan
                    </div>
                </div>

            </div>
        </div>
    </div>

    {{-- ─── COLUMNA 2: RADIOTAXIS / NORMATIVAS ─── --}}
    <div class="col-12 col-lg-4">
        <div class="ct-action-card h-100">

            <div class="ct-action-header ct-action-header--radiotaxis">
                <div class="ct-action-header-icon">
                    <i class="bi bi-taxi-front-fill"></i>
                </div>
                <div>
                    <div class="ct-action-header-title">RadioTaxis &amp; Normativas</div>
                    <div class="ct-action-header-sub">Gestión de taxis y reglamentos</div>
                </div>
            </div>

            <div class="ct-action-card-body">

                {{-- RADIOTAXIS --}}
                <div class="ct-action-section">
                    <div class="ct-action-section-label">
                        <i class="bi bi-taxi-front"></i>
                        RadioTaxis
                    </div>
                    <div class="d-flex gap-2">
                        @can('admin.radiotaxis.crear')
                            <a href="{{ route('admin.radiotaxis.crear') }}"
                               class="btn ct-btn ct-btn-create flex-fill">
                                <i class="bi bi-plus-lg"></i> Crear
                            </a>
                        @endcan
                        @can('admin.radiotaxis.ver')
                            <a href="{{ route('admin.radiotaxis.index') }}"
                               class="btn ct-btn ct-btn-view flex-fill">
                                <i class="bi bi-list-ul"></i> Ver
                            </a>
                        @endcan
                    </div>
                </div>

                <div class="ct-action-divider"></div>

                {{-- NORMATIVAS --}}
                <div class="ct-action-section">
                    <div class="ct-action-section-label">
                        <i class="bi bi-file-earmark-text-fill"></i>
                        Normativas
                    </div>
                    <div class="d-flex gap-2">
                        @can('admin.normativas.crear')
                            <a href="{{ route('admin.normativas.crear') }}"
                               class="btn ct-btn ct-btn-create flex-fill">
                                <i class="bi bi-plus-lg"></i> Crear
                            </a>
                        @endcan
                        @can('admin.normativas.ver')
                            <a href="{{ route('admin.normativas.index') }}"
                               class="btn ct-btn ct-btn-view flex-fill">
                                <i class="bi bi-list-ul"></i> Ver
                            </a>
                        @endcan
                    </div>
                </div>

            </div>
        </div>
    </div>

    {{-- ─── COLUMNA 3: USUARIOS / REPORTES / CONFIG ─── --}}
    <div class="col-12 col-lg-4">
        <div class="ct-action-card h-100">

            <div class="ct-action-header ct-action-header--usuarios">
                <div class="ct-action-header-icon">
                    <i class="bi bi-person-fill-gear"></i>
                </div>
                <div>
                    <div class="ct-action-header-title">Usuarios &amp; Sistema</div>
                    <div class="ct-action-header-sub">Acceso, reportes y configuración</div>
                </div>
            </div>

            <div class="ct-action-card-body">

                {{-- USUARIOS --}}
                <div class="ct-action-section">
                    <div class="ct-action-section-label">
                        <i class="bi bi-person-fill"></i>
                        Usuarios
                    </div>
                    <div class="d-flex gap-2">
                        @can('admin.usuarios.crear')
                            <a href="{{ route('admin.usuarios.crear') }}"
                               class="btn ct-btn ct-btn-create flex-fill">
                                <i class="bi bi-plus-lg"></i> Crear
                            </a>
                        @endcan
                        @can('admin.usuarios.ver')
                            <a href="{{ route('admin.usuarios.index') }}"
                               class="btn ct-btn ct-btn-view flex-fill">
                                <i class="bi bi-list-ul"></i> Ver
                            </a>
                        @endcan
                    </div>
                </div>

                <div class="ct-action-divider"></div>

                {{-- REPORTES --}}
                @can('admin.reportes.ver')
                <div class="ct-action-section">
                    <div class="ct-action-section-label">
                        <i class="bi bi-bar-chart-fill"></i>
                        Reportes
                    </div>
                    <a href="{{ route('admin.reportes.trufis_mas_seleccionados') }}"
                       class="btn ct-btn ct-btn-view w-100">
                        <i class="bi bi-graph-up-arrow"></i>
                        Ver Reportes
                    </a>
                </div>
                <div class="ct-action-divider"></div>
                @endcan

                {{-- CONFIGURACIÓN --}}
                @can('admin.settings.ver')
                <div class="ct-action-section">
                    <div class="ct-action-section-label">
                        <i class="bi bi-gear-fill"></i>
                        Configuración
                    </div>
                    <a href="{{ route('admin.settings.reclamos.edit') }}"
                       class="btn ct-btn ct-btn-back w-100">
                        <i class="bi bi-telephone-fill"></i>
                        Números de Reclamos
                    </a>
                </div>
                @endcan

            </div>
        </div>
    </div>

</div>

{{-- ═══════════════════════════════════════════════════
     ESTILOS ESPECÍFICOS DEL DASHBOARD
═══════════════════════════════════════════════════ --}}
<style>
/* Icono del header de página */
.ct-header-icon {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 38px;
    height: 38px;
    border-radius: 10px;
    background: linear-gradient(135deg, var(--brand-dark), var(--brand-primary));
    color: #fff;
    font-size: 1.1rem;
    flex-shrink: 0;
}

/* Footer de stat card */
.ct-stat-footer {
    padding: 7px 14px 10px;
    font-size: 0.75rem;
    font-weight: 500;
    color: var(--text-muted);
    border-top: 1px solid var(--border);
    display: flex;
    align-items: center;
    gap: 4px;
}

/* Línea decorativa de sección */
.ct-section-rule {
    flex: 1;
    height: 1px;
    background: var(--border);
}

/* ── ACTION CARD REDISEÑADO ── */
.ct-action-card {
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-sm);
    overflow: hidden;
    background: var(--surface);
    transition: transform 0.2s ease, box-shadow 0.2s ease;
    display: flex;
    flex-direction: column;
}

.ct-action-card:hover {
    transform: translateY(-3px);
    box-shadow: var(--shadow-lg);
}

/* Header de la action card */
.ct-action-header {
    padding: 18px 20px;
    display: flex;
    align-items: center;
    gap: 14px;
    border-bottom: 1px solid rgba(255,255,255,0.10);
}

.ct-action-header--trufis {
    background: linear-gradient(135deg, var(--brand-dark) 0%, var(--brand-primary) 100%);
}

.ct-action-header--radiotaxis {
    background: linear-gradient(135deg, var(--brand-primary) 0%, var(--brand-aqua) 100%);
}

.ct-action-header--usuarios {
    background: linear-gradient(135deg, #032e3a 0%, var(--brand-dark) 100%);
}

.ct-action-header-icon {
    width: 44px;
    height: 44px;
    border-radius: 12px;
    background: rgba(255,255,255,0.15);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.3rem;
    color: #fff;
    flex-shrink: 0;
    border: 1px solid rgba(255,255,255,0.18);
}

.ct-action-header-title {
    font-size: 0.95rem;
    font-weight: 800;
    color: #fff;
    letter-spacing: 0.1px;
    line-height: 1.2;
}

.ct-action-header-sub {
    font-size: 0.75rem;
    font-weight: 500;
    color: rgba(255,255,255,0.70);
    margin-top: 2px;
}

/* Body de la action card — siempre visible (no hover) */
.ct-action-card-body {
    padding: 20px;
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 0;
}

/* Sección dentro del body */
.ct-action-section {
    padding: 4px 0 12px;
}

.ct-action-section:last-child {
    padding-bottom: 0;
}

.ct-action-section-label {
    font-size: 0.73rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.7px;
    color: var(--text-muted);
    margin-bottom: 10px;
    display: flex;
    align-items: center;
    gap: 6px;
}

.ct-action-section-label i {
    color: var(--brand-aqua);
    font-size: 0.85rem;
}

/* Divisor entre secciones */
.ct-action-divider {
    height: 1px;
    background: var(--border);
    margin: 10px 0 16px;
    opacity: 0.7;
}

/* Botones en par (flex-fill) */
.ct-btn.flex-fill {
    flex: 1;
    min-width: 0;
    justify-content: center;
}
</style>

@endsection
