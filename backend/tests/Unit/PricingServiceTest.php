<?php

namespace Tests\Unit;

use App\Services\PricingService;
use Carbon\Carbon;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

class PricingServiceTest extends TestCase
{
    // Jede Zeile: Minuten, Stundenpreis, Gratis-Minuten, Tagesmaximum, erwarteter Preis.
    public static function cases(): array
    {
        return [
            'gratis in den ersten 15 Minuten' => [10, 300, 15, null, 0],
            'eine angefangene Stunde'         => [16, 300, 15, null, 300],
            'genau zwei Stunden'              => [120, 300, 0, null, 600],
            'zwei Stunden und eine Minute'    => [121, 300, 0, null, 900],
            'Tagesmaximum greift'             => [600, 300, 0, 2400, 2400],
            'ein Tag und eine Stunde'         => [25 * 60, 300, 0, 2400, 2700],
        ];
    }

    #[DataProvider('cases')]
    public function test_price(int $minutes, int $rate, int $free, ?int $cap, int $expected): void
    {
        $start = Carbon::parse('2026-01-01 08:00:00');
        $end = $start->copy()->addMinutes($minutes);

        $this->assertSame($expected, (new PricingService())->calculate($start, $end, $rate, $free, $cap));
    }
}
