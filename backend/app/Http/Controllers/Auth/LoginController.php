<?php

namespace App\Http\Controllers\Auth; // <-- DEBE decir esto EXACTAMENTE

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LoginController extends Controller
{
    // Mostrar formulario
    public function mostrarFormulario()
    {
        return view('auth.login');
    }
    
    // Procesar login
    public function autenticar(Request $request)
    {
        // Validar
        $credenciales = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);
        
        // Intentar autenticar
        if (Auth::attempt($credenciales)) {
            $request->session()->regenerate();
            
            // Verificar rol
            $usuario = Auth::user();
            if (!in_array($usuario->rol, ['admin', 'encargado'])) {
                Auth::logout();
                return back()->with('error', 'No tienes acceso al panel admin');
            }
            
            return redirect()->intended('/admin/dashboard');
        }
        
        return back()->withErrors([
            'email' => 'Las credenciales no son correctas.',
        ])->onlyInput('email');
    }
    
    // Cerrar sesión
    public function cerrarSesion(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        
        return redirect('/admin/login');
    }
}