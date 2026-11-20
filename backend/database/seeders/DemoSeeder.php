<?php

namespace Database\Seeders;

use App\Models\ParkingLot;
use App\Models\Tenant;
use App\Models\User;
use App\Tenancy\TenantContext;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

// Demo-Daten: zwei Kunden mit eigenen Farben und Parkplätzen.
class DemoSeeder extends Seeder
{
    public function run(): void
    {
        $tenants = [
            ['name' => 'Berlin Parking', 'slug' => 'berlin', 'primary_color' => '#dc2626'],
            ['name' => 'Wien Garagen', 'slug' => 'wien', 'primary_color' => '#059669'],
        ];

        foreach ($tenants as $data) {
            $tenant = Tenant::create($data);
            // Wir setzen den Tenant, damit die neuen Daten die richtige tenant_id bekommen.
            app(TenantContext::class)->set($tenant);

            User::create([
                'tenant_id' => $tenant->id,
                'name' => "Operator {$tenant->name}",
                'email' => "operator@{$tenant->slug}.test",
                'password' => Hash::make('password'), // Nur für lokale Demos!
                'role' => 'operator',
            ]);

            ParkingLot::create(['name' => 'Hauptbahnhof', 'capacity' => 120, 'hourly_rate_cents' => 300, 'free_minutes' => 15, 'daily_cap_cents' => 2400]);
            ParkingLot::create(['name' => 'Altstadt', 'capacity' => 40, 'hourly_rate_cents' => 450, 'free_minutes' => 0, 'daily_cap_cents' => null]);
        }
    }
}
