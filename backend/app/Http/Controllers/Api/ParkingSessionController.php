<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ParkingLot;
use App\Models\ParkingSession;
use App\Services\PricingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ParkingSessionController extends Controller
{
    public function __construct(private PricingService $pricing) {}

    // Aktive Parkzeiten vom eingeloggten Benutzer (für die Mobile-App).
    public function active(Request $request): JsonResponse
    {
        $sessions = ParkingSession::with('lot:id,name')
            ->where('user_id', $request->user()->id)
            ->whereNull('ended_at')
            ->latest('started_at')
            ->get();

        return response()->json($sessions);
    }

    // Parken starten (Check-in).
    public function start(Request $request): JsonResponse
    {
        $data = $request->validate([
            'parking_lot_id' => ['required', 'integer'],
            'license_plate' => ['required', 'string', 'max:16'],
        ]);
        // Kennzeichen immer gleich schreiben: groß und ohne Leerzeichen.
        $plate = strtoupper(preg_replace('/\s+/', '', $data['license_plate']));

        // Eine Transaktion mit Lock: Zwei Autos können nicht den letzten Platz gleichzeitig nehmen.
        return DB::transaction(function () use ($data, $plate, $request) {
            $lot = ParkingLot::lockForUpdate()->findOrFail($data['parking_lot_id']);

            if ($lot->freeSpots() === 0) {
                return response()->json(['message' => 'Der Parkplatz ist voll.'], 409);
            }
            $alreadyParked = ParkingSession::where('license_plate', $plate)->whereNull('ended_at')->exists();
            if ($alreadyParked) {
                return response()->json(['message' => 'Dieses Auto parkt schon.'], 409);
            }

            $session = $lot->sessions()->create([
                'user_id' => $request->user()?->id,
                'license_plate' => $plate,
                'started_at' => now(),
            ]);

            return response()->json($session, 201);
        });
    }

    // Parken beenden (Check-out) und Preis berechnen.
    public function stop(int $id): JsonResponse
    {
        // Der Global Scope findet nur Sessions vom aktuellen Tenant.
        $session = ParkingSession::findOrFail($id);
        if (! $session->isActive()) {
            return response()->json(['message' => 'Die Parkzeit ist schon beendet.'], 409);
        }

        $lot = $session->lot;
        $end = now();
        $session->update([
            'ended_at' => $end,
            'amount_cents' => $this->pricing->calculate(
                $session->started_at, $end,
                $lot->hourly_rate_cents, $lot->free_minutes, $lot->daily_cap_cents,
            ),
        ]);

        return response()->json($session->fresh());
    }

    // Preis-Vorschau: Was kostet es, wenn ich jetzt fahre?
    public function quote(int $id): JsonResponse
    {
        $session = ParkingSession::findOrFail($id);
        $lot = $session->lot;
        $amount = $this->pricing->calculate(
            $session->started_at, $session->ended_at ?? now(),
            $lot->hourly_rate_cents, $lot->free_minutes, $lot->daily_cap_cents,
        );

        return response()->json(['amount_cents' => $amount, 'currency' => $lot->tenant->currency]);
    }
}
