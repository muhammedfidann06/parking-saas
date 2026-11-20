<?php

namespace Tests\Feature;

use App\Models\ParkingLot;
use App\Models\Tenant;
use App\Models\User;
use App\Tenancy\TenantContext;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

// Der ganze Ablauf: Login -> Parken -> Beenden -> Preis.
class ParkingFlowTest extends TestCase
{
    use RefreshDatabase;

    private function setUpTenant(string $slug): array
    {
        $tenant = Tenant::create(['name' => strtoupper($slug), 'slug' => $slug]);
        app(TenantContext::class)->set($tenant);
        $user = User::create([
            'tenant_id' => $tenant->id, 'name' => 'Test', 'email' => "user@{$slug}.test",
            'password' => Hash::make('secret123'), 'role' => 'driver',
        ]);
        $lot = ParkingLot::create(['name' => 'Zentrum', 'capacity' => 1, 'hourly_rate_cents' => 200]);

        return [$tenant, $user, $lot];
    }

    public function test_login_returns_token(): void
    {
        $this->setUpTenant('linz');

        $this->postJson('/api/login', ['email' => 'user@linz.test', 'password' => 'secret123'], ['X-Tenant' => 'linz'])
            ->assertOk()
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'role']]);
    }

    public function test_login_with_wrong_password_fails(): void
    {
        $this->setUpTenant('linz');

        $this->postJson('/api/login', ['email' => 'user@linz.test', 'password' => 'falsch'], ['X-Tenant' => 'linz'])
            ->assertStatus(422);
    }

    public function test_user_cannot_login_into_other_tenant(): void
    {
        $this->setUpTenant('linz');
        $this->setUpTenant('wels');

        $this->postJson('/api/login', ['email' => 'user@linz.test', 'password' => 'secret123'], ['X-Tenant' => 'wels'])
            ->assertStatus(422);
    }

    public function test_full_parking_flow_and_full_lot(): void
    {
        [, $user, $lot] = $this->setUpTenant('linz');
        $headers = ['X-Tenant' => 'linz'];
        $this->actingAs($user, 'sanctum');

        $id = $this->postJson('/api/sessions', ['parking_lot_id' => $lot->id, 'license_plate' => 'l 123 ab'], $headers)
            ->assertCreated()
            ->assertJsonPath('license_plate', 'L123AB')
            ->json('id');

        // Der Parkplatz hat nur 1 Platz -> jetzt ist er voll.
        $this->postJson('/api/sessions', ['parking_lot_id' => $lot->id, 'license_plate' => 'W 9 XY'], $headers)
            ->assertStatus(409);

        $this->getJson('/api/sessions/active', $headers)->assertOk()->assertJsonCount(1);

        // Wir "reisen" 30 Minuten in die Zukunft.
        $this->travel(30)->minutes();

        $this->postJson("/api/sessions/{$id}/stop", [], $headers)
            ->assertOk()
            ->assertJsonPath('amount_cents', 200); // eine angefangene Stunde
    }
}
