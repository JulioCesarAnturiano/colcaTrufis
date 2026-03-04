<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class GeocodingService
{
    public function reverse(float $lat, float $lng): ?array
    {
        // Cache Para No Llamar Mil Veces Al Mismo Punto.
        $key = 'revgeo:' . round($lat, 5) . ':' . round($lng, 5);

        return Cache::remember($key, now()->addDays(7), function () use ($lat, $lng) {

            $res = Http::timeout(10)
                ->withHeaders([
                    // Nominatim Pide Un User-Agent Identificable.
                    'User-Agent' => config('app.name', 'ColcaTrufis') . '/1.0',
                    'Accept' => 'application/json',
                ])
                ->get('https://nominatim.openstreetmap.org/reverse', [
                    'format' => 'jsonv2',
                    'lat' => $lat,
                    'lon' => $lng,
                    'zoom' => 18,
                    'addressdetails' => 1,
                ]);

            if (!$res->ok()) return null;

            $data = $res->json();

            $addr = $data['address'] ?? [];

            // “Road” Es Lo Más Común, Pero A Veces Viene Con Otros Campos.
            $road =
                $addr['road'] ??
                $addr['pedestrian'] ??
                $addr['footway'] ??
                $addr['path'] ??
                $addr['cycleway'] ??
                $addr['street'] ??
                $addr['neighbourhood'] ??
                null;

            if (!$road) return null;

            return [
                'nombre_via' => $road,
                'tipo_via' => null,
                'meta' => $data,
            ];
        });
    }

    public function buildUbicacionesFromCoords(array $coords, int $sampleEvery = 10): array
    {
        $ubicaciones = [];
        $lastNombre = null;

        $total = count($coords);
        if ($total === 0) return [];

        for ($i = 0; $i < $total; $i++) {
            $isSample = ($i % $sampleEvery === 0) || ($i === $total - 1);
            if (!$isSample) continue;

            // GeoJSON: [lng, lat]
            $lng = (float) $coords[$i][0];
            $lat = (float) $coords[$i][1];

            $info = $this->reverse($lat, $lng);
            if (!$info) continue;

            $nombre = trim((string) $info['nombre_via']);
            if ($nombre === '') continue;

            // Quitar Repetidos Consecutivos.
            if ($lastNombre && mb_strtolower($lastNombre) === mb_strtolower($nombre)) {
                continue;
            }

            $ubicaciones[] = $info;
            $lastNombre = $nombre;

            // Pequeña Pausa Para Evitar Rate Limit En Rutas Largas.
            usleep(250000); // 0.25s
        }

        return $ubicaciones;
    }
}