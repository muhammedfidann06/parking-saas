<?php

namespace Tests\Feature;

use App\Models\ParkingLot;
use App\Models\Tenant;
use App\Tenancy\TenantContext;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

// Der wichtigste Test: Kunde A darf die Daten von Kunde B nicht sehen.
class TenantIsolationTest extends TestCase
{
    use RefreshDatabase;

    public function test_each_tenant_sees_only_its_own_lots(): void
    {
        $a = Tenant::create(['name' => 'A', 'slug' => 'a']);
        $b = Tenant::create(['name' => 'B', 'slug' => 'b']);

        app(TenantContext::class)->set($a);
        ParkingLot::create(['name' => 'Lot A', 'capacity' => 10, 'hourly_rate_cents' => 100]);
        app(TenantContext::class)->set($b);
        ParkingLot::create(['name' => 'Lot B', 'capacity' => 10, 'hourly_rate_cents' => 100]);

        $this->getJson('/api/lots', ['X-Tenant' => 'a'])
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.name', 'Lot A');
    }

    public function test_unknown_tenant_returns_404(): void
    {
        $this->getJson('/api/lots', ['X-Tenant' => 'gibt-es-nicht'])->assertNotFound();
    }
}
