<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>Login - Panel Admin</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    {{-- Tu CSS global del panel --}}
    <link rel="stylesheet" href="{{ asset('css/colcatrufis-admin.css') }}">
</head>

<body class="ct-body">

    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-12 col-md-5 col-lg-4">

                <div class="card ct-stat-card shadow-sm overflow-hidden">

                    <div class="ct-login-header text-center">
                        <div class="ct-login-logo">ColcaTrufis</div>
                        <div class="ct-login-sub">Panel Administrativo</div>
                    </div>

                    <div class="card-body p-4">

                        @if(session('error'))
                            <div class="alert alert-danger alert-dismissible fade show">
                                {{ session('error') }}
                                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                            </div>
                        @endif

                        <form method="POST" action="{{ route('login.submit') }}">
                            @csrf

                            <div class="mb-3">
                                <label for="email" class="form-label fw-semibold">Correo Electrónico</label>
                                <input type="email" class="form-control" id="email" name="email" required>
                            </div>

                            <div class="mb-3">
                                <label for="password" class="form-label fw-semibold">Contraseña</label>
                                <input type="password" class="form-control" id="password" name="password" required>
                            </div>

                            <button type="submit" class="btn ct-btn ct-btn-view w-100">
                                Iniciar Sesión
                            </button>
                        </form>

                    </div>

                    <div class="card-footer text-center text-muted py-3">
                        <small>Solo Personal Autorizado</small>
                    </div>

                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
