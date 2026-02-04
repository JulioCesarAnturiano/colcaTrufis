<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Admin')</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">

    {{-- Bootstrap Icons --}}
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">

    {{-- Estilo Global Del Panel --}}
    <link rel="stylesheet" href="{{ asset('css/colcatrufis-admin.css') }}">

    @stack('styles')
</head>
<body class="ct-body">

<nav class="navbar navbar-expand-lg navbar-dark ct-navbar">
    <div class="container">

        {{-- Marca --}}
        <a class="navbar-brand ct-brand me-3" href="{{ route('admin.dashboard') }}">
            ColcaTrufis Admin
        </a>

        {{-- Botón Home --}}
        <a href="{{ route('admin.dashboard') }}"
           class="btn btn-sm btn-light me-auto ct-btn-home"
           title="Ir al Dashboard">
            <i class="bi bi-house-fill"></i>
        </a>

        <div class="navbar-nav ms-auto d-flex align-items-center">
            @auth
                <span class="navbar-text text-light me-3">
                    {{ auth()->user()->name }}
                    <span class="text-white-50">
                        ({{ auth()->user()->getRoleNames()->join(', ') ?: 'Sin rol' }})
                    </span>
                </span>

                <form action="{{ route('admin.logout') }}" method="POST" class="mb-0">
                    @csrf
                    <button type="submit" class="btn btn-outline-light btn-sm">
                        Salir
                    </button>
                </form>
            @endauth
        </div>
    </div>
</nav>

<div class="container ct-container mt-4">

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

    @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show">
            <ul class="mb-0">
                @foreach ($errors->all() as $e)
                    <li>{{ $e }}</li>
                @endforeach
            </ul>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    @endif

    @yield('content')
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

@stack('scripts')
</body>
</html>
