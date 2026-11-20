<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ParkingLot;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ParkingLotController extends Controller
{
    // Liste aller Parkplätze vom aktuellen Tenant (der Global Scope filtert automatisch).
    public function index(): JsonResponse
    {
        $lots = ParkingLot::withCount(['sessions as occupied' => fn ($q) => $q->whereNull('ended_at')])
            ->orderBy('name')
            ->get()
            ->map(fn (ParkingLot $lot) => [
                'id' => $lot->id,
                'name' => $lot->name,
                'address' => $lot->address,
                'capacity' => $lot->capacity,
                'free' => max(0, $lot->capacity - $lot->occupied),
                'hourly_rate_cents' => $lot->hourly_rate_cents,
                'free_minutes' => $lot->free_minutes,
                'daily_cap_cents' => $lot->daily_cap_cents,
            ]);

        return response()->json($lots);
    }

    // Nur Operatoren und Admins dürfen neue Parkplätze anlegen.
    public function store(Request $request): JsonResponse
    {
        abort_unless(in_array($request->user()?->role, ['operator', 'admin'], true), 403);

        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'address' => ['nullable', 'string', 'max:255'],
            'capacity' => ['required', 'integer', 'min:1'],
            'hourly_rate_cents' => ['required', 'integer', 'min:0'],
            'free_minutes' => ['integer', 'min:0'],
            'daily_cap_cents' => ['nullable', 'integer', 'min:0'],
        ]);

        return response()->json(ParkingLot::create($data), 201);
    }
}
