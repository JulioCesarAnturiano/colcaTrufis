<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminAccess
{
    public function handle(Request $request, Closure $next)
    {
        // Verificar si hay usuario autenticado
        if (!Auth::check()) {
            return redirect()->route('login');
        }
        
        // Verificar rol
        $usuario = Auth::user();
        if (!in_array($usuario->rol, ['admin', 'encargado'])) {
            Auth::logout();
            return redirect()->route('login')
                ->with('error', 'Acceso no autorizado al panel admin');
        }
        
        return $next($request);
    }
}