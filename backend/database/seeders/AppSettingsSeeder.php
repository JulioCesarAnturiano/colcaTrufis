<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AppSettingsSeeder extends Seeder
{
    public function run(): void
    {
        $items = [
            ['key' => 'reclamos_phone_1', 'value' => '+591 00000000', 'group' => 'reclamos', 'activo' => true],
            ['key' => 'reclamos_phone_2', 'value' => '',             'group' => 'reclamos', 'activo' => true],
            ['key' => 'reclamos_whatsapp', 'value' => '+591 00000000', 'group' => 'reclamos', 'activo' => true],
        ];

        foreach ($items as $it) {
            DB::table('app_settings')->updateOrInsert(
                ['key' => $it['key']],
                $it + ['updated_at' => now(), 'created_at' => now()]
            );
        }
    }
}
