<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BrandingController;
use App\Http\Controllers\Api\ParkingLotController;
use App\Http\Controllers\Api\ParkingSessionController;
use App\Http\Middleware\EnsureUserBelongsToTenant;
use App\Http\Middleware\ResolveTenant;
use Illuminate\Support\Facades\Route;

// Alle Routen brauchen einen Tenant.
Route::middleware(ResolveTenant::class)->group(function () {
    // Öffentlich: Branding, Parkplätze und Login.
    Route::get('/branding', BrandingController::class);
    Route::get('/lots', [ParkingLotController::class, 'index']);
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

    // Mit Login (Laravel Sanctum). Danach prüfen wir den Tenant vom Benutzer.
    // Wichtig: Wir benutzen {id} statt Route-Model-Binding. So läuft die Suche
    // erst NACH ResolveTenant, und der Tenant-Filter ist sicher aktiv.
    Route::middleware(['auth:sanctum', EnsureUserBelongsToTenant::class])->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::post('/lots', [ParkingLotController::class, 'store']);
        Route::get('/sessions/active', [ParkingSessionController::class, 'active']);
        Route::post('/sessions', [ParkingSessionController::class, 'start']);
        Route::post('/sessions/{id}/stop', [ParkingSessionController::class, 'stop'])->whereNumber('id');
        Route::get('/sessions/{id}/quote', [ParkingSessionController::class, 'quote'])->whereNumber('id');
    });
});
