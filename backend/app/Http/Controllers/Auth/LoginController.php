<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LoginController extends Controller
{
    public function mostrarFormulario()
    {
        return view('auth.login');
    }

    public function autenticar(Request $request)
    {
        $credenciales = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        // 1) Si email/contraseña son incorrectos
        if (!Auth::attempt($credenciales)) {
            return back()
                ->withInput($request->only('email'))
                ->with('error', 'Usuario no reconocido.');
        }

        // 2) Login OK
        $request->session()->regenerate();

        $usuario = Auth::user();

        // 3) Si no tiene rol permitido
        if (!$usuario->hasAnyRole(['admin', 'encargado'])) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return back()
                ->withInput($request->only('email'))
                ->with('error', 'Usuario no reconocido.');
        }

        return redirect()->intended('/admin/dashboard');
    }

    public function cerrarSesion(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/admin/login');
    }
}
