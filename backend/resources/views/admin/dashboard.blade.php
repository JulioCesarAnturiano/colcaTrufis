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
            <div class="navbar-nav ms-auto">
                <span class="navbar-text text-light me-3">
                    {{ $usuario->name }} ({{ $usuario->rol }})
                </span>
                <form action="{{ route('admin.logout') }}" method="POST">
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
        
        <h2 class="mb-4">Dashboard</h2>
        
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
        
        <div class="mt-4">
            <a href="{{ route('admin.trufis.index') }}" class="btn btn-primary me-2">Ver Trufis</a>
            <a href="{{ route('admin.rutas.index') }}" class="btn btn-secondary">Ver Rutas</a>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>