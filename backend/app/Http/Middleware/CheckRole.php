<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckRole
{
    public function handle(Request $request, Closure $next, $role)
    {
        $user = $request->user();
        
        if (!$user) {
            return redirect()->route('login');
        }
        
        // Si se pasan múltiples roles separados por |
        if (str_contains($role, '|')) {
            $roles = explode('|', $role);
            if (!in_array($user->rol, $roles)) {
                abort(403, 'Acceso no autorizado');
            }
        } else {
            if ($user->rol !== $role) {
                abort(403, 'Acceso no autorizado');
            }
        }
        
        return $next($request);
    }
}