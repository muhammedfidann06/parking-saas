<?php

namespace App\Services;

use Carbon\CarbonInterface;

/**
 * Hier rechnen wir den Preis für eine Parkzeit aus.
 *
 * Regeln:
 *  - Die ersten "free_minutes" sind kostenlos.
 *  - Danach zahlt man pro angefangene Stunde.
 *  - Pro Tag (24 h) gibt es einen Maximalpreis (daily cap), wenn gesetzt.
 */
class PricingService
{
    public function calculate(
        CarbonInterface $start,
        CarbonInterface $end,
        int $hourlyRateCents,
        int $freeMinutes = 0,
        ?int $dailyCapCents = null,
    ): int {
        // Wir rechnen in Minuten (immer aufrunden).
        $minutes = (int) ceil($start->diffInSeconds($end) / 60);

        // Kurz geparkt? Dann ist es gratis.
        if ($minutes <= $freeMinutes) {
            return 0;
        }

        $fullDays = intdiv($minutes, 24 * 60);
        $restMinutes = $minutes % (24 * 60);

        // Preis für den Rest-Tag: angefangene Stunden mal Stundenpreis.
        $restCost = (int) ceil($restMinutes / 60) * $hourlyRateCents;
        $dayCost = 24 * $hourlyRateCents;

        if ($dailyCapCents !== null) {
            // Der Tagespreis ist nie höher als das Maximum.
            $restCost = min($restCost, $dailyCapCents);
            $dayCost = min($dayCost, $dailyCapCents);
        }

        return $fullDays * $dayCost + $restCost;
    }
}
